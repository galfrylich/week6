resource "azurerm_postgresql_flexible_server_database" "flexible_server_database" {
  name      = "postgres-db"
  server_id = azurerm_postgresql_flexible_server.flex_server.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}