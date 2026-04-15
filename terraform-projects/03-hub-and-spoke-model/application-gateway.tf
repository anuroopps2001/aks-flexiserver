locals {
  backend_address_pool_name            = "${azurerm_virtual_network.hub.name}-beap"
  frontend_port_name                   = "${azurerm_virtual_network.hub.name}-feport"
  frontend_ip_configuration_name       = "${azurerm_virtual_network.hub.name}-feip"
  http_setting_name                    = "${azurerm_virtual_network.hub.name}-be-htst"
  grafana_listener_name                = "${azurerm_virtual_network.hub.name}-grafana-httplstn"
  prometheus_listener_name             = "${azurerm_virtual_network.hub.name}-prometheus-httplstn"
  grafana_request_routing_rule_name    = "${azurerm_virtual_network.hub.name}-grafana-rqrt"
  prometheus_request_routing_rule_name = "${azurerm_virtual_network.hub.name}-prometheus-rqrt"
  redirect_configuration_name          = "${azurerm_virtual_network.hub.name}-rdrcfg"
  probe_name                           = "${azurerm_virtual_network.hub.name}-health-probe"
  public_ip_name                       = "${azurerm_virtual_network.hub.name}-pip"
}

resource "azurerm_public_ip" "agw_pip" {
  name                = local.public_ip_name
  resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_application_gateway" "network" {
  name                = "aks-appgw"
  resource_group_name = azurerm_resource_group.rgs["rg-hub-networking"].name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.hub_subnet_for_appgw.id # newly created for appgateway instance only
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.agw_pip.id
  }

  # --- Backend Setup (Pointing to Envoy) ---
  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = ["10.1.1.6"] # Envoy Internal Load Balancer IP
  }


  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = false # Do not override host name so Envoy can read the original header
    probe_name                          = local.probe_name
  }


  # --- Grafana Routing ---
  http_listener {
    name                           = local.grafana_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    host_name                      = "grafana.internal.com"
  }

  request_routing_rule {
    name                       = local.grafana_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.grafana_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 10
  }

  # --- Prometheus Routing ---
  http_listener {
    name                           = local.prometheus_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    host_name                      = "prometheus.internal.com"
  }

  request_routing_rule {
    name                       = local.prometheus_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.prometheus_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 20
  }

  // Go application listener rule
  http_listener {
    name                           = "go-application-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    host_name                      = "go-db-app.internal.com"
  }

  request_routing_rule {
    name                       = "go-application-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "go-application-listener"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 30
  }

  probe {
    name                = local.probe_name
    protocol            = "Http"
    path                = "/metrics"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "prometheus.internal.com"
  }
}