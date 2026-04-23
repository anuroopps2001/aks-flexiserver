output "sas_token_query_string" {
  description = "The generated SAs token query string"
  value = data.azurerm_storage_account_sas.name.sas
  sensitive = true
}

output "full_sas_url" {
  description = "The full URL with SAS token for the Blob service"
  value = "https://${var.storage_account_name}.blob.core.windows.net/${data.azurerm_storage_account_sas.name.sas}"
}