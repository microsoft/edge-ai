---
title: Azure Machine Learning Blueprint
description: Comprehensive Azure Machine Learning deployment with optional cloud foundation, managed compute, AKS/Arc integration, and secure connectivity controls
ms.date: 09/24/2025
ms.topic: reference
estimated_reading_time: 12
keywords:
  - azure machine learning
  - azureml
  - workspace
  - compute cluster
  - aks integration
  - arc kubernetes
  - edge ml
  - training
  - inference
  - terraform
---

## Overview

This blueprint composes the Azure Machine Learning component with optional networking, security, data, container registry, Kubernetes, and edge integrations. Toggle only the pieces you need so that you can land the workspace in an existing landing zone or provision everything end-to-end.

## Architecture

- **Azure Machine Learning workspace** – creates the workspace, assigns access, and connects storage, Application Insights, Key Vault, and optional registry resources. Public network access is disabled by default.
- **Networking and outbound controls** *(optional)* – provisions a virtual network, subnets, network security group, NAT gateway for managed outbound access, Azure DNS Private Resolver, and (optionally) a VPN gateway with certificate management.
- **Security and data foundation** *(optional)* – deploys Key Vault, managed identities, storage account, and Application Insights components when they are not supplied.
- **Azure Container Registry** *(optional)* – builds an ACR instance with private endpoint and NAT-aware configuration for ML image ingestion.
- **Azure Kubernetes Service** *(optional)* – provisions an AKS cluster with workload identity, additional node pools, GPU options, optional Helm/Command Invoke installs, and Azure Monitor integration.
- **AKS integration and Azure ML extension** *(optional)* – registers an AKS cluster (existing or created) as a compute target, configures inference router behaviour, installs GPU add-ons, and supports Kubernetes instance type definitions and tolerations.
- **Azure ML compute cluster** – creates an auto-scaling compute cluster with configurable VM size, priority, idle timeout, and network exposure.
- **Azure ML registry** *(optional)* – deploys a private or public Azure ML registry backed by the storage and ACR resources.
- **Arc-enabled Kubernetes integration** *(optional)* – deploys the Azure ML edge extension to an Arc-connected cluster and registers it as an additional compute target.

## Prerequisites

### Required Azure resources

- **Resource group** for the workspace and optional cloud components (`resource_group_name` defaults to `rg-{resource_prefix}-{environment}-{instance}`).
- **Storage account** when `should_create_storage = false`. Provide the name with `storage_account_name` so the blueprint can attach to it.

> When you reuse existing services (networking, ACR, AKS, Arc, Key Vault, Application Insights) set the relevant `*_name` override so the blueprint can perform lookups.

### Optional existing infrastructure

Set the creation flags to `false` to attach to these resources instead of creating new ones:

- Virtual network and subnet (`virtual_network_name`, `subnet_name`)
- Azure Container Registry (`acr_name`)
- Azure Kubernetes Service cluster (`aks_cluster_name`)
- Arc-enabled Kubernetes cluster (`arc_connected_cluster_name`)
- Key Vault (`key_vault_name`)
- Application Insights (`application_insights_name`)

### Required tools

- Terraform >= 1.9.8
- Azure CLI authenticated to the target subscription. Run `source ./scripts/az-sub-init.sh` to set `ARM_SUBSCRIPTION_ID` before any Terraform command.

### Required providers

- `hashicorp/azurerm` >= 4.8.0
- `azure/azapi` >= 2.0.1 (Arc and extension lookups)
- `hashicorp/azuread` >= 3.x (used by networking and security identity modules)

## Usage

Run `terraform-docs tfvars hcl .` from `blueprints/azureml/terraform` to generate a `terraform.tfvars` skeleton, fill in required values, then apply one of the scenarios below.

### Minimal workspace with managed dependencies

```hcl
module "azureml_workspace" {
  source = "./blueprints/azureml/terraform"

  environment     = "dev"
  location        = "eastus2"
  resource_prefix = "mycoai"
  instance        = "001"

  should_create_security_identity = true
  should_create_observability     = true
  should_create_storage           = true

  # Existing landing zone handles networking and ACR
  should_create_networking  = false
  should_create_acr         = false
  should_create_aks_cluster = false

  should_enable_public_network_access = false
}
```

### Full landing zone with AKS integration and private connectivity

```hcl
module "azureml_full" {
  source = "./blueprints/azureml/terraform"

  environment     = "prod"
  location        = "eastus2"
  resource_prefix = "mycoai"
  instance        = "001"

  should_create_networking        = true
  should_create_acr               = true
  should_create_aks_cluster       = true
  should_create_security_identity = true
  should_create_observability     = true
  should_create_storage           = true

  node_count                      = 3
  node_vm_size                    = "Standard_D8ds_v5"
  subnet_address_prefixes_aks     = ["10.0.5.0/24"]
  subnet_address_prefixes_aks_pod = ["10.0.6.0/24"]

  should_integrate_aks_cluster        = true
  should_enable_cluster_training      = true
  should_enable_cluster_inference     = true
  inference_router_service_type       = "LoadBalancer"
  should_install_nvidia_device_plugin = true
  should_install_dcgm_exporter        = true

  compute_cluster_vm_size     = "Standard_DS3_v2"
  compute_cluster_max_nodes   = 10
  compute_cluster_min_nodes   = 0
  compute_cluster_vm_priority = "Dedicated"

  should_enable_private_endpoints       = true
  should_enable_managed_outbound_access = true
  should_enable_vpn_gateway             = true
}
```

### GPU-optimised AKS pools with taints and autoscale

```hcl
module "azureml_gpu" {
  source = "./blueprints/azureml/terraform"

  environment     = "prod"
  location        = "eastus2"
  resource_prefix = "mycoai"
  instance        = "002"

  should_create_networking        = true
  should_create_acr               = true
  should_create_aks_cluster       = true
  should_create_security_identity = true
  should_create_observability     = true
  should_create_storage           = true

  node_count   = 2
  node_vm_size = "Standard_D8ds_v5"

  node_pools = {
    "gpu-a10" = {
      vm_size                     = "Standard_NV36ads_A10_v5"
      subnet_address_prefixes     = ["10.0.7.0/24"]
      pod_subnet_address_prefixes = ["10.0.8.0/24"]
      enable_auto_scaling         = true
      min_count                   = 1
      max_count                   = 4
      node_taints                 = ["sku=gpu:NoSchedule"]
    }
  }

  should_integrate_aks_cluster        = true
  should_enable_cluster_training      = true
  should_enable_cluster_inference     = true
  should_install_nvidia_device_plugin = true

  system_tolerations = [{
    key      = "sku"
    value    = "gpu"
    effect   = "NoSchedule"
    operator = "Equal"
  }]

  workload_tolerations = [{
    key      = "sku"
    value    = "gpu"
    effect   = "NoSchedule"
    operator = "Equal"
  }]
}
```

Available NVIDIA A10 v5 VM sizes include `Standard_NV6ads_A10_v5`, `Standard_NV12ads_A10_v5`, `Standard_NV18ads_A10_v5`, `Standard_NV36ads_A10_v5`, `Standard_NV36adms_A10_v5`, and `Standard_NV72ads_A10_v5`.

### Edge extension on an Arc-enabled cluster

```hcl
module "azureml_edge" {
  source = "./blueprints/azureml/terraform"

  environment     = "prod"
  location        = "eastus2"
  resource_prefix = "factory"
  instance        = "001"

  should_deploy_edge_extension = true
  arc_connected_cluster_name   = "arck-factory-edge-001"

  extension_name                 = "azureml-factory-edge"
  should_enable_cluster_training = true
  should_enable_cluster_inference = true

  ssl_cname   = "ml-inference.factory.local"
  ssl_cert_pem = file("${path.module}/../certs/factory-edge.pem")
  ssl_key_pem  = file("${path.module}/../certs/factory-edge-key.pem")
}
```

## Variables

The complete and authoritative input reference is generated from the Terraform module. Review the latest definitions, defaults, and validation rules in the [blueprint Terraform README](./terraform/README.md). Use the `terraform-docs tfvars hcl .` output in `blueprints/azureml/terraform` to scaffold your `terraform.tfvars` file.

## Outputs

The blueprint surfaces module outputs defined in the Terraform implementation. Review the full list and descriptions in the [blueprint Terraform README](./terraform/README.md).

## Deployment scenarios

### Development environment

```hcl
should_create_security_identity = true
should_create_observability     = true
should_create_storage           = true
compute_cluster_vm_priority     = "LowPriority"
compute_cluster_max_nodes       = 2
```

### Production cloud environment

```hcl
should_create_networking         = true
should_create_acr                = true
should_create_aks_cluster        = true
should_create_security_identity  = true
should_create_observability      = true
should_create_storage            = true
should_integrate_aks_cluster     = true
should_enable_private_endpoints  = true
should_enable_managed_outbound_access = true
should_enable_vpn_gateway        = true
node_count                       = 5
compute_cluster_max_nodes        = 20
```

### Hybrid edge deployment

```hcl
should_create_security_identity = true
should_create_observability     = true
should_create_storage           = true

should_deploy_edge_extension = true
arc_connected_cluster_name   = "edge-cluster-001"
```

## Security

- **Network isolation** – combine VNet, private endpoints, NAT gateway, and optional VPN gateway for controlled ingress/egress.
- **Managed identities** – Key Vault and managed identities secure access between services.
- **Encryption and secret management** – Key Vault backs sensitive material; SSL variables allow you to supply certificates for inference endpoints.
- **Access control** – workspace role assignments and optional disabling of public network access harden the control plane.
- **Compliance** – private endpoints, workload identity, and registry toggles align with enterprise security requirements.

## Cost optimization

- Set `compute_cluster_min_nodes = 0` to scale training clusters to zero when idle.
- Use `compute_cluster_vm_priority = "LowPriority"` for development workloads.
- Tune `nat_gateway_public_ip_count` and `nat_gateway_idle_timeout_minutes` to balance egress cost and capacity.
- Scale AKS pools with the `node_pools` map and autoscaler fields rather than leaving GPU nodes idle.

## Deployment steps

1. **Initialize Azure subscription context**

   ```bash
   source ./scripts/az-sub-init.sh
   ```

2. **Change to the blueprint Terraform directory**

   ```bash
   cd blueprints/azureml/terraform
   ```

3. **Generate a tfvars template**

   ```bash
   terraform-docs tfvars hcl .
   ```

   Save the output to `terraform.tfvars` (or `terraform.auto.tfvars`) and populate required values.

4. **Initialize Terraform**

   ```bash
   terraform init -upgrade
   ```

5. **Plan changes**

   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

6. **Apply configuration**

   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

7. **Verify deployment**

   - Open [Azure ML Studio](https://ml.azure.com) to confirm workspace provisioning.
   - Inspect compute cluster state.
   - Confirm AKS or Arc extensions are healthy when enabled.

## Troubleshooting

### Terraform

Use these commands to investigate Terraform state issues:

```bash
terraform state list
terraform state show <resource address>
terraform state rm <resource address>
terraform import <address> <resource id>
terraform refresh
```

For permission or provider registration errors, ensure you have run the provider registration scripts in `scripts/` and that the signed-in principal has the required role assignments.

### AKS and Arc connectivity

- Verify `az connectedk8s proxy` access to the cluster and inspect pod health.
- Use `az k8s-extension list` to check extension provisioning state.
- Confirm workload identity is enabled by retrieving the `aks_oidc_issuer_url` output.

### VPN gateway

- If clients cannot connect, confirm the generated CA certificate is installed and that DNS forwarding uses the `private_resolver_dns_ip` output.
- When reusing an existing certificate, verify the `existing_certificate_name` points to a Key Vault certificate in the security identity component.

## GPU node pools

- Define GPU pools in `node_pools` with `node_taints` to keep workloads isolated.
- Provide matching tolerations in `system_tolerations` and `workload_tolerations`.
- Set `should_install_nvidia_device_plugin = true` and `should_install_dcgm_exporter = true` to deploy the required DaemonSets automatically. If you prefer manual installation, apply the NVIDIA device plugin manifest after deployment.
- Optional: When using spot-priced GPU nodes, set the pool `priority = "Spot"`, add the Azure spot taint (for example, `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`), and include a corresponding toleration in `workload_tolerations`. The sample `terraform.tfvars` above shows a full configuration that combines spot taints with GPU tolerations so that job scheduling remains predictable during preemptions.

## Sample GPU workload

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  tolerations:
    - key: "sku"
      operator: "Equal"
      value: "gpu"
      effect: "NoSchedule"
  containers:
    - name: gpu-container
      image: tensorflow/tensorflow:latest-gpu
      resources:
        limits:
          nvidia.com/gpu: 1
        requests:
          nvidia.com/gpu: 1
```

## Next steps

1. Configure datastores and data assets in the workspace.
2. Build pipelines for training and inference.
3. Deploy real-time endpoints or batch scoring jobs.
4. Monitor workloads using Application Insights and Azure Monitor.
5. Adjust compute configuration as usage patterns emerge.

## External references

- [What is an Azure Machine Learning workspace?](https://learn.microsoft.com/azure/machine-learning/concept-workspace)
- [Azure Machine Learning compute targets](https://learn.microsoft.com/azure/machine-learning/concept-compute-target)
- [Manage and optimize Azure Machine Learning costs](https://learn.microsoft.com/azure/machine-learning/how-to-manage-optimize-cost)
- [Deploy Azure Machine Learning extension on AKS or Arc](https://learn.microsoft.com/azure/machine-learning/how-to-deploy-kubernetes-extension)
- [NVIDIA device plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
