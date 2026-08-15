variables {
  org_id = "321953905269"
  prefix = "gch"
  groups = {
    org_admins      = "gcp-organization-admins@gcpcloudhub.in"
    billing_admins  = "gcp-billing-admins@gcpcloudhub.in"
    devops          = "gcp-devops@gcpcloudhub.in"
    security_admins = "gcp-security-admins@gcpcloudhub.in"
  }
}

run "verify_folder_structure" {
  command = plan

  assert {
    condition     = length(var.departments) == 5
    error_message = "Expected 5 departments"
  }

  assert {
    condition     = length(google_folder.department) == 5
    error_message = "Expected 5 department folders"
  }

  assert {
    condition     = length(google_folder.prod) == 5
    error_message = "Expected 5 Prod sub-folders"
  }

  assert {
    condition     = length(google_folder.nonprod) == 5
    error_message = "Expected 5 NonProd sub-folders"
  }
}
