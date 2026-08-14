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

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "state_bucket" {
  type = string
}
