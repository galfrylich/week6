output "nic_id" {
  value = azurerm_network_interface.webAppNic[var.vm_count.index].id
}