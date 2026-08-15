terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
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
