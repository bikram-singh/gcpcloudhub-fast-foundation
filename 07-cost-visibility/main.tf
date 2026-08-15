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
    prefix = "07-cost-visibility"
  }
}

provider "google" {
  user_project_override = true
  billing_project       = "gch-seed-28bdf9"
}

resource "google_project_service" "bq_api" {
  project = var.seed_project_id
  service = "bigquery.googleapis.com"
}

resource "google_bigquery_dataset" "billing_export" {
  project     = var.seed_project_id
  dataset_id  = "${var.prefix}_billing_export"
  location    = var.region
  description = "Google Cloud billing export - actual spend, updated daily"

  depends_on = [google_project_service.bq_api]
}
