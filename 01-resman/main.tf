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
    prefix = "01-resman"
  }
}

provider "google" {}

# Top-level department folders directly under the org
resource "google_folder" "department" {
  for_each     = toset(var.departments)
  display_name = "${var.prefix}-${each.value}"
  parent       = "organizations/${var.org_id}"
}

# Prod and NonProd nested inside each department
resource "google_folder" "prod" {
  for_each     = toset(var.departments)
  display_name = "Prod"
  parent       = google_folder.department[each.value].name
}

resource "google_folder" "nonprod" {
  for_each     = toset(var.departments)
  display_name = "NonProd"
  parent       = google_folder.department[each.value].name
}

# Org-level IAM for admin groups
resource "google_organization_iam_member" "org_admins" {
  org_id = var.org_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = "group:${var.groups.org_admins}"
}

resource "google_organization_iam_member" "billing_admins" {
  org_id = var.org_id
  role   = "roles/billing.admin"
  member = "group:${var.groups.billing_admins}"
}

resource "google_organization_iam_member" "security_admins" {
  org_id = var.org_id
  role   = "roles/iam.securityAdmin"
  member = "group:${var.groups.security_admins}"
}

# DevOps group gets Editor on every department's NonProd folder
resource "google_folder_iam_member" "devops_nonprod" {
  for_each = toset(var.departments)
  folder   = google_folder.nonprod[each.value].name
  role     = "roles/editor"
  member   = "group:${var.groups.devops}"
}
