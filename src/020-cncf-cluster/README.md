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

Find required environment variables that must be set:

```sh
./k3s-device-setup.sh -h
```

Set environment variables and call the script.

```sh
# Replace or add environment variables below with parameters for your need.
ENVIRONMENT=dev \
  ARC_RESOURCE_GROUP_NAME=rg-sample-dev-001 \
  ARC_RESOURCE_NAME=arck-sample-dev-001 \
  ./k3s-device-setup.sh
```
