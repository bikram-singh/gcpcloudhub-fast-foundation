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
    prefix = "01-org-policies"
  }
}

provider "google" {
  user_project_override = true
  billing_project        = "gch-seed-28bdf9"
}

# Prevent default VPC network creation on all new projects org-wide
resource "google_org_policy_policy" "skip_default_network" {
  name   = "organizations/${var.org_id}/policies/compute.skipDefaultNetworkCreation"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Block VMs from getting external/public IP addresses
resource "google_org_policy_policy" "vm_external_ip" {
  name   = "organizations/${var.org_id}/policies/compute.vmExternalIpAccess"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

# Disable creation of downloadable service account keys org-wide
resource "google_org_policy_policy" "disable_sa_key_creation" {
  name   = "organizations/${var.org_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Enforce public access prevention on all Cloud Storage buckets org-wide
resource "google_org_policy_policy" "bucket_public_access_prevention" {
  name   = "organizations/${var.org_id}/policies/storage.publicAccessPrevention"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Block Cloud SQL instances from having public IPs
resource "google_org_policy_policy" "sql_restrict_public_ip" {
  name   = "organizations/${var.org_id}/policies/sql.restrictPublicIp"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restrict IAM grants to only principals from your own Cloud Identity domain
resource "google_org_policy_policy" "domain_restricted_sharing" {
  name   = "organizations/${var.org_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${var.org_id}"

  spec {
    rules {
      values {
        allowed_values = ["C03xtsaju"]
      }
    }
  }
}
