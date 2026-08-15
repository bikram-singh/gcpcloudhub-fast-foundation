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
    prefix = "04-project-factory"
  }
}

provider "google" {
  user_project_override = true
  billing_project        = "gch-seed-28bdf9"
}

data "terraform_remote_state" "resman" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "02-resman"
  }
}

data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "03-networking"
  }
}

locals {
  # Explicit list of workload projects to create - avoids accidentally
  # hitting billing-account project-link quotas on free-tier accounts.
  # Add entries here deliberately as quota allows.
  workloads = {
    for w in var.enabled_workloads : "${w.department}-${w.env}" => {
      department = w.department
      env        = w.env
      folder_id  = w.env == "prod" ? data.terraform_remote_state.resman.outputs.prod_folder_ids[w.department] : data.terraform_remote_state.resman.outputs.nonprod_folder_ids[w.department]
    }
  }
}

resource "random_id" "suffix" {
  for_each    = local.workloads
  byte_length = 3
}

resource "google_project" "workload" {
  for_each = local.workloads

  name                = "${var.prefix}-${lower(each.value.department)}-${each.value.env}"
  project_id          = "${var.prefix}-${lower(each.value.department)}-${each.value.env}-${random_id.suffix[each.key].hex}"
  folder_id           = each.value.folder_id
  billing_account     = var.billing_account_id
  auto_create_network = false
}

resource "google_project_service" "workload_apis" {
  for_each = local.workloads
  project  = google_project.workload[each.key].project_id
  service  = "compute.googleapis.com"
}

# Attach every workload project to the shared VPC as a service project
resource "google_compute_shared_vpc_service_project" "attach" {
  for_each        = local.workloads
  host_project    = data.terraform_remote_state.networking.outputs.net_host_project_id
  service_project = google_project.workload[each.key].project_id

  depends_on = [google_project_service.workload_apis]
}

resource "google_project_iam_audit_config" "workload_audit" {
  for_each = local.workloads
  project  = google_project.workload[each.key].project_id
  service  = "allServices"

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
