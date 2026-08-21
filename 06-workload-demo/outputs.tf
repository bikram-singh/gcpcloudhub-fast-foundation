output "demo_service_url" {
  value = google_cloud_run_v2_service.demo.uri
}

output "demo_vm_internal_ip" {
  value = google_compute_instance.demo_vm.network_interface[0].network_ip
}

output "cloud_sql_private_ip" {
  value = google_sql_database_instance.demo_postgres.private_ip_address
}
