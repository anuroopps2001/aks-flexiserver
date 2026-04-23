variable "plan_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "app_name" {
  type = string
}


variable "sku_name" { default = "S1" }

variable "enable_staging_slot" {
  type    = bool
  default = false
}

variable "common_app_settings" {
  type = map(string)
}

variable "build_time" {
  type = string
}

variable "user_assigned_identity_id" {
  description = "The Resource ID of the User Assigned Identity"
  type        = string
}

variable "user_assigned_identity_principal_id" {
  description = "The Principal ID of the User Assigned Identity"
  type        = string
}

variable "app_service_subnet_id" {
  type = string
}