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
    prefix = "08-vpc-sc"
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

data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "03-networking"
  }
}

# Look up project numbers - VPC-SC requires numbers, not IDs
data "google_project" "workloads" {
  for_each   = data.terraform_remote_state.project_factory.outputs.workload_project_ids
  project_id = each.value
}

data "google_project" "net_host" {
  project_id = data.terraform_remote_state.networking.outputs.net_host_project_id
}

resource "google_access_context_manager_access_policy" "policy" {
  parent = "organizations/${var.org_id}"
  title  = "${var.prefix}-access-policy"
}

# Dry-run perimeter - evaluates and logs what WOULD be blocked,
# without actually blocking anything. Safe to run alongside live workloads.
resource "google_access_context_manager_service_perimeter" "perimeter" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/${var.prefix}_perimeter"
  title  = "${var.prefix}_perimeter"

  status {
    restricted_services = [
      "storage.googleapis.com",
      "bigquery.googleapis.com",
      "secretmanager.googleapis.com",
    ]

    resources = concat(
      [for p in data.google_project.workloads : "projects/${p.number}"],
      ["projects/${data.google_project.net_host.number}"]
    )
  }

  # DRY RUN - nothing is actually blocked yet. This logs violations
  # for review before switching to enforced mode.
  use_explicit_dry_run_spec = true

  spec {
    restricted_services = [
      "storage.googleapis.com",
      "bigquery.googleapis.com",
      "secretmanager.googleapis.com",
    ]

    resources = concat(
      [for p in data.google_project.workloads : "projects/${p.number}"],
      ["projects/${data.google_project.net_host.number}"]
    )
  }
}
