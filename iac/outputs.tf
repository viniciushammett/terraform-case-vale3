output "vnet_id" {
  description = "ID da VNet criada"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nome da VNet criada"
  value       = azurerm_virtual_network.main.name
}

output "subnet_web_id" {
  description = "ID da subnet Web (Application Gateway)"
  value       = azurerm_subnet.web.id
}

output "subnet_app_id" {
  description = "ID da subnet App (API interna)"
  value       = azurerm_subnet.app.id
}

output "nsg_app_id" {
  description = "ID do NSG aplicado à subnet App"
  value       = azurerm_network_security_group.app.id
}

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Região Azure onde os recursos foram criados"
  value       = azurerm_resource_group.main.location
}
