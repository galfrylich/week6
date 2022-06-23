 resource "azurerm_virtual_machine" "webVms" {
  count                 =  var.vm_count             
  name                  = "webVm${count.index}"
  location              = var.location
  resource_group_name   = var.name
  network_interface_ids = [azurerm_network_interface.webAppNic[count.index].id]
  vm_size               = "Standard_B1ls"

  storage_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "webOsDisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.web_username
    admin_password = var.web_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  
}

resource "azurerm_network_interface" "webAppNic" {
  count               =  var.vm_count 
  name                = "webNic${count.index}"
  location            = var.location
  resource_group_name = "${var.prefix}rg"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.azurerm_subnet
    private_ip_address_allocation = "Dynamic"
  }
}