########################################################################################################################
# Create the SQL Server
########################################################################################################################
resource "azurerm_mssql_server" "sql_svr" {
  name                          = var.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = lookup(var.sql_config, "version", "12.0")
  administrator_login           = lookup(var.sql_config, "administrator_login", "sql_sa")
  administrator_login_password  = var.administrator_login_password
  connection_policy             = lookup(var.sql_config, "connection_policy", "Default")
  minimum_tls_version           = "1.2"
  public_network_access_enabled = lookup(var.sql_config, "public_network_access_enabled", "false")
  tags                          = var.tags

  azuread_administrator {
    login_username = var.azuread_administrator.login_username
    object_id      = var.azuread_administrator.object_id
    tenant_id      = var.azuread_administrator.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }
}


######################################################
# Auditing and security vulnerability assesments
######################################################
locals {
  vulnerability_scan_sa_name = replace(var.sql_server_name, "-", "")
}

# Vulnerability scans storage account
resource "azurerm_storage_account" "sa_sql_vulnerability_scans" {
  count                    = var.enable_vulnerability_scans == true ? 1 : 0
  name                     = "${local.vulnerability_scan_sa_name}scans"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = var.tags
}
# Vulnerability scans storage container
resource "azurerm_storage_container" "blob_sql_vulnerability_scans" {
  count                 = var.enable_vulnerability_scans == true ? 1 : 0
  name                  = "${local.vulnerability_scan_sa_name}-scan"
  storage_account_name  = azurerm_storage_account.sa_sql_vulnerability_scans[0].name
  container_access_type = "private"
}
# Enable Vulnerability scan
resource "azurerm_mssql_server_vulnerability_assessment" "sql_vulnerability" {
  count                           = var.enable_vulnerability_scans == true ? 1 : 0
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.sql_alert_policy[0].id
  storage_container_path          = "${azurerm_storage_account.sa_sql_vulnerability_scans[0].primary_blob_endpoint}${azurerm_storage_container.blob_sql_vulnerability_scans[0].name}/"
  storage_account_access_key      = azurerm_storage_account.sa_sql_vulnerability_scans[0].primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
    emails                    = var.admin_email_addresses
  }
}
# SQL Alert Policy
resource "azurerm_mssql_server_security_alert_policy" "sql_alert_policy" {
  count               = var.enable_vulnerability_scans == true ? 1 : 0
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.sql_svr.name
  state               = "Enabled"

  storage_endpoint           = azurerm_storage_account.sa_sql_vulnerability_scans[0].primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.sa_sql_vulnerability_scans[0].primary_access_key
  disabled_alerts            = var.disabled_alerts
  retention_days             = var.sql_alert_retention
}

# extended_auditing_policy - (Optional) An extended_auditing_policy block as defined below.
resource "azurerm_mssql_server_extended_auditing_policy" "sql_svr_audit" {
  count                  = var.enable_extended_auditing == true ? 1 : 0
  server_id              = azurerm_mssql_server.sql_svr.id
  log_monitoring_enabled = true
}


/*
########################################################################################################################
# Create Azure AD Admin User (Optional)
########################################################################################################################

resource "azurerm_sql_active_directory_administrator" "sql_aad_admin_user" {
  count               = var.azuread_administrator == "" ? 0 : 1
  server_name         = azurerm_mssql_server.sql_svr.name
  resource_group_name = var.resource_group_name
  login               = var.azuread_administrator.login_username
  tenant_id           = var.azuread_administrator.tenant_id
  object_id           = var.azuread_administrator.object_id
}
*/


########################################################################################################################
# Create the Private Endpoint (OPTIONAL)
########################################################################################################################
resource "azurerm_private_endpoint" "pe" {
  count               = var.pe_name == "" ? 0 : 1
  name                = var.pe_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "${var.sql_server_name}-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.sql_svr.id
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = var.private_dns_zone_name
    private_dns_zone_ids = var.private_dns_zone_ids
  }
}



########################################################################################################################
# Create Azure SQL firewall Rules 
########################################################################################################################
resource "azurerm_mssql_firewall_rule" "sql_fw_rules" {
  for_each = var.sql_fw_rules

  server_id           = azurerm_mssql_server.sql_svr.id
  name                = each.key
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address
}


########################################################################################################################
# Create the SQL Databases (using for_each loop)
########################################################################################################################
resource "azurerm_mssql_database" "sql_db" {
  for_each = var.db_name

  name                        = each.key
  tags                        = var.tags
  server_id                   = azurerm_mssql_server.sql_svr.id
  create_mode                 = lookup(each.value, "create_mode", "Default")
  #creation_source_database_id = lookup(each.value, "creation_source_database_id", "") # FUTURE ENHANCEMENT - Requires logic to ignore if not being used.
  sku_name                    = lookup(each.value, "sku_name", "GP_S_Gen5_2")
  auto_pause_delay_in_minutes = lookup(each.value, "auto_pause_delay_in_minutes", "-1")
  zone_redundant              = lookup(each.value, "zone_redundant", true)
  min_capacity                = lookup(each.value, "min_capacity", "1")
  max_size_gb                 = lookup(each.value, "max_size_gb", "32") # enhancement required to ignore if create_mode is `secondary`
  collation                   = lookup(each.value, "collation", "SQL_Latin1_General_CP1_CI_AS")
  storage_account_type        = lookup(each.value, "storage_account_type", "GRS")

  short_term_retention_policy {
    retention_days = lookup(each.value, "pitr_retention_days", "7")
  }
  
  long_term_retention_policy {
    weekly_retention  = lookup(each.value, "weekly_retention", "P4W")
    monthly_retention = lookup(each.value, "monthly_retention", "P3M")
    yearly_retention  = lookup(each.value, "yearly_retention", "P1Y")
    week_of_year      = lookup(each.value, "week_of_year", "4")
  }

}

locals {
  string = {for d in local.dbs : d => "Server=tcp:${local.server_fqdn},1433;Initial Catalog=${d};Persist Security Info=False;User ID={****SQL_USER****};Password={**your_password***};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }

  server_fqdn = azurerm_mssql_server.sql_svr.fully_qualified_domain_name
  dbs         = values(azurerm_mssql_database.sql_db)[*].name
  #connection_strings = zipmap(local.dbs, "Server=tcp:${local.server_fqdn},1433;Initial Catalog=${local.dbs};Persist Security Info=False;User ID=sql_sa;Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;")
}

resource "azurerm_mssql_database_extended_auditing_policy" "sql_db_auditing" {
  for_each = azurerm_mssql_database.sql_db
  database_id            = each.value.id
  log_monitoring_enabled = true
  retention_in_days      = "7"
}



####################################### Diagnostic Settings ############################################################
# 
########################################################################################################################
resource "azurerm_monitor_diagnostic_setting" "sql_db_diagnostics" {
  for_each = azurerm_mssql_database.sql_db

  name                       = "${each.value.name}-DS"
  target_resource_id         = each.value.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "SQLSecurityAuditEvents"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}


