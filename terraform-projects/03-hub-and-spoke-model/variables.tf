variable "location" {
  type    = string
  default = "centralindia"
}

variable "resource_groups" {
  type = map(object({
    location = string
  }))
}

variable "hub_config" {
  type = object({
    name          = string
    address_space = list(string)
    rg            = string
  })
}

variable "hub_subnets" {
  type = map(object({
    address_prefixes   = list(string)
    service_delegation = optional(string)
    service_endpoints  = optional(list(string))
  }))
}

variable "spoke_vnets" {
  type = map(object({
    address_space = list(string)
    rg            = string
  }))
}

variable "subnets" {
  type = map(object({
    vnet_key          = string
    address_prefixes  = list(string)
    delegation        = optional(string) # Only for the postgres and Site2Site VPN
    service_endpoints = list(string)
  }))
}




variable "default_secrets" {
  type = map(string)
  default = {
    "DB-PASSWORD" = "YourSuperSecurePassword123!"
  }
}

variable "kv_secrets" {
  type    = map(string)
  default = {}
}


variable "ssh_public_key" {
  type        = string
  description = "The actual string content of the public key, not the path"
  sensitive   = true
}