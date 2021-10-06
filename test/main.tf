data "azurerm_subscription" "current" {
}

locals {
  tenant_id = data.azurerm_subscription.current.tenant_id
}


resource "azurerm_resource_group" "rg_test" {
  name     = "rg-sql-mod-test"
  location = "uksouth"
}

# Create server PW
resource "random_password" "sql_pass" {
  length           = 20
  special          = true
  override_special = "_%@"
}


module "sql_local_test" {
  source = "../"

  azuread_administrator = {
    login_username = "sql_admin_user"
    object_id      = "azuread-user-object-ID"
    tenant_id      = local.tenant_id
  }

  sql_server_name              = "test-sql-aad"
  resource_group_name          = azurerm_resource_group.rg_test.name
  location                     = azurerm_resource_group.rg_test.location
  administrator_login_password = random_password.sql_pass.result
  sql_config = {
    public_network_access_enabled = true
  }

  db_name = {
    db_default_config = {
    },
    db_custom_config = {
      sku_name       = "Basic"
      zone_redundant = false
      max_size_gb    = "1"
    }
  }
}

