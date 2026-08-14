output "net_host_project_id" {
  value = google_project.net_host.project_id
}

output "vpc_self_link" {
  value = google_compute_network.shared_vpc.self_link
}

output "prod_subnet_self_link" {
  value = google_compute_subnetwork.prod.self_link
}

output "nonprod_subnet_self_link" {
  value = google_compute_subnetwork.nonprod.self_link
}
