# Device setup

Component for CNCF cluster setup through scripting for AIO by installing a K3s cluster, onboarding to Azure
Arc, configuring AIO pre-requisites and other optional features. This script is to be executed on the device that will
be used as the cluster.

This script has been tested on the following operating systems:

- Azure Virtual Machine with Ubuntu 20.04 LTS

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Troubleshooting

### Virtual Machine extension

Check the VM extension logs for errors, ensure you SSH into the machine:

```sh
sudo su
cat /var/lib/waagent/Microsoft.Azure.Extensions.CustomScript-2.1.10/status/0.status
```

Check the VM extension `stdout` and `stderr` logs:

```sh
sudo cat /var/lib/waagent/custom-script/download/0/stdout
sudo cat /var/lib/waagent/custom-script/download/0/stderr
```

## Script prerequisites

- Service Principal or Managed Identify connected to the VM with the following permissions:
  - `Kubernetes Cluster - Azure Arc Onboarding`

## Script overview

The script performs the following steps:

- Install K3s, Azure CLI, kubectl
- Login to Azure CLI (Service Principal or Managed Identity)
- Connect to Azure Arc and enable features: `custom-locations`, `oidc-issuer`, `workload-identity`, `cluster-connect` and optionally `auto-upgrade`
- Optionally add the provided Azure AD user as a cluster admin to enable `kubectl` access via `connectedk8s proxy`
- Configure OIDC issuer url for Azure Arc within K3s
- Increase limits for Azure container storage within the host machine
- In non production environments will install k9s and configure `.bashrc` with auto complete and aliases for development

## Script

Login to Azure CLI using the below command:

```sh
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

Set the following environment variables:

```sh
## Required environment variables

# The username of user that will be used on the host machine
ENV_HOST_USERNAME=<device_username>
# The resource group where the Azure Arc resource will be created
ENV_ARC_RESOURCE_GROUP=<arc_resource_group>
# The name of the Azure Arc resource
ENV_ARC_RESOURCE_NAME=<arc_resource_name>

# The Azure AD object ID of the custom locations resource for the Azure Arc resource
ENV_CUSTOM_LOCATIONS_OID=<custom_locations_oid>

# Optional environment variables

# When environment is set to not 'prod', the script install development tools on the cluster, such as  K9s, etc.
ENV_ENVIRONMENT=<environment>

# If set to 'true', add the 'aad_user_id' as a cluster admin to enable the user to access the cluster with cluster connect
ENV_ADD_USER_AS_CLUSTER_ADMIN=<add_user_as_cluster_admin>
# The Azure AD user ID that will be added as a cluster admin
ENV_AAD_USER_ID=<aad_user_id>

# If set to 'true', enable auto-upgrade for the Azure Arc resource
ENV_ARC_AUTO_UPGRADE=<arc_auto_upgrade>

# The tenant ID, client ID and client secret of the service principal used to connect the Azure Arc resource to Azure
# If not set, the script will attempt to use the managed identity of the VM
ENV_ARC_SP_CLIENT_ID=<arc_sp_client_id>
ENV_ARC_SP_SECRET=<arc_sp_secret>
ENV_TENANT_ID=<tenant_id>
```

```sh
./device_setup.sh
```
