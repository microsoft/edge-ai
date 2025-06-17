# ARC Enabled K8s Cluster on Rancher with AIO

## Requirements
- Project on the BMW Edge Platform
- Azure Subscription
- Azure Service Principal with the following Roles/Permissions
    - Contributor (through BMW https://manage.azure.bmw.cloud portal)
    - Microsoft.Authorization/roleAssignments/write on subscription level (e.g. `az role assignment create --assignee <service principal object_id> --role "Role Based Access Control Administrator" --scope <subscription id>`). To assign this permission, temporary role `FPC Owner` needs to be requested through the BMW Azure portal https://manage.azure.bmw.cloud.

## Configuration
Set the following environment variables:
| Name          | Description | Default     |
| -----         | -----       | ----------- |
| ARM_TENANT_ID | The Azure Tenant | ce849bab-cc1c-465b-b62e-18f07c9ac198 |
| ARM_CLIENT_ID | The SP Client ID (see requirements above) | |
| ARM_CLIENT_SECRET | Password for the SP | |
| TF_VAR_rancher_url | Url for BMW Rancher | https://edge.bmwgroup.net |
| TF_VAR_rancher_access_key | Rancher API access key | |
| TF_VAR_rancher_secret_key | Rancher API secret key | |
| TF_VAR_http_proxy | HTTP Proxy used by Azure ARC to access cloud services | |

For local development, create a `.env` file using the following example and source it with `source .env`:
```sh
export ARM_TENANT_ID=ce849bab-cc1c-465b-b62e-18f07c9ac198
export ARM_CLIENT_ID=<fillme>
export ARM_CLIENT_SECRET=<fillme>
export TF_VAR_rancher_url=https://edge.bmwgroup.net
export TF_VAR_rancher_access_key=<fillme>
export TF_VAR_rancher_secret_key=<fillme>
export TF_VAR_http_proxy=<fillme>
```

## Notes
- For smaller sized clusters pass the configuration variable `disable_broker_cpu_limits = true` to this module to disable the resource configuration for the MQTT Broker (see https://learn.microsoft.com/en-us/azure/iot-operations/manage-mqtt-broker/howto-configure-availability-scale?tabs=portal#cardinality-and-kubernetes-resource-limits). 