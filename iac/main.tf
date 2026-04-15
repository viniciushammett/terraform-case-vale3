terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}
  # Autenticação via: az login ou variáveis de ambiente ARM
  # subscription_id é lido automaticamente de: az account show
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Virtual Network
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_address_space]

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

# Subnet Web: recebe o Application Gateway (WAF) - camada de borda
resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_web_cidr]

  # Application Gateway requer subnet dedicada (sem service endpoints adicionais)
}

# Subnet App: recebe a API interna - camada privada, nunca exposta diretamente
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_app_cidr]

  service_endpoints = ["Microsoft.Storage"] # Permite acesso privado ao Storage
}

# ---------------------------------------------------------------------------
# Network Security Group
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.project}-app-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # ------------------------------------------------------------------
  # REGRA 1 - Allow HTTPS saída da snet-app para o Storage Account
  # Justificativa: A API precisa acessar o Storage via Managed Identity.
  #                Limitado a porta 443 (HTTPS) e ao destino Storage.
  # ------------------------------------------------------------------
  security_rule {
    name                       = "Allow-HTTPS-Outbound-Storage"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_app_cidr
    destination_address_prefix = "Storage" # Service Tag Azure
  }

  # ------------------------------------------------------------------
  # REGRA 2 — Deny all inbound de qualquer origem para a snet-app
  # Justificativa: A API nunca deve ser acessada diretamente da internet
  #                ou de outra subnet não autorizada. Todo tráfego deve
  #                passar obrigatoriamente pelo Application Gateway (WAF).
  #                Esta regra garante que mesmo que o WAF seja bypassado,
  #                a snet-app não responde a conexões diretas.
  # Prioridade 4096 = mais baixa possível (regra de catch-all).
  # ------------------------------------------------------------------
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "0.0.0.0/0"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# NSG Association - aplica o NSG a snet-app
# ---------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
