

output "resource_linux_machine_pass" {
    value = azurerm_virtual_machine.webVms[*].os_profile
    sensitive = true
}

output "LB_ip" {
    value = azurerm_lb.lb.frontend_ip_configuration
}


