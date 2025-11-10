---
title: CNCF Cluster Script Output Blueprint
description: Infrastructure as Code configurations for generating K3s Kubernetes cluster installation scripts with Azure Arc connectivity without actual deployment
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - cncf cluster
  - k3s kubernetes
  - azure arc
  - script generation
  - terraform
  - bicep
  - cluster setup
  - installation scripts
  - edge computing
estimated_reading_time: 2
---

## CNCF Cluster Script Output Blueprint

This blueprint provides Infrastructure as Code (IaC) configurations for generating installation scripts that set up and configure K3s Kubernetes clusters with Azure Arc connectivity. Unlike the full deployment blueprints, this option focuses on script generation without actually deploying the cluster resources. The generated scripts can then be manually executed in your target environment.

There are two implementation options:

- **Terraform**: Generates scripts that can be output to a local directory
- **Bicep**: Generates scripts and stores them as secrets in an Azure Key Vault

Both implementations create two types of scripts:

1. **Server Script**: For setting up the primary K3s server node and Arc enablement
2. **Node Script**: For joining additional worker nodes to the cluster (for multi-node deployments)

## Terraform Structure

- Uses the reusable component from `/src/100-edge/100-cncf-cluster/terraform`
- Outputs the generated scripts to the specified output path
- Can optionally create an Azure managed identity for cluster Arc enablement

### Terraform Key Input Variables

| Variable                              | Description                                  | Default                           | Required |
|---------------------------------------|----------------------------------------------|-----------------------------------|:--------:|
| `resource_prefix`                     | Prefix for all resources                     | n/a                               |   yes    |
| `environment`                         | Environment (dev, test, prod)                | n/a                               |   yes    |
| `instance`                            | Instance identifier                          | `"001"`                           |    no    |
| `custom_locations_oid`                | Custom Locations Service Principal Object ID | `null` (will attempt to retrieve) |    no    |
| `arc_onboarding_sp`                   | Service Principal for Arc onboarding         | `null`                            |    no    |
| `cluster_admin_id`                    | ID for cluster-admin permissions             | `null` (current user if enabled)  |    no    |
| `should_output_cluster_server_script` | Whether to output the server script          | `true`                            |    no    |
| `should_output_cluster_node_script`   | Whether to output the node script            | `false`                           |    no    |
| `script_output_filepath`              | Path to output script files                  | `"./out"`                         |    no    |
| `should_upload_to_key_vault`          | Upload scripts to Key Vault as secrets       | `false`                           |    no    |
| `key_vault_name`                      | Name of the Key Vault                        | `"kv-{prefix}-{env}-{instance}"`  |    no    |

## Bicep Structure

- Deploys a user-assigned managed identity for Arc onboarding (if enabled)
- Creates role assignments (if enabled)
- Generates scripts and stores them as secrets in an Azure Key Vault
- Provides outputs for accessing the generated scripts

### Bicep Key Parameters

| Parameter                          | Description                                      | Default                        | Required |
|------------------------------------|--------------------------------------------------|--------------------------------|:--------:|
| `common`                           | Common settings (resourcePrefix, location, etc.) | n/a                            |   yes    |
| `customLocationsOid`               | Custom Locations Service Principal Object ID     | n/a                            |   yes    |
| `keyVaultName`                     | Name of the Key Vault for script storage         | Generated from resource prefix |    no    |
| `arcOnboardingSpClientId`          | Service Principal Client ID for Arc onboarding   | n/a                            |    no    |
| `shouldAddCurrentUserClusterAdmin` | Add current user as cluster admin                | `true`                         |    no    |
| `clusterServerVirtualMachineName`  | VM name for the server                           | n/a                            |    no    |
| `clusterNodeVirtualMachineNames`   | VM names for worker nodes                        | n/a                            |    no    |
| `shouldDeployScriptToVm`           | Deploy scripts directly to VMs                   | `false`                        |    no    |

## Prerequisites

Ensure you have the following prerequisites:

- If using `should_upload_to_key_vault=true`:
  - An existing Key Vault in your resource group (will be automatically found using naming convention if not specified)
  - Or specify a custom Key Vault name with `key_vault_name`
- Appropriate permissions to create resources

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

## Generated Scripts

This blueprint produces two types of scripts:

1. **Server Script**: Sets up the Kubernetes cluster primary node with K3s, installs necessary components, and enables Azure Arc connectivity.

2. **Node Script**: Configures additional nodes to join an existing K3s cluster (for multi-node deployments).

The scripts handle:

- K3s installation and configuration
- Azure CLI installation (optional)
- Azure login and subscription setup
- Azure Arc enablement
- Custom locations registration
- Workload identity setup
- Cluster role assignments

## Related Resources

- See the [full-single-cluster](../full-single-cluster/README.md) blueprint for complete deployment including the cluster
- See the [full-multi-node-cluster](../full-multi-node-cluster/README.md) blueprint for multi-node deployments

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
