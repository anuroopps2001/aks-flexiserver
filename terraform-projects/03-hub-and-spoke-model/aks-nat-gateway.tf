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