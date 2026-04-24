data "archive_file" "frontend_zip" {
  type       = "zip"
  source_dir = "${path.module}/app"
  # This creates a unique filename based on the content hash
  output_path = "${path.module}/frontend.zip"

}

resource "azurerm_service_plan" "frontend_plan" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "frontend_app" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.frontend_plan.id
  ## Manually slot the code into prod appservice, once tested in staging deployment slot 
  # zip_deploy_file = data.archive_file.frontend_zip.output_path

  virtual_network_subnet_id = var.app_service_subnet_id 

  site_config {
    application_stack {
      node_version = "20-lts"
    }
    health_check_path = "/health" # Appservice will the endpoint before making sure the resource is ready to accept the requests or not
    # How long to wait before deciding the instance is dead
    health_check_eviction_time_in_min = 2
    vnet_route_all_enabled            = true
  }


  app_settings = merge(var.common_app_settings, {
    ENVIRONMENT                                = "production",
    APP_VERSION                                = "v1",
    BUILD_TIME                                 = var.build_time,
    "APPLICATION_INSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string,
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3",
    "XDT_MicrosoftApplicationInsights_Mode"      = "Recommended"
    XDT_MicrosoftApplicationInsights_NodeJS    = "1"
  })

  # Standard Settings (The "Suitcase"): These settings are packed inside the code. When the code moves from Staging to 
  #  Production, the settings travel with it.

  # Sticky Settings (The "Furniture"): These settings belong to the room (the slot). No matter who moves into the
  #  room (Version 1 or Version 2 of your code), they have to use the furniture already there.
  sticky_settings {
    # Sticky settings: Stay with the slot
    # Non-sticky settings: Move with the code
    app_setting_names = ["API_BASE_URL", "ENVIRONMENT", "APP_VERSION", "BUILD_TIME"]
  }


  # app_settings = {
  #   WEBSITES_PORT = "3000"
  #   API_BASE_URL  = var.aks_ingress_url
  #   SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  #   STARTUP_COMMAND = "npm start"
  #   API_BASE_URL = "http://4.247.194.93"
  #   WEBSITE_VNET_ROUTE_ALL = "1"  # force all outbound traffic from the App Service into your VNet
  #   WEBSITE_DNS_SERVER = "168.63.129.16"
  # }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  key_vault_reference_identity_id = var.user_assigned_identity_id
}

resource "azurerm_linux_web_app_slot" "staging" {
  count           = var.enable_staging_slot ? 1 : 0
  name            = "staging"
  zip_deploy_file = data.archive_file.frontend_zip.output_path
  app_service_id  = azurerm_linux_web_app.frontend_app.id
  virtual_network_subnet_id = var.app_service_subnet_id

  site_config {
    application_stack {
      node_version = "20-lts"
    }
    health_check_path = "/health"
    # How long to wait before deciding the instance is dead
    health_check_eviction_time_in_min = 2
    vnet_route_all_enabled            = true
  }

  app_settings = merge(var.common_app_settings, {
    ENVIRONMENT = "staging",
    APP_VERSION = "v2",
    BUILD_TIME  = var.build_time,
    "APPLICATION_INSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string,
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3",
    "XDT_MicrosoftApplicationInsights_Mode"      = "Recommended"
  })

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  key_vault_reference_identity_id = var.user_assigned_identity_id

  tags = {
    code_hash = data.archive_file.frontend_zip.output_base64sha256
  }
}

# Application insights for the appservice
resource "azurerm_application_insights" "appinsights" {
  name                = "${var.app_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}


resource "azurerm_network_security_group" "app_service_nsg" {
  name = "nsg-app-service-integration"
  location = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "allow_aks_outbound" {
  name = "Allow-Outbound"
  priority = 100
  direction = "Outbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "80"
  source_address_prefix = "*"
  destination_address_prefix = "10.1.1.6"
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app_service_nsg.name
}

resource "azurerm_network_security_rule" "allow_kv_outbound" {
  name = "Allow-KeyVault-Outbound"
  priority = 110
  direction = "Outbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "443"
  source_address_prefix = "*"
  destination_address_prefix = "10.2.1.5"
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app_service_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id = var.app_service_subnet_id
  network_security_group_id = azurerm_network_security_group.app_service_nsg.id
}