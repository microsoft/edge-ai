<!-- BEGIN_TF_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
# MQTT Configuration Module

This module creates MQTT broker listeners, endpoints, and dataflows using the azapi provider.
It handles the deployment of MQTT configuration resources for both enterprise and site clusters.
Uses existing AIO instance and dataflow profile outputs from the IoT Operations module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.8, < 2.0 |
| azapi | >= 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| azapi | >= 2.3.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource.enterprise_mqtt_broker_authentication](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.enterprise_mqtt_broker_listener](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.enterprise_mqtt_endpoint_cert_auth](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.site_enterprise_route_cert_auth](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.site_mqtt_endpoint](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |
| [azapi_resource.enterprise_aio_broker](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enterprise\_aio\_instance | Enterprise Azure IoT Operations instance object from the IoT Operations module | `any` | n/a | yes |
| enterprise\_broker\_port | The port number for the enterprise MQTT broker listener | `number` | n/a | yes |
| enterprise\_broker\_server\_cert\_secret\_name | The name of the Kubernetes secret containing the broker server certificate | `string` | n/a | yes |
| enterprise\_client\_ca\_configmap\_name | The name of the Kubernetes configmap containing the client CA certificate | `string` | n/a | yes |
| enterprise\_custom\_locations | Custom locations object for the enterprise cluster | ```object({ id = string name = string })``` | n/a | yes |
| enterprise\_vm\_private\_ip | The private IP address of the enterprise VM (cluster A). | `string` | n/a | yes |
| site\_aio\_dataflow\_profile | Site Azure IoT Operations dataflow profile object from the IoT Operations module | `any` | n/a | yes |
| site\_aio\_instance | Site Azure IoT Operations instance object from the IoT Operations module | `any` | n/a | yes |
| site\_client\_secret\_name | The name of the Kubernetes secret containing the client certificate and key | `string` | n/a | yes |
| site\_custom\_locations | Custom locations object for the site cluster | ```object({ id = string name = string })``` | n/a | yes |
| site\_tls\_ca\_configmap\_name | The name of the Kubernetes configmap containing the TLS CA certificate | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| enterprise\_mqtt\_broker\_authentication | The enterprise MQTT broker authentication resource. |
| enterprise\_mqtt\_broker\_listener | The enterprise MQTT broker listener resource. |
| enterprise\_mqtt\_endpoint\_cert\_auth | The enterprise MQTT endpoint with certificate authentication. |
| site\_enterprise\_route\_cert\_auth | The enterprise site route with certificate authentication dataflow. |
| site\_mqtt\_endpoint | The site MQTT endpoint resource. |
<!-- markdown-table-prettify-ignore-end -->
<!-- END_TF_DOCS -->
