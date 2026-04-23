resource "azurerm_private_endpoint" "kv_pe" {
  name                = "kv-private-endpoint"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  subnet_id           = azurerm_subnet.spoke_subnets["snet-client"].id

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv_dns_zone.id]
  }
}

resource "azurerm_private_dns_zone" "kv_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
}


resource "azurerm_private_dns_zone_virtual_network_link" "kv_agent_dns_link" {
  name                  = "kv-dns-link-agents"
  resource_group_name   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.spokes["client-and-agent"].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_aks_dns_link" {
  name                  = "kv-dns-link-aks"
  resource_group_name   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.spokes["aks"].id
}


resource "azurerm_private_dns_zone_virtual_network_link" "kv_db_dns_link" {
  name                  = "kv-dns-link-db"
  resource_group_name   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.spokes["data"].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_appservice_dns_link" {
  name                  = "kv-dns-link-appservice"
  resource_group_name   = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_key_vault" "kv" {
  name                          = "anuroop-kv-${random_string.suffix.result}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"


    bypass = "AzureServices"

    ip_rules = ["122.183.54.41/32", "106.202.107.38/32"]

  }
  # roles applied will take effect with this new feature
  rbac_authorization_enabled = true


  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    azurerm_subnet.spoke_subnets
  ]

}


# Collect the default secrets and secrets stored inside the .tfvars first
locals {
  final_secrets_map = merge(var.default_secrets, var.kv_secrets)

  role_assignments = [
    {
      role         = "Key Vault Secrets User"
      scope        = azurerm_key_vault.kv.id
      principal_id = azurerm_user_assigned_identity.aks_db_access_identity.principal_id
    },
    {
      role         = "Storage Blob Data Contributor"
      scope        = azurerm_storage_account.storage.id
      principal_id = azurerm_user_assigned_identity.aks_db_access_identity.principal_id
    },
    {
      role         = "Key Vault Secrets User"
      scope        = azurerm_key_vault.kv.id
      principal_id = azurerm_user_assigned_identity.agent_identity.principal_id
    }
  ]
}

resource "azurerm_role_assignment" "main" {
  for_each = {
    for idx, r in local.role_assignments : "${r.role}-${idx}" => r
  }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

resource "azurerm_key_vault_secret" "db_secrets" {
  for_each     = local.final_secrets_map
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

# Federated Identity specifying namespace and the serviceAccount of AKS
resource "azurerm_federated_identity_credential" "db_access_federation" {
  name = "aks-db-access-federation"

  audience = ["api://AzureADTokenExchange"]

  # This points to the OIDC Issuer URL of your specific AKS cluster
  issuer = azurerm_kubernetes_cluster.private_aks.oidc_issuer_url

  # The ID of the Managed Identity we are federating
  user_assigned_identity_id = azurerm_user_assigned_identity.aks_db_access_identity.id

  subject = "system:serviceaccount:default:psql-auth-sa"
}


moved {
  from = azurerm_role_assignment.storage_contributor
  to   = azurerm_role_assignment.main["Storage Blob Data Contributor-1"]
}

moved {
  from = azurerm_role_assignment.appservice_access_kv_role
  to   = azurerm_role_assignment.main["Key Vault Secrets User-0"]
}

moved {
  from = azurerm_role_assignment.db_access_kv_role
  to   = azurerm_role_assignment.main["Key Vault Secrets User-2"]
}