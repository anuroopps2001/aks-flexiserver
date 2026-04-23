resource "azurerm_resource_group" "tfstate" {
  name     = "rg-terraform-state"
  location = var.location
}

resource "random_string" "tfstate" {
  length  = 10
  special = false
  lower   = true
  upper = false
}
resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${random_string.tfstate.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  public_network_access_enabled     = false
  shared_access_key_enabled         = false
  min_tls_version                   = "TLS1_2"
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}


resource "azurerm_private_endpoint" "storage_pe_bootstrap" {
  name                = "pe-hub-storage-bootstrap"
  location            = var.location
  resource_group_name = azurerm_resource_group.tfstate.name
  subnet_id           = var.subnet_id


  private_dns_zone_group {
    name                 = "storage-dns-group"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  private_service_connection {
    name                           = "storage-connection-bootstrap"
    private_connection_resource_id = azurerm_storage_account.tfstate.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}