resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}


# resource "azurerm_container_registry" "acr" {
#   name                = "anuroopregistry${random_string.suffix.result}"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   sku                 = "Premium"
#   admin_enabled       = false

#   public_network_access_enabled = false
# }

# # Permissions for UserAssignedIdentity which is being used by agent VMs to push the images into ACR
# resource "azurerm_role_assignment" "acr_push" {
#   scope                = azurerm_container_registry.acr.id # on which resource, role is assigned
#   role_definition_name = "AcrPush"
#   principal_id         = azurerm_user_assigned_identity.agent_identity.principal_id # To whom, permissions are give
# }

# # CircleCI Agent (App Spoke) → Peering → Hub VNet → Private Endpoint → ACR.
# # PrivateEndpoint is a combo of 2 terraform resources
# # 1. The Endpoint itself (azurerm_private_endpoint): This creates the "Network Interface" in your subnet.
# # 2. The Private DNS Zone (azurerm_private_dns_zone): This is the "Phonebook." It tells your VNets: "Hey, if you're looking for anuroop.azurecr.io, don't look on the web—go to the private IP 10.0.1.5."


# # The "Phonebook" for Private ACR
# # If anyone wants to reach acr via hostname, reach via this IP 
# resource "azurerm_private_dns_zone" "acr_dns" {
#   name                = "privatelink.azurecr.io"
#   resource_group_name = azurerm_resource_group.rgs[var.hub_config.rg].name
# }

# # Link the DNS Zone to the all Spokes vnets, Defines who are allowed to resolve hostnames to IPs in Private DNS zone
# resource "azurerm_private_dns_zone_virtual_network_link" "spoke_vnets_link" {
#   for_each              = var.spoke_vnets
#   name                  = "link-${each.key}"
#   resource_group_name   = azurerm_resource_group.rgs[var.hub_config.rg].name
#   private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
#   virtual_network_id    = azurerm_virtual_network.spokes[each.key].id

#   depends_on = [azurerm_private_dns_zone.acr_dns]
# }

# # Similarly, Link the DNS Zone to the all HUB vnets
# resource "azurerm_private_dns_zone_virtual_network_link" "hub_vnet_link" {
#   name                  = "link-hub"
#   resource_group_name   = azurerm_resource_group.rgs[var.hub_config.rg].name
#   private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
#   virtual_network_id    = azurerm_virtual_network.hub.id

#   depends_on = [azurerm_private_dns_zone.acr_dns]
# }

# # Private Endpoint
# # This places the ACR's private NIC into your Hub VNet
# resource "azurerm_private_endpoint" "acr_pe" {
#   name                = "pe-acr-hub"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs[var.hub_config.rg].name
#   subnet_id           = azurerm_subnet.hub_subnets.id

#   private_service_connection {
#     name                           = "acr-privatelink"
#     private_connection_resource_id = azurerm_container_registry.acr.id
#     is_manual_connection           = false
#     subresource_names              = ["registry"]
#   }

#   # This block automatically creates an "A" record in your Private DNS zone for ACR hostname.
#   private_dns_zone_group { # injected that A record into the zone.
#     name                 = "acr-dns-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns.id]
#   }
# }