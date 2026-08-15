output "workload_project_ids" {
  value = { for k, v in google_project.workload : k => v.project_id }
}
