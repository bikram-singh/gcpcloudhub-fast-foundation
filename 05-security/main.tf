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
    prefix = "05-security"
  }
}

provider "google" {
  user_project_override = true
  billing_project        = "gch-seed-28bdf9"
}

# Dedicated logging bucket for centralized audit logs
resource "google_logging_project_bucket_config" "audit_logs" {
  project        = var.seed_project_id
  location       = "asia-south1"
  retention_days = 30
  bucket_id      = "${var.prefix}-audit-logs"
}

# Org-level log sink capturing all audit logs (Admin Activity, Data Access, System Event)
resource "google_logging_organization_sink" "org_audit_sink" {
  name             = "${var.prefix}-org-audit-sink"
  org_id           = var.org_id
  destination      = "logging.googleapis.com/projects/${var.seed_project_id}/locations/asia-south1/buckets/${google_logging_project_bucket_config.audit_logs.bucket_id}"
  include_children  = true

  filter = "logName:\"cloudaudit.googleapis.com\""
}

# Grant the sink's service identity permission to write to the destination
resource "google_project_iam_member" "sink_writer" {
  project = var.seed_project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.org_audit_sink.writer_identity
}

# Custom least-privilege role replacing broad roles/editor for devops group
resource "google_organization_iam_custom_role" "devops_scoped" {
  org_id      = var.org_id
  role_id     = "${var.prefix}DevopsScoped"
  title       = "GCH DevOps Scoped Role"
  description = "Least-privilege role for devops group: compute, GKE, and Cloud Run management without full Editor"
  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop",
    "container.clusters.create",
    "container.clusters.get",
    "container.clusters.list",
    "container.clusters.update",
    "run.services.create",
    "run.services.get",
    "run.services.list",
    "run.services.update",
  ]
}

# Secret Manager pattern - demonstrates secure secret storage for future workloads.
# No secret VALUE is stored in Terraform state or code; only the secret container
# is created here. Actual values are set out-of-band via gcloud/Console/CI secrets,
# never committed or passed through tfvars.

resource "google_secret_manager_secret" "example_workload_secret" {
  project   = var.seed_project_id
  secret_id = "${var.prefix}-example-db-credential"

  replication {
    auto {}
  }

  labels = {
    department  = "platform"
    managed-by  = "terraform"
  }
}

# Grant only the automation SA and devops group access to read this secret -
# least privilege, not org-wide or project-wide broad access.
resource "google_secret_manager_secret_iam_member" "devops_secret_accessor" {
  project   = var.seed_project_id
  secret_id = google_secret_manager_secret.example_workload_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "group:gcp-devops@gcpcloudhub.in"
}
