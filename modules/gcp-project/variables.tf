variable "name" {
  description = "Project display name."
  type        = string
}

variable "project_id" {
  description = "Globally unique project ID."
  type        = string
}

variable "billing_account" {
  type = string
}

variable "org_id" {
  description = "Set for org-level projects. Mutually exclusive with folder_id."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Set for folder-level projects. Mutually exclusive with org_id."
  type        = string
  default     = null
}

variable "department" {
  type    = string
  default = "platform"
}

variable "environment" {
  type    = string
  default = "shared"
}

variable "apis" {
  description = "APIs to enable on this project."
  type        = list(string)
  default     = []
}
