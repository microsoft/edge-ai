---
title: Device Setup
description: Component for CNCF cluster setup through scripting for AIO by installing a K3s cluster, onboarding to Azure Arc, configuring AIO pre-requisites and other optional features
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: tutorial
keywords:
  - device setup
  - cncf cluster
  - k3s cluster
  - azure arc
  - azure iot operations
  - script deployment
  - key vault
  - terraform
  - bicep
estimated_reading_time: 6
---

## Device setup

Component for CNCF cluster setup through scripting for AIO by installing a K3s cluster, onboarding to Azure
Arc, configuring AIO pre-requisites and other optional features. This script is to be executed on the device that will
be used as the cluster.

This script has been tested on the following operating systems:

- Azure Virtual Machine with Ubuntu 22.04 LTS

## Key Features

### Script Deployment Options

This component now supports two methods for deploying scripts to VMs:

1. **Direct Script Deployment**: The default method where the script content is embedded directly in the VM extension.
2. **Key Vault Script Retrieval**: A more flexible method where scripts are downloaded from Azure Key Vault at runtime using the `deploy-script-secrets.sh` script.

The Key Vault Script Retrieval method offers the following advantages:

- Scripts can be updated in Key Vault without redeploying infrastructure
- Script content is securely stored and retrieved only when needed
- Different scripts can be deployed based on OS type and node type
- Sensitive information in scripts is more secure

To enable Key Vault Script Retrieval, set the variable `should_use_script_from_secrets_for_deploy` to `true` in your Terraform configuration. This is enabled by default.

## Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

## Troubleshooting

### Virtual Machine extension

Refer to [Custom Script Linux - Troubleshooting](https://learn.microsoft.com/azure/virtual-machines/extensions/custom-script-linux#troubleshooting)
for detailed troubleshooting information.

```sh
# Go into super-user for accessing all information without needing `sudo`
sudo su
```

List the custom-script directory for `stdout` and `stderr` files:

```sh
sudo ls -l /var/lib/waagent/custom-script/download/0/
```

Check the VM extension logs for errors, ensure you SSH into the machine:

```sh
# Linux Agent logs, may or may not exist:
sudo cat /var/log/waagent.log

# Azure Script Extension logs:
sudo cat /var/log/azure/custom-script/handler.log

#  Additional status logs:
sudo cat /var/lib/waagent/Microsoft.Azure.Extensions.CustomScript-2.1.10/status/0.status
```

Check the VM extension `stdout` and `stderr` logs:

```sh
sudo cat /var/lib/waagent/custom-script/download/0/stdout
sudo cat /var/lib/waagent/custom-script/download/0/stderr
```

Check the logs for the services if they managed to start:

```sh
# Logs for k3s.service
sudo journalctl -u k3s

# Logs for k3s-agent.service
sudo journalctl -u k3s-agent
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

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
