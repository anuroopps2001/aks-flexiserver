locals {
  backend_address_pool_name      = "${azurerm_virtual_network.vnet_central.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.vnet_central.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet_central.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.vnet_central.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.vnet_central.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet_central.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.vnet_central.name}-rdrcfg"
  probe_name                     = "${azurerm_virtual_network.vnet_central.name}-health-probe"
}

# NSG for AppGateway
resource "azurerm_network_security_group" "appgw_nsg" {
  name = "appgw_nsg"
  location = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name
}
# For AppGateway to handle user's requests at the top of azure
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg_central.name
  virtual_network_name = azurerm_virtual_network.vnet_central.name
  address_prefixes     = ["10.2.3.0/24"]
}

# Attach NSG to the AppGateway subnet
resource "azurerm_subnet_network_security_group_association" "appgw_assoc" {
  subnet_id = azurerm_subnet.appgw_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}

resource "azurerm_network_security_rule" "allow_gateway_manager" {
  name                        = "AllowGatewayManagerInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "GatewayManager" # This is the Service Tag
  source_port_range           = "*"
  destination_port_range      = "65200-65535"   # As specified in the error
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_central.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "AllowAnyHTTPInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_port_range      = "80"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_central.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_network_security_rule" "allow_https" {
  name                        = "AllowAnyHTTPSInbound"
  priority                    = 101 # Set this close to your HTTP rule (100)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "Internet"
  source_port_range           = "*"
  destination_port_range      = "443"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg_central.name
  network_security_group_name = azurerm_network_security_group.appgw_nsg.name
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "appgw-pip"
  location            = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "aks-appgw"
  resource_group_name = azurerm_resource_group.rg_central.name
  location            = azurerm_resource_group.rg_central.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "aks-appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

 frontend_port {
   name = local.frontend_port_name
   port = 80
 }
  frontend_port {
    name = "https-port"
    port = 443
  }
  ssl_certificate {
    name = "app1-cert"
    data = filebase64("D:/circle-ci-cd/ssl-certs/app1-local.pfx")
    password = "Anuroopps@2108"
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    # servers IPs of nodepool created by aks
    ip_addresses = [
      "10.1.1.5"
    ]
  }

  # Health probes for checking health of BackendPool
  probe {
    name                = local.probe_name
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    # Just like we hit node_ip:nodePort, appgateway also, needs to get and get the response
    # if used curl -I http://node_ip:nodePort , we will get 404 and to avoid this hitting actual application
    host = "app1.local" # domain name of my application


    match {
      status_code = [ "200-399" ] # since using ssl cert for *.local inside cluster, http request will receive 301 from AKS nginx fabric api gateway 
    }
  }
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"

    # azureuser@client-management-vm:~/aks-flexiserver$ kubectl get svc -n nginx-gateway
    # NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)                      AGE
    # ngf-nginx-gateway-fabric   LoadBalancer   10.0.176.33   10.1.1.6      80:31190/TCP,443:32636/TCP   23h
    # azureuser@client-management-vm:~/aks-flexiserver$ curl -k http://10.1.1.6:31190
    # ^C
    # azureuser@client-management-vm:~/aks-flexiserver$ kubectl get no -owide
    # NAME                              STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
    # aks-default-19100529-vmss000006   Ready    <none>   3h12m   v1.33.6   10.1.1.5      <none>        Ubuntu 22.04.5 LTS   5.15.0-1102-azure   containerd://1.7.30-2
    # azureuser@client-management-vm:~/aks-flexiserver$ curl -k http://10.1.1.5:31190
    # <html>
    # <head><title>404 Not Found</title></head>
    # <body>
    # <center><h1>404 Not Found</h1></center>
    # <hr><center>nginx</center>
    # </body>
    # </html>
    # azureuser@client-management-vm:~/aks-flexiserver$

    # azureuser@client-management-vm:~/aks-flexiserver$ curl -H "Host: app1.local" -k -L http://10.1.1.5:31190/
    # hello-ngf
    # azureuser@client-management-vm:~/aks-flexiserver$

    port            = 31190 # Nginx Fabric API Gateway service nodePort from nginx-ingress namespace as shown above
    protocol        = "Http"
    request_timeout = 60
    probe_name      = local.probe_name
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  http_listener {
    name = "${local.listener_name}-https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name = "https-port"
    protocol = "Https"
    ssl_certificate_name = "app1-cert"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  request_routing_rule {
  name                       = "${local.request_routing_rule_name}-https"
  priority                   = 10 # Priority must be unique (HTTP was 9)
  rule_type                  = "Basic"
  http_listener_name         = "${local.listener_name}-https" # The new HTTPS listener
  backend_address_pool_name  = local.backend_address_pool_name
  backend_http_settings_name = local.http_setting_name
}

}