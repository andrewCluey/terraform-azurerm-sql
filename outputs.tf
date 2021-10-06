output "db_ids" {
  description = "The IDs of all created Databases"
  value = {
    for k, v in azurerm_mssql_database.sql_db : k => v.id
  }
}

output "sqldb_name_id" {
  description = "A map output showing SQL Server DB names and IDs"
  value       = zipmap(values(azurerm_mssql_database.sql_db)[*].name, values(azurerm_mssql_database.sql_db)[*].id)
}

output "db_names" {
  description = "The names of all DBs created"
  value       = values(azurerm_mssql_database.sql_db)[*].name
}


output "sql_server_name" {
  description = "The confirmed name of the SQL server"
  value       = azurerm_mssql_server.sql_svr.name
}

output "sql_server_id" {
  description = "The confirmed ID of the SQL server"
  value       = azurerm_mssql_server.sql_svr.id
}

output "sql_server_fqdn" {
  description = "The FQDN of the SQL server"
  value       = azurerm_mssql_server.sql_svr.fully_qualified_domain_name
}

output "db_connection_strings" {
  value = local.string
}

