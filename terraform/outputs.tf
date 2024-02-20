output "postgresql_password" {
  value     = azurerm_postgresql_flexible_server.lab.administrator_password
  sensitive = true
}

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.lab.fqdn
}

output "app_uri" {
  value = "http://${azurerm_public_ip.lab.ip_address}"
}
