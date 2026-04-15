resource "azurerm_storage_container" "loki_container" {
  name = var.container_name
  storage_account_id = var.storage_account_id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "loki_identity" {
  name = "${var.name}-identity"
  location = var.location
  resource_group_name = var.resource_group_name
}

# 3. Assign RBAC (Blob Data Contributor)
resource "azurerm_role_assignment" "loki_role_assignement" {
  scope = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = azurerm_user_assigned_identity.loki_identity.principal_id
}

# 4. Create Federated Identity for Workload Identity
resource "azurerm_federated_identity_credential" "loki_fed_identity" {
  name = "${var.name}-fed-identity"
  audience = [ "api://AzureADTokenExchange" ]
  issuer = var.oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.loki_identity.id
  subject = "system:serviceaccount:${var.namespace}:${var.name}"
}