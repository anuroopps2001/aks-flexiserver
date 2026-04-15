resource "azuread_group" "devops_engineers" {
  display_name     = "DevOps-Engineers-PIM"
  security_enabled = true
  description      = "Group for JIT access to Azure Resources"
}

resource "azuread_user" "engineer_anuroop" {
  user_principal_name = "anuroop@anuroopps2001outlook.onmicrosoft.com"
  display_name        = "Anuroop"
  password            = "ChangeMe1234!" # Best practice: use a secret manager
}
resource "azuread_group_member" "add_user" {
  group_object_id  = azuread_group.devops_engineers.object_id
  member_object_id = azuread_user.engineer_anuroop.object_id # Corrected to the user's ID
}


# Get the Role Definition for 'Contributor'
data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = data.azurerm_subscription.current.id
}

resource "azurerm_role_assignment" "group_standard_access" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.devops_engineers.object_id

  depends_on = [
    azuread_group.devops_engineers,
    azuread_group_member.add_user
  ]
}