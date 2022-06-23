# internal workstation to connect the app machines

resource "azurerm_public_ip" "ansiblePip" {
  name                = "stationPublicIP"
  location            = azurerm_resource_group.webApp.location
  resource_group_name = azurerm_resource_group.webApp.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "ansible" {
  name                = "${var.prefix}-ansibleNIC"
  location            = azurerm_resource_group.webApp.location
  resource_group_name = azurerm_resource_group.webApp.name

  ip_configuration {
    name                          = "ansibleNicConfiguration"
    subnet_id                     = azurerm_subnet.ansible.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ansiblePip.id
  }
}

resource "azurerm_virtual_machine" "ansibel-vm" {
  name                  = "${var.prefix}-ansibleVM"
  location              = azurerm_resource_group.webApp.location
  resource_group_name   = azurerm_resource_group.webApp.name
  network_interface_ids = [azurerm_network_interface.ansible.id]
  vm_size               = "Standard_B1ls"

  storage_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "webOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.ansible_username
    admin_password = var.ansible_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  
}

#ansible workstation network resources

resource "azurerm_subnet" "ansible" {
  name                 = "ansible-subnet"
  resource_group_name  = azurerm_resource_group.webApp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "ansible-nsg" {
  name                = "ansible-nsg"
  location            = azurerm_resource_group.webApp.location
  resource_group_name = azurerm_resource_group.webApp.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" #security
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "blockOther"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ansible-association" {
  subnet_id                 = azurerm_subnet.ansible.id
  network_security_group_id = azurerm_network_security_group.ansible-nsg.id
}
