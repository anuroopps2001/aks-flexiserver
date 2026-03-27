# 1. Create a Public IP for the Client VM (to allow you to SSH in)
resource "azurerm_public_ip" "client_ip" {
  name                = "pip-client-vm"
  location            = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 2. Create the Network Interface (NIC)
resource "azurerm_network_interface" "client_nic" {
  name                = "nic-client-vm"
  location            = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client_ip.id
  }
}


# 3. Create a Linux Virtual Machine (Ubuntu 24.04)
resource "azurerm_linux_virtual_machine" "client_vm" {
  name                = "client-management-vm"
  resource_group_name = azurerm_resource_group.rg_central.name
  location            = azurerm_resource_group.rg_central.location
  size                = "Standard_D2s_v3" # Cost-effective for a jumpbox
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.client_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${pathexpand("~/.ssh/id_rsa.pub")}") # Ensure this file exists on your local machine
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  tags = {
    "managedby" = "terraform"
  }
}

resource "azurerm_network_security_group" "client_nsg" {
  name                = "nsg-client-management"
  location            = azurerm_resource_group.rg_central.location
  resource_group_name = azurerm_resource_group.rg_central.name

  security_rule       = [
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = null
            destination_port_ranges                    = [
                "3000",
                "9090",
            ]
            direction                                  = "Inbound"
            name                                       = "grafana"
            priority                                   = 110
            protocol                                   = "*"
            source_address_prefix                      = "122.168.68.85"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = "22"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "SSH"
            priority                                   = 100
            protocol                                   = "Tcp"
            source_address_prefix                      = "*"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
        {
            access                                     = "Allow"
            description                                = null
            destination_address_prefix                 = "*"
            destination_address_prefixes               = []
            destination_application_security_group_ids = []
            destination_port_range                     = "8080"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "go-app"
            priority                                   = 120
            protocol                                   = "*"
            source_address_prefix                      = "122.168.68.85"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
    ]
}

# Attach client vm nsg to the client vm subnet
resource "azurerm_subnet_network_security_group_association" "clientvm_assoc" {
  subnet_id                 = azurerm_subnet.client_subnet.id
  network_security_group_id = azurerm_network_security_group.client_nsg.id
  
  }