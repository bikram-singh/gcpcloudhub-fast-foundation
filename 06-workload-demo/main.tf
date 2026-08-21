terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.44.0"
    }
  }
  backend "gcs" {
    bucket = "gch-tf-state-28bdf9"
    prefix = "06-workload-demo"
  }
}

provider "google" {
  user_project_override = true
  billing_project       = "gch-seed-28bdf9"
}

data "terraform_remote_state" "project_factory" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "04-project-factory"
  }
}

locals {
  workload_project_id = data.terraform_remote_state.project_factory.outputs.workload_project_ids["HR-nonprod"]
}

resource "google_project_service" "run_api" {
  project = local.workload_project_id
  service = "run.googleapis.com"
}

# Demonstration workload proving the org -> folder -> project -> resource
# hierarchy end to end. Uses Google's public hello-world container image -
# no custom build pipeline needed for this demo.
resource "google_cloud_run_v2_service" "demo" {
  name     = "${var.prefix}-hr-nonprod-demo"
  project  = local.workload_project_id
  location = var.region

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    scaling {
      max_instance_count = 3
    }
  }

  depends_on = [google_project_service.run_api]
}

# Public access for demo purposes only. A production workload would
# restrict this to specific identities or use IAP.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = local.workload_project_id
  location = var.region
  name     = google_cloud_run_v2_service.demo.name
  role     = "roles/run.invoker"
  member   = "domain:gcpcloudhub.in"
}

data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "03-networking"
  }
}

# Minimal demo VM - no external IP (blocked by org policy anyway),
# attached to the existing shared VPC NonProd subnet.
resource "google_compute_instance" "demo_vm" {
  name                      = "${var.prefix}-demo-vm"
  project                   = local.workload_project_id
  zone                      = "${var.region}-a"
  machine_type              = "e2-micro"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = data.terraform_remote_state.networking.outputs.nonprod_subnet_self_link
    # No access_config block = no external IP
  }

  metadata = {
    block-project-ssh-keys = "true"
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    department  = "hr"
    environment = "nonprod"
    managed-by  = "terraform"
  }
}

# --- Cloud SQL PostgreSQL, private IP only (org policy blocks public IP) ---

resource "google_project_service" "sqladmin_api" {
  project = local.workload_project_id
  service = "sqladmin.googleapis.com"
}

resource "google_project_service" "servicenetworking_api" {
  project = data.terraform_remote_state.networking.outputs.net_host_project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_compute_global_address" "psa_range" {
  name          = "${var.prefix}-psa-range"
  project       = data.terraform_remote_state.networking.outputs.net_host_project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.terraform_remote_state.networking.outputs.vpc_self_link
}

resource "google_service_networking_connection" "psa_connection" {
  network                 = data.terraform_remote_state.networking.outputs.vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]
  depends_on              = [google_project_service.servicenetworking_api]
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

resource "google_sql_database_instance" "demo_postgres" {
  name                = "${var.prefix}-hr-nonprod-pg"
  project             = local.workload_project_id
  region              = var.region
  database_version    = "POSTGRES_15"
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.terraform_remote_state.networking.outputs.vpc_self_link
    }

    backup_configuration {
      enabled = false
    }
  }

  depends_on = [google_service_networking_connection.psa_connection, google_project_service.sqladmin_api]
}

resource "google_sql_database" "demo_db" {
  name     = "demo"
  project  = local.workload_project_id
  instance = google_sql_database_instance.demo_postgres.name
}

resource "google_sql_user" "demo_user" {
  name     = "demo_app"
  project  = local.workload_project_id
  instance = google_sql_database_instance.demo_postgres.name
  password = random_password.db_password.result
}

resource "google_secret_manager_secret_version" "db_credential" {
  secret      = "projects/gch-seed-28bdf9/secrets/gch-example-db-credential"
  secret_data = jsonencode({
    host     = google_sql_database_instance.demo_postgres.private_ip_address
    database = google_sql_database.demo_db.name
    username = google_sql_user.demo_user.name
    password = random_password.db_password.result
  })
}
