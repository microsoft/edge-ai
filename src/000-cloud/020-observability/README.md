# Observability

Component deploying observability related resources needed for an edge deployment.

This includes the following:

- Azure Managed Grafana
- Azure Monitor Workspace
- Azure Log Analytics Workspace
- Application Insights
- Roles and permissions for access to the Grafana dashboard
- Existing Grafana Dashboard for AIO

## Cost Optimization

This component is configured with cost-optimized defaults:

- Application Insights data retention is set to 30 days by default
- Log Analytics daily quota is set to 10 GB by default
- Log Analytics retention is set to 30 days by default

These values can be adjusted based on your monitoring and compliance requirements.

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)
