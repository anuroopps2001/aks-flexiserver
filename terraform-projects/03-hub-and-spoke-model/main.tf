terraform {
  backend "azurerm" {
    resource_group_name = "rg-terraform-state"
    storage_account_name = "sttfstate4ojm07om5k"
    container_name = "tfstate"
    key = "terraform.tfstate"
    use_azuread_auth = true
  }
}

data "azurerm_client_config" "current" {}

# Azure loki storage account module
module "loki_storage" {
  source = "./modules/azure_identity_storage"

  name                 = "loki"
  container_name       = "loki-logs"
  namespace            = "monitoring"
  storage_account_name = azurerm_storage_account.storage.name
  storage_account_id   = azurerm_storage_account.storage.id
  location             = var.location
  oidc_issuer_url      = azurerm_kubernetes_cluster.private_aks.oidc_issuer_url
  resource_group_name  = azurerm_resource_group.rgs["rg-hub-networking"].name
}

# Azure storageAccount SAS module
resource "time_static" "now" {}

locals {
  start_time  = time_static.now.rfc3339
  expiry_time = formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timeadd(local.start_time, "24h"))
}
module "sas_generator" {
  source                    = "./modules/sas_generator"
  storage_connection_string = azurerm_storage_account.storage.primary_connection_string
  start_time                = local.start_time
  expiry_time               = local.expiry_time
  storage_account_name      = azurerm_storage_account.storage.name
}

module "frontend_webapp" {
  source                = "./modules/app_service"
  app_name              = "go-db-app-ui-prod"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rgs["rg-hub-networking"].name
  enable_staging_slot   = true # This triggers the slot creation
  plan_name             = "go-db-app-plan"
  build_time            = timestamp()
  app_service_subnet_id = azurerm_subnet.hub_subnets["snet-appservice-integration"].id

  common_app_settings = {
    WEBSITES_PORT                  = "3000"
    API_BASE_URL                   = "@Microsoft.KeyVault(SecretUri=https://${azurerm_key_vault.kv.name}.vault.azure.net/secrets/API-BASE-URL)"
    WEBSITE_DNS_SERVER             = "168.63.129.16"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }

  user_assigned_identity_id           = azurerm_user_assigned_identity.agent_identity.id
  user_assigned_identity_principal_id = azurerm_user_assigned_identity.agent_identity.principal_id
}

module "terraform_tftstae" {
  source               = "./modules/bootstrap"
  location             = var.location
  subnet_id            = azurerm_subnet.hub_subnets["snet-appgw"].id
  private_dns_zone_ids = [azurerm_private_dns_zone.storage_account_dns_zone.id]
}