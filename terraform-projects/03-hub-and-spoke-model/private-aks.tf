# Create the zone yourself with a predictable name
resource "azurerm_private_dns_zone" "aks_dns_zone" {
  name                = "privatelink.centralindia.azmk8s.io"
  resource_group_name = azurerm_resource_group.rgs[var.hub_config.rg].name
}

# Link it to your Spoke VNet immediately
resource "azurerm_private_dns_zone_virtual_network_link" "aks_spoke_link" {
  name                  = "link-spoke-vnets"
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.spokes["aks"].id
  resource_group_name   = azurerm_resource_group.rgs[var.hub_config.rg].name
}


resource "azurerm_private_dns_zone_virtual_network_link" "agent_spoke_vnet_akslink" {
  name                  = "link-agent-spoke-vnets"
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.spokes["client-and-agent"].id
  resource_group_name   = azurerm_resource_group.rgs[var.hub_config.rg].name
}

resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = azurerm_private_dns_zone.aks_dns_zone.id # The ID of your 'privatelink.centralindia.azmk8s.io' zone
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.agent_identity.principal_id

  # Crucial: This ensures the permission is granted before AKS tries to use it
  depends_on = [azurerm_private_dns_zone.aks_dns_zone]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id # on which resource, role is assigned
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.agent_identity.principal_id # To whom, permissions are give
}

resource "azurerm_kubernetes_cluster" "private_aks" {
  name                = "aks-private-cluster"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  dns_prefix          = "anuroop-aks"

  # Azure creates a new Private DNS Zone (usually ending in *.privatelink.centralindia.azmk8s.io) in a in a hidden Resource Group
  # and from whatever the vnet I try access the AKS cluster, first I need to link that vnet with PrivateDNSZone got created
  private_cluster_enabled = true # This will keep, AKS API Internal and completly invisible to the internet

  private_dns_zone_id       = azurerm_private_dns_zone.aks_dns_zone.id # custom dns zone instead of using AKS Automatically created
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  default_node_pool {
    name           = "systempool"
    node_count     = 1
    vm_size        = "Standard_B2as_v2"
    vnet_subnet_id = azurerm_subnet.spoke_subnets["snet-aks"].id


    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agent_identity.id] # To pull the images from ACR
  }
  network_profile {
    network_plugin      = "azure"
    network_data_plane  = "azure"
    network_plugin_mode = "overlay"


    pod_cidr       = "192.168.0.0/16"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"

    load_balancer_sku = "standard"
  }

  # For using secrets stored inside keyVault through the federated identities of managed identities
  key_vault_secrets_provider {
    secret_rotation_enabled  = true # Optional: Automatically syncs KV changes to K8s
    secret_rotation_interval = "2m" # Optional: How often to poll for updates

    # kube-system   aks-secrets-store-csi-driver-7scxq                       3/3     Running   0          20s
    # kube-system   aks-secrets-store-provider-azure-v6ch8                   1/1     Running   0          20s
  }

  depends_on = [
    azurerm_role_assignment.aks_dns_contributor, # Wait for the permission!
    azurerm_role_assignment.acr_pull             # Wait for ACR access too
  ]
}


resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_subnet.spoke_subnets["snet-aks"].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.agent_identity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.agent_identity
  ]
}