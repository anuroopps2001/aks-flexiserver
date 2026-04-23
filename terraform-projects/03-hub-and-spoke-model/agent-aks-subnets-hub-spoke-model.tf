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