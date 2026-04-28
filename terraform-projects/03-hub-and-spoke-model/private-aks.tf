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

# resource "azurerm_role_assignment" "acr_pull" {
#   scope                = azurerm_container_registry.acr.id # on which resource, role is assigned
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_user_assigned_identity.agent_identity.principal_id # To whom, permissions are give
# }

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

  azure_policy_enabled = true  # This ensure, Gatekeeper addon will be deployed on aks and policies will be tested against this
  
  default_node_pool {
    name           = "systempool"
    vm_size        = "Standard_B2as_v2"
    vnet_subnet_id = azurerm_subnet.spoke_subnets["snet-aks"].id



    # Azure creates a new pool named tempnodepool.
    # Azure migrates your system pods to the temporary pool.
    # Azure deletes your old systempool nodes.
    # Azure recreates the systempool with your new settings (the taint).
    # Azure moves the pods back and deletes the temporary pool.


    # temporary_name_for_rotation = "tempnodepool"
    # only_critical_addons_enabled = true # It will taint the nodes
    # auto_scaling_enabled         = true
    # min_count                    = 1
    # max_count                    = 2
    # node_count                   = 1 # This becomes the 'starting' count

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
    # azurerm_role_assignment.acr_pull             # Wait for ACR access too
  ]
}


# dedicated user workload related pool
# resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
#   name                  = "workloadpool"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.private_aks.id
#   vm_size               = "Standard_B2as_v2"
#   vnet_subnet_id        = azurerm_subnet.spoke_subnets["snet-aks"].id


#   auto_scaling_enabled = true
#   node_count           = 1
#   min_count            = 1
#   max_count            = 2

#   node_taints = ["workload=production:NoSchedule"]

#   node_labels = {
#     "role" = "user-workloads"
#   }
# }

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_subnet.spoke_subnets["snet-aks"].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.agent_identity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.agent_identity
  ]
}


# Custom policies for Enforce CPU and Memory Limits
resource "azurerm_resource_policy_assignment" "enforce_cpu_limits" {
  name = "aks-enforce-limits"

  # Built-in ID for "Kubernetes cluster containers should have CPU and memory limits"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/03a4ecdb-0684-4039-be91-2762979e1bc8"
  description = "Ensures all containers have CPU/Memory requests and limits to prevent node exhaustion."
  resource_id = azurerm_kubernetes_cluster.private_aks.id
  display_name = "CPU Enforment Policy"  

  parameters = jsonencode({
    effect = {
      value = "Audit"  # This won't break your deployments, but it will list every "non-compliant" pod in the Azure Portal
      # For Hard Setting, we can apply value = "deny"
    }
  })
  
}

resource "azurerm_network_security_group" "aks_custom_nsg" {
  name                = "nsg-aks-custom-control"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
}

resource "azurerm_network_security_rule" "deny_envoy_access" {
  name                        = "Deny-envoy-traffic"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "10.0.3.0/24"
  destination_address_prefix  = "10.1.1.6"
  resource_group_name         = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  network_security_group_name = azurerm_network_security_group.aks_custom_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "aks_custom_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke_subnets["snet-aks"].id
  network_security_group_id = azurerm_network_security_group.aks_custom_nsg.id
}
