variable "org_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "prefix" {
  type    = string
  default = "gch"
}

variable "departments" {
  type    = list(string)
  default = ["HR", "Finance", "IT", "Sales", "AI"]
}

variable "state_bucket" {
  type = string
}

variable "enabled_workloads" {
  description = "Explicit list of department/env pairs to actually provision, gated by billing quota."
  type = list(object({
    department = string
    env        = string
  }))
}
