resource "google_project" "this" {
  name                = var.name
  project_id          = var.project_id
  org_id              = var.org_id
  folder_id           = var.folder_id
  billing_account     = var.billing_account
  auto_create_network = false

  labels = {
    department  = lower(var.department)
    environment = var.environment
    cost-center = "${lower(var.department)}-${var.environment}"
    managed-by  = "terraform"
  }
}

resource "google_project_service" "apis" {
  for_each = toset(var.apis)
  project  = google_project.this.project_id
  service  = each.value
}

resource "google_project_iam_audit_config" "full_audit" {
  project = google_project.this.project_id
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
