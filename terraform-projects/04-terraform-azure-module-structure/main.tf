# Create Resource Groups
resource "azurerm_resource_group" "rgs" {
  for_each = var.resource_groups
  name     = each.key
  location = each.value.location
}

module "network" {
  source = "../modules/network"
  location = var.location
  resource_groups = azurerm_resource_group.rgs
  hub_config = var.hub_config
  spoke_config = var.spoke_config
  subnets = var.subnets
}

module "database" {
  source           = "./modules/database"
  location         = var.location
  resource_group   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  db_subnet_id     = module.network.subnet_ids["snet-db"]
  aks_vnet_id      = module.network.vnet_ids["aks"]
  agent_vnet_id    = module.network.vnet_ids["client-and-agent"]
  db_password      = var.default_secrets["DB-PASSWORD"][cite: 12, 18]
}

module "aks" {
  source            = "./modules/compute_aks"
  location          = var.location
  resource_group    = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  aks_subnet_id     = module.network.subnet_ids["snet-aks"]
  hub_rg            = var.hub_config.rg
  agent_identity_id = azurerm_user_assigned_identity.agent_identity.id
}