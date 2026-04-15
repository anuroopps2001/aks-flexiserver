output "flexi_server_hostname" {
  value = azurerm_postgresql_flexible_server.db.fqdn
}

output "azurerm_storage_account" {
  value       = azurerm_storage_account.storage.name
  description = "The name of the storage account."
}

output "azurerm_storage_account_key" {
  value       = azurerm_storage_account.storage.primary_access_key
  description = "The primary access key for the storage account."
  sensitive   = true # This prevents the key from being printed in clear text in logs
}

output "azurerm_storage_container" {
  value       = azurerm_storage_container.images.name
  description = "The name of the storage container."
}