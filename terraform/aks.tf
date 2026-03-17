resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "aks-private-india"
  location                = azurerm_resource_group.rg_south.location
  resource_group_name     = azurerm_resource_group.rg_south.name
  dns_prefix              = "aks-private"
  private_cluster_enabled = true # makes the cluster private

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }
}