/**
 * # Application Insights
 *
 * Creates an Azure Application Insights instance for monitoring applications,
 * specifically designed to integrate with Azure Functions and other application services.
 * This module provides comprehensive monitoring capabilities including telemetry collection,
 * performance tracking, and diagnostic insights.
 */

resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${var.resource_prefix}-${var.environment}-${var.instance_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = var.application_type

  retention_in_days = var.retention_in_days

  tags = var.tags
}
