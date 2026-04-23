resource "random_string" "storage_account" {
  length  = 3
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_storage_account" "storage" {
  resource_group_name      = azurerm_resource_group.rgs["rg-hub-networking"].name
  name                     = "anuroopstorageaccount${random_string.storage_account.result}"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  public_network_access_enabled = false
}

resource "azurerm_storage_container" "images" {
  name                  = "go-app-uploads"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}


resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pe-hub-storage-account"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
  subnet_id           = azurerm_subnet.hub_subnets["snet-appgw"].id



  private_dns_zone_group {
    name = "storage-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_account_dns_zone.id,

    ]
  }


  private_service_connection {
    name                           = "storage-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "storage_account_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
}


# Link Hub vnet to DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "hub_storage_accountvnet_link" {
  name                  = "hub-vnet-link-to-storage-dns-zone"
  resource_group_name   = azurerm_resource_group.rgs["rg-hub-networking"].name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

# Link AKS Spoke Vnet to DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "aks_storage_account_vnet_link" {
  name                  = "spoke-aks-vnet-link-to-storage-dns-zone"
  resource_group_name   = azurerm_resource_group.rgs["rg-hub-networking"].name
  virtual_network_id    = azurerm_virtual_network.spokes["aks"].id
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns_zone.name
}


