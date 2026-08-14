output "seed_project_id" {
  value = google_project.seed.project_id
}

output "tf_state_bucket" {
  value = google_storage_bucket.tf_state.name
}

output "automation_sa_email" {
  value = google_service_account.automation.email
}
