# The Service Principal for CircleCI
resource "azuread_application" "circleci_oidc" {
  display_name = "circleci-oidc-sp"
}

resource "azuread_service_principal" "circleci_sp" {
  client_id = azuread_application.circleci_oidc.client_id
}

# The Federated Identity Credential
resource "azuread_application_federated_identity_credential" "circleci_federation" {
  application_id = azuread_application.circleci_oidc.id
  display_name   = "circleci-oidc-trust"
  description    = "OIDC for CircleCI"
  audiences      = ["df943366-0e4d-4301-814a-796da580b6cc"]
  issuer         = "https://oidc.circleci.com/org/df943366-0e4d-4301-814a-796da580b6cc"
  subject        = "org/df943366-0e4d-4301-814a-796da580b6cc/project/ee3b3e0e-a9b7-4abe-9d7a-7324ba24e786/user/58bd21dd-34fd-4dfa-be1b-f8909fae9137/vcs-origin/github.com/anuroopps2001/go-db-application/vcs-ref/refs/heads/feature/circleci-metrics"
}

# Grant keyvault access
resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.circleci_sp.object_id
}

# Role to download the kubeconfig
resource "azurerm_role_assignment" "aks_user" {
  scope                = azurerm_kubernetes_cluster.private_aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = azuread_service_principal.circleci_sp.object_id
}