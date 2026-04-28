# 1. Resource Groups
resource "azurerm_resource_group" "rgs" {
  for_each = var.resource_groups
  name     = each.key
  location = each.value.location
}

# 2. Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = var.hub_config.name
  address_space       = var.hub_config.address_space
  location            = azurerm_resource_group.rgs[var.hub_config.rg].location
  resource_group_name = azurerm_resource_group.rgs[var.hub_config.rg].name
}

# 3. Spoke Virtual Networks (Meta-argument: for_each)
resource "azurerm_virtual_network" "spokes" {
  for_each            = var.spoke_vnets
  name                = "vnet-spoke-${each.key}"
  address_space       = each.value.address_space
  location            = azurerm_resource_group.rgs[each.value.rg].location
  resource_group_name = azurerm_resource_group.rgs[each.value.rg].name
}

# 4. Peering: Spoke -> Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = var.spoke_vnets
  name                      = "peer-${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.rgs[each.value.rg].name
  virtual_network_name      = azurerm_virtual_network.spokes[each.key].name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# 5. Peering: Hub -> Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = var.spoke_vnets
  name                      = "peer-hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.rgs[var.hub_config.rg].name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spokes[each.key].id
}


resource "azurerm_virtual_network_peering" "aks-to-postgres" {
  name                      = "peer-aks-to-postgres-flexi-server"
  resource_group_name       = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  virtual_network_name      = azurerm_virtual_network.spokes["aks"].name
  remote_virtual_network_id = azurerm_virtual_network.spokes["data"].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "postgres-to-aks" {
  name                      = "peer-postgres-flexi-server-to-aks"
  resource_group_name       = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  virtual_network_name      = azurerm_virtual_network.spokes["data"].name
  remote_virtual_network_id = azurerm_virtual_network.spokes["aks"].id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}


resource "azurerm_subnet" "spoke_subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rgs[var.spoke_vnets[each.value.vnet_key].rg].name
  virtual_network_name = azurerm_virtual_network.spokes[each.value.vnet_key].name
  address_prefixes     = each.value.address_prefixes

  service_endpoints = each.value.service_endpoints

  # Dynamic block for Subnet Delegation (required for Postgres Flexible Server
  # dynamic "delegation" {
  #   for_each = each.value.delegation == "postgres" ? [1] : []
  #   content {
  #     name = "delegation"
  #     service_delegation {
  #       name    = "Microsoft.DBforPostgreSQL/flexibleServers"
  #       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  #     }
  #   }
  # }
}

# New resource for the Hub's internal subnets (like App Gateway)
resource "azurerm_subnet" "hub_subnets" {
  for_each             = var.hub_subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rgs[var.hub_config.rg].name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints


  dynamic "delegation" {
    # Only create this block if service_delegation is not null
    for_each = each.value.service_delegation != null ? [1] : []

    content {
      name = "delegation"
      service_delegation {
        name    = each.value.service_delegation
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

moved {
  from = azurerm_subnet.hub_subnets
  to   = azurerm_subnet.hub_subnets["snet-appgw"]
}

moved {
  from = azurerm_subnet.hub_subnet_for_appgw
  to   = azurerm_subnet.hub_subnets["snet-agw_new"]
}


# 1. The Two-Way Routing Requirement
# Direction 1: Spoke A → Spoke B (The Request)
# Location: Subnet in Spoke A.

# UDR: Address Prefix 10.2.0.0/16 (Spoke B) → Next Hop 10.0.1.4 (Firewall).

# Firewall Policy: Allow 10.1.0.0/16 to 10.2.0.0/16.

# Direction 2: Spoke B → Spoke A (The Response)
# Location: Subnet in Spoke B.

# UDR: Address Prefix 10.1.0.0/16 (Spoke A) → Next Hop 10.0.1.4 (Firewall).

# Firewall Policy: (Usually covered by the same rule, but the routing must exist).



# 1. Define the RTs using the EXACT same keys as your var.subnets
# resource "azurerm_route_table" "spoke_rts" {
#   for_each = {
#     "snet-aks"    = { destination = "10.2.0.0/16", name = "rt-aks" }
#     "snet-client" = { destination = "10.1.0.0/16", name = "rt-client" }
#   }

#   name                = each.value.name
#   location            = azurerm_resource_group.rgs["rg-spoke-workloads"].location
#   resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name

#   route {
#     name                   = "to-opposite-spoke"
#     address_prefix         = each.value.destination
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address # Your Hub Firewall IP
#   }

#   depends_on = [azurerm_public_ip.fw_pip]
# }

# # 2. Selective Association
# resource "azurerm_subnet_route_table_association" "spoke_associations" {
#   for_each = azurerm_route_table.spoke_rts

#   # This uses 'each.key' (e.g., "snet-aks") to find the matching subnet 
#   # in your existing azurerm_subnet.spoke_subnets resource.
#   subnet_id      = azurerm_subnet.spoke_subnets[each.key].id
#   route_table_id = azurerm_route_table.spoke_rts[each.key].id
# }


# # 1. Create a Public IP for the NAT Gateway
# resource "azurerm_public_ip" "nat_pip" {
#   name                = "pip-aks-nat"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # 2. Create the NAT Gateway
# resource "azurerm_nat_gateway" "aks_nat" {
#   name                    = "nat-aks-outbound"
#   location                = var.location
#   resource_group_name     = azurerm_resource_group.rgs["rg-spoke-workloads"].name
#   sku_name                = "Standard"
#   idle_timeout_in_minutes = 4
# }

# # 3. Associate the Public IP with the NAT Gateway
# resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
#   nat_gateway_id       = azurerm_nat_gateway.aks_nat.id
#   public_ip_address_id = azurerm_public_ip.nat_pip.id
# }

# # 4. Attach the NAT Gateway to your AKS Subnet
# resource "azurerm_subnet_nat_gateway_association" "aks_nat_assoc" {
#   subnet_id      = azurerm_subnet.spoke_subnets["snet-aks"].id
#   nat_gateway_id = azurerm_nat_gateway.aks_nat.id
# }