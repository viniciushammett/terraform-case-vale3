# IaC - Terraform

Cria a infraestrutura base: **VNet + 2 subnets + NSG com 2 regras**.

---

## Pré-requisitos

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| Terraform | 1.5.0 | https://developer.hashicorp.com/terraform/downloads |
| Azure CLI | 2.50.0 | https://docs.microsoft.com/cli/azure/install-azure-cli |

---

## Autenticação Azure

```bash
# Login interativo (desenvolvimento local)
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# Verificar conta ativa
az account show
```

Para CI/CD, use Service Principal via variáveis de ambiente:
```bash
export ARM_CLIENT_ID="<APP_ID>"
export ARM_CLIENT_SECRET="<SECRET>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export ARM_TENANT_ID="<TENANT_ID>"
```

---

## Validação Local (sem provisionar nada)

```bash
cd iac/

# Inicializa providers (necessário mesmo para validate)
terraform init

# Valida sintaxe e configuração - não acessa a Azure
terraform validate

# Saída esperada:
# Success! The configuration is valid.
```

---

## Plan - Visualizar o que será criado

```bash
# Exibe todos os recursos que seriam criados
terraform plan

# Salva o plano em arquivo (recomendado para apply deterministico)
terraform plan -out=tfplan
```

O `plan` mostra exatamente:
- Quais recursos serão criados/modificados/destruídos
- Valores de todas as propriedades
- Estimativa de custo (se Terraform Cloud estiver configurado)

---

## Apply - Criar os recursos

```bash
# Aplica o plano salvo (recomendado)
terraform apply tfplan

# Ou apply interativo (pede confirmação antes de criar)
terraform apply
```

Recursos criados:
1. `azurerm_resource_group` — Resource Group
2. `azurerm_virtual_network` — VNet `10.0.0.0/16`
3. `azurerm_subnet` (web) — `snet-web` `10.0.1.0/24`
4. `azurerm_subnet` (app) — `snet-app` `10.0.2.0/24`
5. `azurerm_network_security_group` — NSG com 2 regras
6. `azurerm_subnet_network_security_group_association` — NSG → snet-app

---

## Customização via variáveis

```bash
# Sobrescrever variáveis na linha de comando
terraform plan \
  -var="environment=prod" \
  -var="location=eastus2" \
  -var="resource_group_name=rg-secureapi-prod"

# Ou criar arquivo terraform.tfvars
cat > terraform.tfvars << EOF
project             = "myapi"
environment         = "prod"
location            = "eastus2"
resource_group_name = "rg-myapi-prod"
vnet_address_space  = "172.16.0.0/16"
subnet_web_cidr     = "172.16.1.0/24"
subnet_app_cidr     = "172.16.2.0/24"
EOF

terraform plan
```

---

## Destroy - Remover todos os recursos

```bash
# Remove tudo que foi criado por este Terraform
terraform destroy
```

---

## Estrutura dos arquivos

| Arquivo | Conteúdo |
|---|---|
| `main.tf` | Recursos principais (VNet, subnets, NSG) |
| `variables.tf` | Definição e defaults de todas as variáveis |
| `outputs.tf` | Valores exportados após o apply |

---

> **Nota:** Este IaC é o mínimo necessário conforme os requisitos do case.
