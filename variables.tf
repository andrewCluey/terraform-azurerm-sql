variable "sql_server_name" {
  type        = string
  description = "The name of the Microsoft SQL Server. This needs to be globally unique within Azure."
  # validation required - name" did not match regex "^[0-9a-z]([-0-9a-z]{0,61}[0-9a-z])?$"
}


variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the Microsoft SQL Server."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  default     = "uksouth"
}


variable "sql_config" {
  type        = any
  default     = {}
  description = <<EOF
  OPTIONAL: An input map to define key SQL Server configuration settings.
  EXAMPLE

    sql_config = {
        version             = "12.0"
        connection_policy   = "Default"   # The connection policy the server will use. Possible values are Default, Proxy, and Redirect.
        administrator_login = "sql_sa"    # The administrator login name for the new server. Changing this forces a new resource to be created.
    }
EOF
}

variable "administrator_login_password" {
  type        = string
  description = "The password associated with the administrator_login user. Needs to comply with Azure's Password Policy"
  sensitive   = true
}

variable "azuread_administrator" {
  type        = any
  description = <<EOF
  Input object to define an Azure AD user account to be the administrator fo the new SQL Server.
  Requires inputs for `login_username`, `object_id` & `tenant_id`.
  EXAMPLE:
  azuread_administrator = {
    login_username = "sql_admin_user"
    object_id      = "903235-foo-object-id"
    tenant_id      = "755kblahblahblah40923040"
  }
EOF
}

variable "sql_fw_rules" {
  type        = any
  default     = {}
  description = <<EOF
  A map of maps input parameter containinng the name of the new SQL Ffirewall rule, the start IP address and the end IP address.
  EXAMPLE:

  sql_fw_rules = {
      ascHomeAccess = {
          start_ip_address = "5.2.3.4"
          end_ip_address   = "5.2.3.4"
      },
      RemoteSiteAccess = {
          start_ip_address = "20.2.3.1"
          end_ip_address   = "5.2.3.5"
      }
  }
EOF
}

variable "pe_name" {
  type        = string
  description = "OPTIONAL: The name to assign to the new Private Endpoint (if required)."
  default     = ""
}

variable "pe_subnet_id" {
  type        = string
  description = "OPTIONAL: The id of the Subnet where the new Private Endpoint NIC should be created."
  default     = ""
}

variable "private_dns_zone_name" {
  type        = string
  description = "The Private DNS zone name for a SQL Database Private Endpoint."
  default     = ""
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "The Private DNS zone ID for SQL Database Private Link. Defaults to DNS zone deployed in Platform Subscription."
  default     = ""
}


variable "db_name" {
  type        = any
  default     = {}
  description = <<EOF
  An map object where each SQL Database that is needed can be defined. 
  Each DB name that is defined will create a new SQL Database. As defaults settings have been defined in the resource code, it is not necessary fior additional parameteres to be added.

  However, should you wish to change the default DB configuration, then this can be achieved. Simply add the relevant configuration item into the map object for the db you are creating.

  Configurable items include:
    * sku_name                          : "Specifies the SKU used by the DB. Options include 'Basic'; 'ElasticPool'; 'Hyperscale'; 'HS_Gen4_1' & 'GP_S_Gen5_2' (default)."
    * requested_service_objective_name  : 
    * zone_redundant                    :
    * max_size_bytes                    :
    * collation                         :
    * requested_service_objective_id    :

  EXAMPLE:
  db_name = {
    db_default_config = {
    },
    db_custom_config = {
      sku_name                         = "Basic"
      zone_redundant                   = false
      max_size_gb                      = "2"
    }
  }

EOF
}


variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID fo the Log Analytics Workspace where SQL logs should be sent."
}


variable "tags" {
  type        = map(any)
  description = "A map of custom tags to apply to the new SQL Server"
  default     = {}
}


variable "enable_vulnerability_scans" {
  type        = bool
  description = "Should vulnerability scans be enabled for the new SQL Server"
  default     = false
}

variable "admin_email_addresses" {
  type        = list(string)
  description = "Required only when `enable_vulnerability_scans` is set to `true`. A list of email addresses to send email alerts to for vulnerability scan alerts."
  default     = []
}

variable "disabled_alerts" {
  type        = list(string)
  description = <<EOF
  A list of alerts that are disabled. Allowed values are:
  `sql_Injection`
  `sql_Injection_Vulnerability`
  `Access_Anomaly`
  `Data_Exfiltration`
  `Unsafe_Action`
  Default setting is for no alerts to be disabled.
EOF
  default = []
}

variable "sql_alert_retention" {
  type        = string
  description = "The number of days to keep the Threat Detection audit logs. Defaults to 30."
  default     = "30"
}


variable "enable_extended_auditing" {
  type        = bool
  description = "If set to `True`, then extended auditing will be enabled. Defaults to True."
  default     = true
}
