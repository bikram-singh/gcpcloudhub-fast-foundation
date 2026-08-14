variable "org_id" {
  description = "Numeric GCP organization ID."
  type        = string
}

variable "prefix" {
  description = "Short prefix used for all resource names."
  type        = string
  default     = "gch"
}

variable "departments" {
  description = "List of department names, each gets Prod/NonProd sub-folders."
  type        = list(string)
  default     = ["HR", "Finance", "IT", "Sales", "AI"]
}

variable "groups" {
  description = "Admin group emails."
  type = object({
    org_admins       = string
    billing_admins   = string
    devops           = string
    security_admins  = string
  })
}
