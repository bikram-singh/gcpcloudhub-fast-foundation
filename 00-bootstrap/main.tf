terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  region                = var.region
  user_project_override = true
  billing_project       = "gch-seed-28bdf9"
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "google_project" "seed" {
  name                = "${var.prefix}-seed"
  project_id          = "${var.prefix}-seed-${random_id.suffix.hex}"
  org_id              = var.org_id
  auto_create_network = false
  billing_account     = var.billing_account_id

  labels = {
    department  = "platform"
    environment = "shared"
    cost-center = "platform-eng"
    managed-by  = "terraform"
  }
}

resource "google_project_service" "seed_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "orgpolicy.googleapis.com",
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "monitoring.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
  ])
  project = google_project.seed.project_id
  service = each.value
}

resource "google_storage_bucket" "tf_state" {
  name          = "${var.prefix}-tf-state-${random_id.suffix.hex}"
  project       = google_project.seed.project_id
  location      = var.region
  force_destroy = false

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age        = 30
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
  public_access_prevention = "enforced"

  depends_on = [google_project_service.seed_apis]
}

resource "google_service_account" "automation" {
  project      = google_project.seed.project_id
  account_id   = "${var.prefix}-automation"
  display_name = "FAST-style automation SA"

  depends_on = [google_project_service.seed_apis]
}

resource "google_organization_iam_member" "automation_org_admin" {
  org_id = var.org_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = "serviceAccount:${google_service_account.automation.email}"
}

resource "google_organization_iam_member" "automation_folder_admin" {
  org_id = var.org_id
  role   = "roles/resourcemanager.folderAdmin"
  member = "serviceAccount:${google_service_account.automation.email}"
}

resource "google_billing_account_iam_member" "automation_billing_admin" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.admin"
  member             = "serviceAccount:${google_service_account.automation.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.seed.project_id
  workload_identity_pool_id = "${var.prefix}-github-pool"
  display_name              = "GitHub Actions pool"
  depends_on                = [google_project_service.seed_apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.seed.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.prefix}-github-provider"
  display_name                       = "GitHub provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif_impersonation" {
  service_account_id = google_service_account.automation.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

terraform {
  backend "gcs" {
    bucket = "gch-tf-state-28bdf9"
    prefix = "00-bootstrap"
  }
}

# Budget alert to protect free-trial credits from silent overspend
resource "google_billing_budget" "trial_guard" {
  billing_account = var.billing_account_id
  display_name    = "${var.prefix}-trial-budget-guard"

  budget_filter {
    projects = []
  }

  amount {
    specified_amount {
      currency_code = "INR"
      units         = "20000"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }

}

resource "google_project_iam_audit_config" "seed_audit" {
  project = google_project.seed.project_id
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
