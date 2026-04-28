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

  blob_properties {
    delete_retention_policy {
      days = 7 # Restore deleted blobs (within 7 days) and Protection against accidental overwrite
    }

    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "images" {
  name                  = "go-app-uploads"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}


# Life cycle management of containers within the storage accounts
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "move-old-data"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["go-app-uploads"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30 # 30 days → move to Cool
        delete_after_days_since_modification_greater_than       = 90 # 90 days → delete
      }
    }
  }
}

resource "azurerm_log_analytics_workspace" "storage_law" {
  name                = "storage-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
resource "azurerm_monitor_diagnostic_setting" "storage_logs" {
  name                       = "storage-diagnostics"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.storage_law.id


  enabled_log {
    category = "StorageApiResult"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
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


