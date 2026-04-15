# Unkike, serviceManagedIdentities, which will be removed once the resource using those identities being deleted,
# UserassignedIdentities will stay intact, even if the resources using these identities gets deleted and also,
# we can attach the sigle userAssignedIdentity to multiple azure resources

resource "azurerm_user_assigned_identity" "agent_identity" {
  name                = "id-circleci-agent"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
}


# Public Ip for the VNet VM, just to avoid the cost of the bastion
resource "azurerm_public_ip" "agent_pip" {
  name                = "pip-circleci-agent"
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network interface for the vm
resource "azurerm_network_interface" "agent_nic" {
  name                = "nic-circleci-agent"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke_subnets["snet-client"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent_pip.id
  }
}

# Create the Agent VM (Runner)
resource "azurerm_linux_virtual_machine" "agent_vm" {
  name                = "vm-circleci-runner"
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  location            = var.location
  size                = "Standard_B2as_v2"
  admin_username      = "azureuser"

  # Attach the Managed Identity above created
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agent_identity.id]
  }

  network_interface_ids = [azurerm_network_interface.agent_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${pathexpand("~/.ssh/id_rsa.pub")}")
  }
  depends_on = [azurerm_user_assigned_identity.agent_identity]
}


resource "azurerm_network_security_group" "agen_nsg" {
  name                = "agent-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rgs["rg-spoke-workloads"].name
  security_rule {
    name                       = "AllowSSHFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach NSG to the agent subnet
resource "azurerm_subnet_network_security_group_association" "agent_ssh_assoc" {
  subnet_id                 = azurerm_subnet.spoke_subnets["snet-client"].id
  network_security_group_id = azurerm_network_security_group.agen_nsg.id
}