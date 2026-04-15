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