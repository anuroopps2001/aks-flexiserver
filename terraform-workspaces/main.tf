# Variable map for environment-specific settings
variable "rg_config" {
  type = map(object({
    location = string
    tier     = string
  }))

  default = {
    dev  = { location = "East US",  tier = "Standard" }
    prod = { location = "West US 2", tier = "Premium" }
  }
}

locals {
  # Logic: If workspace is 'default', use 'dev' settings to avoid errors
  env = lookup(var.rg_config, terraform.workspace, var.rg_config["dev"])
}

resource "azurerm_resource_group" "example" {
  # This creates: rg-workspace-dev or rg-workspace-prod
  name     = "rg-workspace-${terraform.workspace}" 
  location = local.env.location

  tags = {
    Environment = terraform.workspace
    Tier        = local.env.tier
  }
}