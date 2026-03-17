# Resource Group for South India (AKS)
resource "azurerm_resource_group" "rg_south" {
  name     = "rg-aks-southindia"
  location = "southindia"
}

# Resource Group for Central India (Postgres)
resource "azurerm_resource_group" "rg_central" {
  name     = "rg-db-centralindia"
  location = "centralindia"
}