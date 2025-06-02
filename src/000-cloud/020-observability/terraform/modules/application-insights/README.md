# Application Insights Module

This Terraform module creates an Azure Application Insights instance designed for monitoring applications, specifically optimized for Azure Functions integration.

## Features

- **Application Monitoring**: Comprehensive telemetry collection and performance tracking
- **Azure Functions Integration**: Optimized configuration for Function App monitoring
- **Log Analytics Integration**: Connected to Log Analytics Workspace for centralized logging
- **Configurable Settings**: Flexible retention, sampling, and security configurations
- **Connection String Output**: Provides connection details for application integration

## Usage

```terraform
module "application_insights" {
  source = "./modules/application-insights"

  # Required parameters
  resource_prefix              = "myapp"
  environment                  = "dev"
  instance_suffix              = "fn"
  location                     = "East US"
  resource_group_name          = "rg-myapp-dev-001"
  log_analytics_workspace_id   = "/subscriptions/.../workspaces/log-myapp-dev-001"

  # Application configuration
  application_type                              = "web"
  retention_in_days                            = 30
  daily_data_cap_in_gb                         = 1
  sampling_percentage                          = 100
  should_disable_daily_data_cap_notifications  = false
  should_disable_ip_masking                    = false
  should_disable_local_authentication          = false
  should_enable_internet_ingestion             = true
  should_enable_internet_query                 = true
  should_force_customer_storage_for_profiler   = false

  tags = {
    Environment = "dev"
    Purpose     = "monitoring"
  }
}
```

## Integration with Azure Functions

To connect this Application Insights instance to Azure Functions, use the connection string output:

```terraform
module "azure_functions" {
  source = "../messaging/modules/azure-functions"

  # ... other parameters ...

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.application_insights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    # ... other app settings ...
  }
}
```

## Outputs

- `application_insights`: Complete Application Insights resource object including:
  - `id`: Resource ID
  - `name`: Resource name
  - `instrumentation_key`: Legacy instrumentation key
  - `connection_string`: Modern connection string for application integration
  - `app_id`: Application ID for API access
  - Additional metadata fields

## Requirements

- Azure subscription with Application Insights service available
- Existing Log Analytics Workspace
- Terraform >= 1.9.8
- AzureRM provider >= 4.8.0

## Application Types

Supported application types:

- `web`: Web applications and services (default for Azure Functions)
- `java`: Java applications
- `MobileCenter`: Mobile applications
- `other`: General applications

## Security Considerations

- Connection string contains sensitive authentication information
- IP masking can be disabled for development environments but should be enabled in production
- Internet ingestion and query access should be configured based on security requirements
- Local authentication can be disabled to enforce Azure AD authentication
