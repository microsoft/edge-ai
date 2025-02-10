# New Environment Onboard Requirements

Component for onboarding a new environment and includes IaC for creating resources that are needed for an
edge deployment.

This includes the following:

- Azure Resource Group
- User Assigned Managed Identity for a VM Host
- Service Principal for automated cluster setup and Azure Arc connection

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)
