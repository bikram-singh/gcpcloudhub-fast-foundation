output "department_folder_ids" {
  value = { for k, v in google_folder.department : k => v.name }
}

output "prod_folder_ids" {
  value = { for k, v in google_folder.prod : k => v.name }
}

output "nonprod_folder_ids" {
  value = { for k, v in google_folder.nonprod : k => v.name }
}
