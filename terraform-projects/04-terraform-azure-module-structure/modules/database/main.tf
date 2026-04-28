resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group
}

# VNet Links
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each              = { aks = var.aks_vnet_id, agents = var.agent_vnet_id }
  name                  = "link-${each.key}"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = each.value
  resource_group_name   = var.resource_group
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "anuroop-psql-flex"
  resource_group_name    = var.resource_group
  location               = var.location
  version                = "14"
  administrator_login    = "psqladmin"
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B2s"
  public_network_access_enabled = false[cite: 12]
}