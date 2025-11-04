<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# Akri REST HTTP Connector Module

This module deploys the Azure IoT Operations Akri REST HTTP Connector Template
as part of the IoT Operations deployment. The connector template enables discovery
and management of REST/HTTP endpoints as assets and supports multiple authentication
methods with routing to MQTT broker and state store destinations.

This module is integrated into the IoT Operations component to provide unified
deployment and configuration of both core IoT Operations and REST connectivity.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azapi | ~> 2.7 |

## Providers

| Name | Version |
|------|---------|
| azapi | ~> 2.7 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.connector_template](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aio\_instance\_id | Azure IoT Operations instance ID where the connector template will be deployed. | `string` | n/a | yes |
| custom\_location\_id | Custom location ID for the Azure IoT Operations deployment. | `string` | n/a | yes |
| akri\_rest\_connector\_config | Configuration for the Akri REST HTTP Connector template | ```object({ template_name = optional(string, "rest-http-connector") image_tag = optional(string, "latest") log_level = optional(string, "Info") replicas = optional(number, 1) mqtt_broker_host = optional(string, "aio-mq-dmqtt-frontend:8883") mqtt_broker_audience = optional(string, "aio-mq") mqtt_ca_configmap = optional(string, "aio-ca-trust-bundle-test-only") })``` | `{}` | no |
| environment | The deployment environment (e.g., dev, staging, prod). | `string` | `"dev"` | no |
| location | The Azure region where resources are deployed. | `string` | `"eastus2"` | no |
| resource\_prefix | Prefix for all resource names. | `string` | `"aio"` | no |

## Outputs

| Name | Description |
|------|-------------|
| connector\_template | The deployed REST HTTP connector template. |
| connector\_template\_id | ID of the deployed REST HTTP connector template. |
| connector\_template\_name | Name of the deployed REST HTTP connector template. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
