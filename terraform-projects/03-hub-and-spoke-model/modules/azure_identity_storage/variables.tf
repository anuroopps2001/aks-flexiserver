variable "name" {
  description = "The prefix name for the identity (e.g., 'loki')"
  type        = string
}

variable "container_name" {
  description = "The name of the Blob Container"
  type        = string
}

variable "storage_account_name" {
  description = "The name of the existing Storage Account"
  type        = string
}

variable "storage_account_id" {
  description = "The ID of the Storage Account for RBAC scope"
  type        = string
}

variable "oidc_issuer_url" {
  description = "The OIDC Issuer URL from the AKS cluster"
  type        = string
}

variable "namespace" {
  description = "The Kubernetes namespace for the ServiceAccount"
  type        = string
  default     = "monitoring"
}
variable "location" {
  description = "The Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Resource Group"
  type        = string
}