# terraform-azurerm-sql

Creates a new SQL Server in Azure, along with any number of databases.

## Azure AD SQL Administrator

```js
  azuread_administrator = {
    login_username = "sql_admin_user"
    object_id      = "21b3fa33-foo-object-id"
    tenant_id      = local.tenant_id
  }
```

## Arguments

| Name | Type | Required / Optional | Description |
| -- | -- | -- | -- |
| location  | string | optional | if not set then default of 'uksouth' is set.  |
| resource_group_name | string | required |  |
| sql_config | map | optional | See examples below |
| sql_fw_rules | map | optional | A map (see example below) of SQL firewall rules that define which PUBLIC IP addresses can connect to the SQL Server. |
| pe_name | string | optional | When set, a Private Endpoint connection will be created for the SQL Server.  |
| private_dns_zone_name | string | optional | only used if `pe_name` is set. Defaults to `privatelink.database.windows.net`  |
| private_dns_zone_id | string | optional | Only used if `pe_name` is set. Defaults to the ID of the `privatelink.database.windows.net` DNS zone in the platform subscription. |
| db_name | map | optional | See Section below | 
| tags | map | optional | A set of key:value pairs to tag the new resources. |

## sql_config

The sql_config input parameter can be used to change the default deployment configuration of an Azure SQL Server. Thsi includes settings such as:

- Azure SQL Version (`12.0` by default). Valid options are `2.0` (for v11 server) and `12.0` (for v12 server). This is unlikely to ever need changing.

- SQL Administrator USer Name (`sql_sa` by default). Chaning this on a server already deployed forces a new resource to be created.

- The connection policy to use (`Default` by default). Other options allowed are `Proxy` & `Redirect`. 

- Is Public Network Access enabled (`false` by default).

## db_name

The `db_name` input parameter is an optional inpout that defines the SQL Databases that shoudl ber created. Each separate `db_name` block that is added, will create a SQL Database with the settings defined.

EXAMPLE:

```js
db_name = {
    db_default_config = {
    },
    db_custom_config = {
      sku_name       = "Basic"
      zone_redundant = false
      max_size_gb    = "1"
    }
  }

```

The structure is of a map, with the name of the database being the `key` and then the specific Database configuration settings defined within then block. If no configuration settings are added, then the Database will be deployed with the default settings.

Possible configuration options are:

- `create_mode` (defaults to `Default`). Possible values are `Copy`, `OnlineSecondary`, `PointInTimeRestore`, `Recovery`, `Restore`, `RestoreExternalBackup`, `RestoreExternalBackupSecondary`, `RestoreLongTermRetentionBackup` and `Secondary`.

- `creation_source_database_id` (defaults to `""`). This is for the ID of the source Database to be referred to create the new DB. Only to be used when the `create_mode` option requires another database as a reference (such as `Copy` or `Secondary`).

- `max_size_gb` Defaults to 32GB. Should not be configured when the `create_mode` is `Secondary` or `OnlineSecondary`, as the sizing of the primary is then used as per Azure documentation. ```**** ENHANCEMENT REQUIRED TO IGNORE THIS SETTING IF `create_mode` is `Secondary` or `OnlineSecondary` *******```

- `sku_name` Defaults to `GP_S_Gen5_2`. Supported values include : `GP_S_Gen5_2`, `HS_Gen4_1`, `BC_Gen5_2`, `ElasticPool`, `Basic`, `S0`, `P2` , `DW100c`, `DS100` and `Hyperscale`. Changing FROM `Hyperscale` to another tier will force a new resource to be created. To see all availabke SKU's in a region, run the following Azure Powershell command `Get-AzSqlServerServiceObjective -Location "uksouth"`.

- `storage_account_type` Defaults to `GRS`. Determines the storage account type used to store Database Backups.

- `weekly_retention` Defaults to `P4W` (4 weeks) . Valid value is between 1 to 520 weeks. e.g. `P1Y, P1M, P1W or P7D`.

- `monthly_retention` Defaults to `P3M` (3 months). Valid value is between 1 to 120 months. e.g. `P1Y, P1M, P4W or P30D`.

- `yearly_retention` Defaults to `P1Y` (1 year). Valid value is between 1 to 10 years. e.g. `P1Y, P12M, P52W or P365D`.

- `week_of_year` Defaults to `4`. The week of year to take the yearly backup in an ISO 8601 format. Value has to be between `1 and 52`.

- `zone_redundant` Defaults to `false`. Means the replicas of this database will be spread across multiple availability zones. This property is only settable for `Premium and Business Critical` databases.

### FUTURE ENHANCEMENTS to `db_name`

- `read_replica_count` NOT YET IMPLEMENTED. FUTURE ENHANCEMENT.
- `read_scale` NOT YET IMPLEMENTED. FUTURE ENHANCEMENT.
- `threat_detection_policy` NOT YET IMPLEMENTED. FUTURE ENHANCEMENT
