# Create a Private DNS Zone for Postgres
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
}

# Link this zone to your AKS and Agent VNets
resource "azurerm_private_dns_zone_virtual_network_link" "db_aks_link" {
  name                  = "db-aks-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.spokes["aks"].id
  resource_group_name   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
}


# Linking Agent VNet
resource "azurerm_private_dns_zone_virtual_network_link" "db_agents_link" {
  name                  = "db-agents-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.spokes["client-and-agent"].id
  resource_group_name   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
}

# Create the Flexible Server
resource "azurerm_postgresql_flexible_server" "db" {
  name                = "anuroop-psql-flex"
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  location            = var.location
  version             = "14"

  administrator_login    = "psqladmin"
  administrator_password = var.default_secrets["DB-PASSWORD"] # Keyvault

  zone = "1"

  public_network_access_enabled = false
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B2s"

  depends_on = [azurerm_key_vault_secret.db_secrets]

}

resource "azurerm_postgresql_flexible_server_firewall_rule" "aks_pods_access" {
  name             = "allow-aks-pods"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = "10.1.1.0"
  end_ip_address   = "10.1.1.255"
}


# resource "azurerm_postgresql_flexible_server_virtual_network_rule" "aks_vnet_rule" {
#   name = "aks-vnet-rule"
#   server_id = azurerm_postgresql_flexible_server.db.id
#   subnet_id = var.snet-aks.id
# }
# Creating individual databases inside the flexiserver
resource "azurerm_postgresql_flexible_server_database" "aks_go_app_db" {
  name      = var.kv_secrets["DB-NAME"]
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Dedicated UserIdentity for AKS pods to access DB creds through KeyVault
resource "azurerm_user_assigned_identity" "aks_db_access_identity" {
  name                = "id-aks-db-access"
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  location            = var.location
}

resource "azurerm_private_endpoint" "postgres_pe" {
  name                = "pe-postgres-db"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  subnet_id           = azurerm_subnet.spoke_subnets["snet-db"].id # no delegation for DB servers only

  private_service_connection {
    name                           = "psc-postgres"
    private_connection_resource_id = azurerm_postgresql_flexible_server.db.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-postgres"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgres_dns.id]
  }
}