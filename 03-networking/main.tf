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
    prefix = "03-networking"
  }
}

provider "google" {}

data "terraform_remote_state" "resman" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "02-resman"
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

# Networking host project, placed under IT > Prod folder
resource "google_project" "net_host" {
  name            = "${var.prefix}-net-host"
  project_id      = "${var.prefix}-net-host-${random_id.suffix.hex}"
  org_id          = null
  folder_id       = data.terraform_remote_state.resman.outputs.prod_folder_ids["IT"]
  billing_account = var.billing_account_id
  auto_create_network = false

  labels = {
    department  = "it"
    environment = "shared"
    cost-center = "platform-eng"
    managed-by  = "terraform"
  }
}

resource "google_project_service" "net_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
  ])
  project = google_project.net_host.project_id
  service = each.value
}

resource "google_compute_network" "shared_vpc" {
  name                    = "${var.prefix}-shared-vpc"
  project                 = google_project.net_host.project_id
  auto_create_subnetworks = false
  depends_on              = [google_project_service.net_apis]
}

resource "google_compute_subnetwork" "prod" {
  name                     = "${var.prefix}-prod-subnet"
  project                  = google_project.net_host.project_id
  network                  = google_compute_network.shared_vpc.id
  region                   = var.region
  ip_cidr_range            = "10.10.0.0/20"
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "nonprod" {
  name                     = "${var.prefix}-nonprod-subnet"
  project                  = google_project.net_host.project_id
  network                  = google_compute_network.shared_vpc.id
  region                   = var.region
  ip_cidr_range            = "10.20.0.0/20"
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "router" {
  name    = "${var.prefix}-router"
  project = google_project.net_host.project_id
  region  = var.region
  network = google_compute_network.shared_vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat"
  project                            = google_project.net_host.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.prefix}-allow-internal"
  project = google_project.net_host.project_id
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.10.0.0/20", "10.20.0.0/20"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.prefix}-allow-iap-ssh"
  project = google_project.net_host.project_id
  network = google_compute_network.shared_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # Google's IAP range
}

# Designate this project as a Shared VPC host project so other projects can attach as service projects
resource "google_compute_shared_vpc_host_project" "host" {
  project = google_project.net_host.project_id
}

resource "google_project_iam_audit_config" "net_host_audit" {
  project = google_project.net_host.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
