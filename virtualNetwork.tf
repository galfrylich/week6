resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.webApp.location
  resource_group_name = azurerm_resource_group.webApp.name
}

# the web subnet resources

resource "azurerm_subnet" "webSubnet" {
  name                 = "webSubnet"
  resource_group_name  = azurerm_resource_group.webApp.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "webApp-nsg" {
  name                = "webApp-nsg"
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
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "app"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "DB"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "5432"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "blockOthers"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "webApp-association" {
  subnet_id                 = azurerm_subnet.webSubnet.id
  network_security_group_id = azurerm_network_security_group.webApp-nsg.id
}

# the DB subnet resources

resource "azurerm_subnet" "dbsubnet" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.webApp.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}


resource "azurerm_network_security_group" "DB-nsg" {
  name                = "DB-nsg"
  location            = azurerm_resource_group.webApp.location
  resource_group_name = azurerm_resource_group.webApp.name

  security_rule {
    name                       = "db-internal newtork"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "5432"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "db-loadBalancer"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "5432"
    destination_port_range     = "5432"
    source_address_prefix      = azurerm_public_ip.public_ip.ip_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "DB-association" {
  subnet_id                 = azurerm_subnet.dbsubnet.id
  network_security_group_id = azurerm_network_security_group.DB-nsg.id
}

resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "${var.prefix}-pdz.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.webApp.name

  depends_on = [azurerm_subnet_network_security_group_association.DB-association]
}

resource "azurerm_private_dns_zone_virtual_network_link" "network_link" {
  name                  = "${var.prefix}-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.webApp.name
}

resource "azurerm_postgresql_flexible_server" "flex_server" {
  name                   = "${var.prefix}-serverr"
  resource_group_name    = azurerm_resource_group.webApp.name
  location               = azurerm_resource_group.webApp.location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.dbsubnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dns_zone.id
  administrator_login    = var.userDb
  administrator_password = var.passDb
  #zone                   = "1"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  backup_retention_days  = 7

  depends_on = [azurerm_private_dns_zone_virtual_network_link.network_link]
}


resource "azurerm_postgresql_flexible_server_firewall_rule" "fwconfig" {
  name      = "fw-config"
  server_id = azurerm_postgresql_flexible_server.flex_server.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

#Create Postgres firewall rule
resource "azurerm_postgresql_flexible_server_configuration" "flexible_server_configuration" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.flex_server.id
  value     = "off"
}
