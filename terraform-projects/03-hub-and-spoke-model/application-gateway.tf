# locals {
#   backend_address_pool_name            = "${azurerm_virtual_network.hub.name}-beap"
#   frontend_port_name                   = "${azurerm_virtual_network.hub.name}-feport"
#   frontend_ip_configuration_name       = "${azurerm_virtual_network.hub.name}-feip"
#   http_setting_name                    = "${azurerm_virtual_network.hub.name}-be-htst"
#   grafana_listener_name                = "${azurerm_virtual_network.hub.name}-grafana-httplstn"
#   prometheus_listener_name             = "${azurerm_virtual_network.hub.name}-prometheus-httplstn"
#   grafana_request_routing_rule_name    = "${azurerm_virtual_network.hub.name}-grafana-rqrt"
#   prometheus_request_routing_rule_name = "${azurerm_virtual_network.hub.name}-prometheus-rqrt"
#   redirect_configuration_name          = "${azurerm_virtual_network.hub.name}-rdrcfg"
#   probe_name                           = "${azurerm_virtual_network.hub.name}-health-probe"
#   public_ip_name                       = "${azurerm_virtual_network.hub.name}-pip"

#   https_port_name    = "${azurerm_virtual_network.hub.name}-httpsport"
#   frontend_cert_name = "appgw-frontend-cert"
#   root_ca_name       = "internal-root-ca"
# }

# resource "azurerm_public_ip" "agw_pip" {
#   name                = local.public_ip_name
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   location            = var.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }


# resource "azurerm_application_gateway" "network" {
#   name                = "aks-appgw"
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
#   location            = var.location

#   sku {
#     name     = "Standard_v2"
#     tier     = "Standard_v2"
#     capacity = 2
#   }

#   gateway_ip_configuration {
#     name      = "my-gateway-ip-configuration"
#     subnet_id = azurerm_subnet.hub_subnet_for_appgw.id # newly created for appgateway instance only
#   }



#   frontend_port {
#     name = local.frontend_port_name
#     port = 80
#   }


#   frontend_port {
#     name = local.https_port_name
#     port = 443
#   }


#   frontend_ip_configuration {
#     name                 = local.frontend_ip_configuration_name
#     public_ip_address_id = azurerm_public_ip.agw_pip.id
#   }

#   ssl_certificate {
#     name     = local.frontend_cert_name
#     data     = filebase64("./appgw-frontend.pfx")
#     password = "Anuroopps@2108"
#   }

#   # --- Backend Setup (Pointing to Envoy) ---
#   backend_address_pool {
#     name         = local.backend_address_pool_name
#     ip_addresses = ["10.1.1.7"] # Envoy Internal Load Balancer IP
#   }


#   backend_http_settings {
#     name                                = local.http_setting_name
#     cookie_based_affinity               = "Disabled"
#     port                                = 80
#     protocol                            = "Http"
#     request_timeout                     = 60
#     pick_host_name_from_backend_address = false # Do not override host name so Envoy can read the original header
#     probe_name                          = local.probe_name
#   }

#   probe {
#     name                = local.probe_name
#     protocol            = "Http"
#     path                = "/healthz"
#     interval            = 30
#     timeout             = 30
#     unhealthy_threshold = 3
#     host                = "mygoapp.com"
#   }

#   http_listener {
#     name                           = "http-redirect-listener"
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.frontend_port_name
#     protocol                       = "Http"
#   }



#   http_listener {
#     name                           = "go-application-https-listener"
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.https_port_name
#     protocol                       = "Https"
#     ssl_certificate_name           = local.frontend_cert_name
#     host_name                      = "mygoapp.com"
#   }

#   redirect_configuration {
#     name                 = local.redirect_configuration_name
#     redirect_type        = "Permanent"
#     target_listener_name = "go-application-https-listener" # Redirects everything to the Go app HTTPS
#     include_path         = true
#     include_query_string = true
#   }

#   request_routing_rule {
#     name                        = "http-to-https-redirect-rule"
#     rule_type                   = "Basic"
#     http_listener_name          = "http-redirect-listener"
#     redirect_configuration_name = local.redirect_configuration_name
#     priority                    = 100
#   }

#   request_routing_rule {
#     name                       = "go-app-https-rule"
#     rule_type                  = "Basic"
#     http_listener_name         = "go-application-https-listener"
#     backend_address_pool_name  = local.backend_address_pool_name
#     backend_http_settings_name = local.http_setting_name
#     priority                   = 5
#   }
# }


# # Create the NSG
# resource "azurerm_network_security_group" "appgw_nsg" {
#   name                = "nsg-appgw"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name

#   security_rule {
#     name                       = "AllowHTTPS"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp" # Ensure capitalized 'Tcp'
#     source_port_range          = "*"
#     destination_port_range     = "443" # Ensure no spaces
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "AllowHTTPInbound"
#     priority                   = 110
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "AllowGatewayManager"
#     priority                   = 120
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "65200-65535"
#     source_address_prefix      = "GatewayManager"
#     destination_address_prefix = "*"
#   }
# }

# # Attach the NSG to the App Gateway Subnet
# resource "azurerm_subnet_network_security_group_association" "appgw_nsg_assoc" {
#   subnet_id                 = azurerm_subnet.hub_subnet_for_appgw.id
#   network_security_group_id = azurerm_network_security_group.appgw_nsg.id
# }