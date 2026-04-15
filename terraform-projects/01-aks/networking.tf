# VNet South India
resource "azurerm_virtual_network" "vnet_south" {
  name                = "vnet-aks"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg_south.location
  resource_group_name = azurerm_resource_group.rg_south.name
}


resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.rg_south.name
  virtual_network_name = azurerm_virtual_network.vnet_south.name
  address_prefixes     = ["10.1.1.0/24"]

  // By using ignore_changes, you're telling Terraform: "I know there's an NSG there, but just leave it alone."
  lifecycle {
    ignore_changes = [private_endpoint_network_policies, service_endpoints]
  }
}

# For site-2-site VPN between Azure and GCP
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg_south.name
  virtual_network_name = azurerm_virtual_network.vnet_south.name
  address_prefixes     = ["10.1.255.0/27"]
}

# VNet Central India
resource "azurerm_virtual_network" "vnet_central" {
  name                = "vnet-db"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name
}

# 1. Delegated Subnet for Postgres
resource "azurerm_subnet" "db_subnet" {
  name                 = "snet-db-flex"
  resource_group_name  = azurerm_resource_group.rg_central.name
  virtual_network_name = azurerm_virtual_network.vnet_central.name
  address_prefixes     = ["10.2.1.0/24"]

  delegation {
    name = "fs-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# 2. Standard Subnet for Client/Management VM
resource "azurerm_subnet" "client_subnet" {
  name                 = "snet-client"
  resource_group_name  = azurerm_resource_group.rg_central.name
  virtual_network_name = azurerm_virtual_network.vnet_central.name
  address_prefixes     = ["10.2.2.0/24"]
}

# Peering: South to Central
resource "azurerm_virtual_network_peering" "south_to_central" {
  name                      = "peer-south-to-central"
  resource_group_name       = azurerm_resource_group.rg_south.name
  virtual_network_name      = azurerm_virtual_network.vnet_south.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_central.id
  allow_forwarded_traffic   = true
}

# Peering: Central to South
resource "azurerm_virtual_network_peering" "central_to_south" {
  name                      = "peer-central-to-south"
  resource_group_name       = azurerm_resource_group.rg_central.name
  virtual_network_name      = azurerm_virtual_network.vnet_central.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_south.id
  allow_forwarded_traffic   = true
}

# 3. Private DNS Zone for Postgres
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg_central.name
}


# 4. Link Postgres DNS to BOTH VNets (South and Central)
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link_central" {
  name                  = "central-vnet-link"
  resource_group_name   = azurerm_resource_group.rg_central.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet_central.id
}


resource "azurerm_private_dns_zone_virtual_network_link" "dns_link_south" {
  name                  = "south-vnet-link"
  resource_group_name   = azurerm_resource_group.rg_central.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet_south.id
}

# 5. The Postgres Flexible Server
resource "azurerm_postgresql_flexible_server" "db" {
  name                = "pg-flex-india"
  resource_group_name = azurerm_resource_group.rg_central.name
  location            = azurerm_resource_group.rg_central.location
  version             = "13"
  delegated_subnet_id = azurerm_subnet.db_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres_dns.id
  zone                = "1"

  public_network_access_enabled = false

  administrator_login    = "psqladmin"
  administrator_password = "SecurePassword123!" # Use a Secret Manager in Prod
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"

  # Recommended: Add this to prevent accidental password resets during future plans
  lifecycle {
    ignore_changes = [
      administrator_password
    ]
  }
}


# NSG for the Database Subnet
resource "azurerm_network_security_group" "db_nsg" {
  name                = "nsg-postgres"
  location            = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name

  security_rule {
    name                       = "AllowAKSTraffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.1.1.0/24" # AKS Subnet Range
    destination_address_prefix = "*"
  }
}

# Associate NSG to the DB Subnet
resource "azurerm_subnet_network_security_group_association" "db_assoc" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}