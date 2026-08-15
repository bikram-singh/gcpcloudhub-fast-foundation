variable "org_id" {
  description = "Numeric GCP organization ID."
  type        = string
}

variable "customer_id" {
  description = "Cloud Identity customer ID, used for domain-restricted sharing."
  type        = string
}

variable "state_bucket" {
  description = "GCS bucket used for all stage state files."
  type        = string
}

