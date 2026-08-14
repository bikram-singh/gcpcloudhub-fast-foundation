variable "org_id" {
  description = "Numeric GCP organization ID."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID (XXXXXX-XXXXXX-XXXXXX)."
  type        = string
}

variable "domain" {
  description = "Organization primary domain."
  type        = string
}

variable "prefix" {
  description = "Short prefix used for all resource names."
  type        = string
  default     = "gch"
}

variable "region" {
  description = "Default region for resources."
  type        = string
  default     = "asia-south1"
}

variable "github_repo" {
  description = "GitHub repo allowed to impersonate the automation SA, format owner/repo."
  type        = string
  default     = "bikram-singh/gcpcloudhub-fast-foundation"
}
