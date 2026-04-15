
resource "azurerm_key_vault" "kv" {
  name                = "anuroop-kv-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  network_acls {
    default_action = "Deny"

    virtual_network_subnet_ids = [
      azurerm_subnet.spoke_subnets["snet-aks"].id,   # # Allow AKS Pods to fetch secrets
      azurerm_subnet.spoke_subnets["snet-client"].id # # Allow your Management VM to fetch secrets
    ]


    bypass = "AzureServices"

    ip_rules = ["223.185.131.59/32", "122.168.64.57/32", "122.168.65.109/32", "122.168.64.15/32"] # From my laptop
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
}

resource "azurerm_key_vault_secret" "db_secrets" {
  for_each     = local.final_secrets_map
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

# Grant this specific identity access to the Key Vault
resource "azurerm_role_assignment" "db_access_kv_role" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_db_access_identity.principal_id
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

# Assign the Role to the Storage Account
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_db_access_identity.principal_id
}
