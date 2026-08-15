variables {
  org_id       = "321953905269"
  customer_id  = "C03xtsaju"
  state_bucket = "gch-tf-state-28bdf9"
}

run "verify_org_policies_plan" {
  command = plan

  assert {
    condition     = google_org_policy_policy.skip_default_network.name == "organizations/321953905269/policies/compute.skipDefaultNetworkCreation"
    error_message = "skipDefaultNetworkCreation policy name mismatch"
  }

  assert {
    condition     = google_org_policy_policy.vm_external_ip.spec[0].rules[0].deny_all == "TRUE"
    error_message = "vmExternalIpAccess should deny all"
  }

  assert {
    condition     = google_org_policy_policy.disable_sa_key_creation.spec[0].rules[0].enforce == "TRUE"
    error_message = "disableServiceAccountKeyCreation should be enforced"
  }
}
