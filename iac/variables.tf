variable "project" {
  description = "Nome do projeto usado como prefixo nos recursos"
  type        = string
  default     = "secureapi"
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Ambiente deve ser: dev, staging ou prod."
  }
}

variable "location" {
  description = "Região Azure para deploy dos recursos"
  type        = string
  default     = "brazilsouth"
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
  default     = "rg-secureapi-dev"
}

variable "vnet_address_space" {
  description = "CIDR da VNet principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_web_cidr" {
  description = "CIDR da subnet Web (Application Gateway / WAF)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_app_cidr" {
  description = "CIDR da subnet App (API interna)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default = {
    project     = "secureapi"
    environment = "dev"
    managed-by  = "terraform"
    owner       = "platform-team"
  }
}
