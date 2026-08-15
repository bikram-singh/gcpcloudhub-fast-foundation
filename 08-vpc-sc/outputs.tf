output "access_policy_name" {
  value = google_access_context_manager_access_policy.policy.name
}

output "perimeter_name" {
  value = google_access_context_manager_service_perimeter.perimeter.name
}
