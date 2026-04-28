output "database_host" {
  value = module.database.flexi_server_hostname
}

output "storage_account_name" {
  value = module.storage.azurerm_storage_account
}

output "storage_key" {
  value     = module.storage.azurerm_storage_account_key
  sensitive = true
}