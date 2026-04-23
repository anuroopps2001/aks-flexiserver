# resource "azurerm_subnet" "fw_subnet" {
#   name                 = "AzureFirewallSubnet" # name should be same for firewall
#   resource_group_name  = azurerm_resource_group.rgs["rg-hub-networking"].name
#   virtual_network_name = azurerm_virtual_network.hub.name
#   address_prefixes     = ["10.0.0.0/26"] # range should be /26
# }

# # Public IP for the Firewall
# resource "azurerm_public_ip" "fw_pip" {
#   name                = "pip-hub-fw"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# # Firewall Policy (Modern way to manage rules)
# resource "azurerm_firewall_policy" "hub_policy" {
#   name                = "fwp-hub-core"
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   location            = var.location
#   sku                 = "Standard"
# }

# # The Azure Firewall
# resource "azurerm_firewall" "hub_fw" {
#   name                = "afw-hub-core"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"
#   firewall_policy_id  = azurerm_firewall_policy.hub_policy.id

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.fw_subnet.id
#     public_ip_address_id = azurerm_public_ip.fw_pip.id
#   }
# }

# resource "azurerm_firewall_policy_rule_collection_group" "workload_rules" {
#   name               = "fw-policy-workload-rules"
#   firewall_policy_id = azurerm_firewall_policy.hub_policy.id
#   priority           = 200


#   network_rule_collection {
#     name     = "aks-internal-traffic"
#     priority = 100
#     action   = "Allow"

#     rule {
#       name                  = "allow-agent-to-aks"
#       protocols             = ["TCP", "UDP", "ICMP"]
#       source_addresses      = ["10.2.1.0/24"] # agent subnet range
#       destination_addresses = ["10.1.1.0/24"] # aks subnet range

#       destination_ports = ["*"]
#     }
#   }
# }


# # To see the firewall logs we have to send the logs to LAW

# resource "azurerm_log_analytics_workspace" "hub_law" {
#   name                = "law-hub-shared-logging"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

# resource "azurerm_monitor_diagnostic_setting" "fw_diag" {
#   name                       = "fw-diagnostics"
#   target_resource_id         = azurerm_firewall.hub_fw.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.hub_law.id


# # by setting log_analytics_destination_type to Dedicated, logs are sent to resource-specific tables like AZFWNetworkRule
#   log_analytics_destination_type = "Dedicated"

#   enabled_log {
#     category = "AzureFirewallNetworkRule"
#   }


#   enabled_log {
#     category = "AzureFirewallApplicationRule"
#   }

#   enabled_metric {
#     category = "AllMetrics"
#   }
# }