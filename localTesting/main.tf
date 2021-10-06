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

  sql_server_name              = "test-sql-mod"
  resource_group_name          = azurerm_resource_group.rg_test.name
  location                     = azurerm_resource_group.rg_test.location
  administrator_login_password = random_password.sql_pass.result

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
/*
locals {
  string = {for d in local.dbs : d => "Server=tcp:${local.server_fqdn},1433;Initial Catalog=${d};Persist Security Info=False;User ID=sql_sa;Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  server_fqdn        = module.sql_local_test.sql_server_fqdn
  dbs = module.sql_local_test.db_names
  #connection_strings = zipmap(local.dbs, "Server=tcp:${local.server_fqdn},1433;Initial Catalog=${local.dbs};Persist Security Info=False;User ID=sql_sa;Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;")
}
*/

output "db_connection_strings" {
  value = module.sql_local_test.db_connection_strings
}

