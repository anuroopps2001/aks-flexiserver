resource "random_string" "suffix" {
  length  = 3
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storage" {
  name                     = "anuroopstorage${random_string.suffix.result}"
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false[cite: 16]
}


resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}