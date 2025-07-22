---
title: Dual Peered Single Node Cluster Blueprint
description: Deploys two complete Azure IoT Operations environments with different address spaces and VNet peering for cross-cluster communication
author: Edge AI Team
ms.date: 01/11/2025
ms.topic: reference
keywords:
  - azure iot operations
  - dual cluster
  - vnet peering
  - kubernetes
  - arc-enabled
  - terraform
  - edge computing
  - vm deployment
  - k3s cluster
  - network isolation
estimated_reading_time: 4
---

## Dual Peered Single Cluster Blueprint

This blueprint deploys two complete Azure IoT Operations (AIO) environments, each with their own single-node, Arc-enabled Kubernetes cluster. The clusters operate in different virtual network address spaces but are connected through VNet peering, enabling secure communication between the environments while maintaining network isolation.

Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys two independent clusters with the following components for each:

### Per Cluster Components

1. **Cluster A (10.1.0.0/16)**:
   - Linux VM host in Azure
   - K3s Kubernetes cluster on the VM
   - Azure Arc connection for the cluster
   - Complete set of cloud resources (Key Vault, Storage, etc.)
   - Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
   - Optional messaging and observability components

2. **Cluster B (10.2.0.0/16)**:
   - Independent set of all the same components as Cluster A
   - Separate resource group and identity management
   - Different virtual network address space

### Cross-Cluster Connectivity

- **VNet Peering**: Bidirectional peering between Cluster A and Cluster B networks
- **Secure Communication**: Traffic flows through Azure backbone infrastructure
- **Network Isolation**: Each cluster maintains its own address space and security boundaries

### Custom Script Deployment

- **Dynamic Certificate Generation**: Automatically generates TLS certificates using the server VM's private IP address as Subject Alternative Name (SAN)
- **Automated Certificate Management**: Pre-configured certificates for secure MQTT communication between clusters
- **Server Central Configuration**: Deploys server-central.sh to Cluster A for MQTT broker setup with proper certificates
- **Client Technology Configuration**: Deploys client-technology.sh to Cluster B for client endpoint setup with certificate-based authentication
- **Resource Provisioning**: Automatically deploys required Kubernetes manifests and certificates to both clusters

## Use Cases

This blueprint is ideal for scenarios requiring:

- **Multi-tenant edge deployments** with isolated but connected environments
- **Development and production** environments that need occasional data exchange
- **Disaster recovery** setups with active-passive or active-active configurations
- **Cross-site data replication** and backup scenarios
- **Testing network connectivity** between geographically distributed edge sites

## Implementation

This blueprint is currently available as:

- **Terraform** - Infrastructure as Code using HashiCorp Terraform

## Terraform Structure

This blueprint extends the single cluster pattern with dual deployment and network peering:

- **Main Configuration** (`main.tf`): Orchestrates two complete cluster deployments plus VNet peering
- **Variables** (`variables.tf`): Defines parameters for both clusters with separate network configurations
- **Outputs** (`outputs.tf`): Exposes information from both clusters and peering connections
- **Versions** (`versions.tf`): Specifies provider versions and requirements

### Key Modules Used

Each cluster uses the same modules as the single cluster blueprint, prefixed with `cluster_a_` or `cluster_b_`:

| Module Type                    | Purpose                                 | Source Location                                          |
|--------------------------------|-----------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`         | Creates separate resource groups        | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity`      | Handles identity and security per cluster| `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`          | Sets up monitoring infrastructure       | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`                   | Creates data storage resources          | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`              | Sets up messaging infrastructure        | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_networking`             | Creates virtual networks with peering   | `../../../src/000-cloud/050-networking/terraform`        |
| `cloud_vm_host`                | Creates VM hosts for each cluster       | `../../../src/000-cloud/051-vm-host/terraform`           |
| `cloud_acr`                    | Deploys ACR for each cluster            | `../../../src/000-cloud/060-acr/terraform`               |
| `cloud_kubernetes`             | Optional AKS deployment                 | `../../../src/000-cloud/070-kubernetes/terraform`        |
| `edge_cncf_cluster`            | Deploys K3s Kubernetes clusters         | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`                 | Installs Azure IoT Operations           | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_assets`                  | Manages OPC UA assets                   | `../../../src/100-edge/111-assets/terraform`             |
| `edge_observability`           | Sets up edge monitoring                 | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`               | Deploys edge messaging components       | `../../../src/100-edge/130-messaging/terraform`          |
| `certificate_generation`       | Generates TLS certificates with Step CLI| `./modules/certificate-generation`                       |
| `terraform_certificate_generation` | Generates TLS certificates with Terraform TLS provider| `./modules/terraform-certificate-generation`    |
| `secret_provider_class`        | Creates Key Vault secret provider classes| `./modules/secret-provider-class`                       |
| `custom_script_deployment`     | Deploys custom scripts to VMs           | `./modules/custom-script-deployment`                     |

### Variable Reference

This blueprint includes all variables from the single cluster blueprint plus cluster-specific configurations:

#### Core Variables

| Variable                                  | Description                        | Default  | Notes                                                       |
|-------------------------------------------|------------------------------------|----------|-------------------------------------------------------------|
| `environment`                             | Environment type                   | Required | "dev", "test", "prod", etc.                                 |
| `resource_prefix`                         | Prefix for resource naming         | Required | Short unique alphanumeric string (max 6 chars recommended)  |
| `location`                                | Azure region location              | Required | "eastus2", "westus3", etc.                                  |
| `instance`                                | Deployment instance number         | `"001"`  | For multiple deployments                                    |

#### Cluster A Configuration

| Variable                                  | Description                        | Default                     | Notes                                                       |
|-------------------------------------------|------------------------------------|----------------------------|-------------------------------------------------------------|
| `use_existing_resource_group_a`           | Use existing RG for Cluster A     | `false`                    | When true, looks up existing resource group                 |
| `resource_group_name_a`                   | Cluster A resource group name      | `null`                     | Auto-generated when null                                    |
| `cluster_a_virtual_network_config`       | Cluster A network configuration    | `{address_space="10.1.0.0/16", subnet_address_prefix="10.1.1.0/24"}` | CIDR blocks for Cluster A |

#### Cluster B Configuration

| Variable                                  | Description                        | Default                     | Notes                                                       |
|-------------------------------------------|------------------------------------|----------------------------|-------------------------------------------------------------|
| `use_existing_resource_group_b`           | Use existing RG for Cluster B     | `false`                    | When true, looks up existing resource group                 |
| `resource_group_name_b`                   | Cluster B resource group name      | `null`                     | Auto-generated when null                                    |
| `cluster_b_virtual_network_config`       | Cluster B network configuration    | `{address_space="10.2.0.0/16", subnet_address_prefix="10.2.1.0/24"}` | CIDR blocks for Cluster B |

#### Shared Configuration

All other variables from the single cluster blueprint are shared between both clusters, including:

- `should_get_custom_locations_oid`
- `custom_locations_oid`
- `should_create_anonymous_broker_listener`
- `should_create_aks`
- `should_create_acr_private_endpoint`
- `aio_features`
- Asset and messaging configuration variables

#### Certificate Generation Configuration

| Variable                                  | Description                        | Default                     | Notes                                                       |
|-------------------------------------------|------------------------------------|----------------------------|-------------------------------------------------------------|
| `should_create_certificates`              | Generate certificates using Step CLI | `true`                   | When true, chooses between Step CLI or Terraform; when false, uses secret-provider-class module |
| `use_terraform_certificates`              | Use Terraform TLS provider instead of Step CLI | `false`          | Only applies when should_create_certificates is true; requires no external dependencies |

#### Custom Script Deployment Configuration

| Variable                                  | Description                        | Default                     | Notes                                                       |
|-------------------------------------------|------------------------------------|----------------------------|-------------------------------------------------------------|
| `should_deploy_custom_scripts`            | Deploy both custom scripts        | `false`                    | Enables both server-central.sh and client-technology.sh     |
| `should_deploy_server_central_script`     | Deploy server script to Cluster A | `false`                    | Deploys MQTT broker configuration on Cluster A             |
| `should_deploy_client_technology_script`  | Deploy client script to Cluster B | `false`                    | Deploys MQTT client configuration on Cluster B             |

### Network Configuration

The blueprint creates non-overlapping address spaces by default:

- **Cluster A**: 10.1.0.0/16 with subnet 10.1.1.0/24
- **Cluster B**: 10.2.0.0/16 with subnet 10.2.1.0/24

You can customize these address spaces through the `cluster_a_virtual_network_config` and `cluster_b_virtual_network_config` variables.

### VNet Peering Configuration

The blueprint automatically creates bidirectional peering with the following settings:

- **Allow Virtual Network Access**: Enabled
- **Allow Forwarded Traffic**: Enabled
- **Allow Gateway Transit**: Disabled
- **Use Remote Gateways**: Disabled

## Prerequisites

Ensure you have the following prerequisites:

- Sufficient quota for **two VMs** in your target region
- At least **16 GB of RAM total** (8 GB per VM, 16 GB recommended per VM)
- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources in multiple resource groups
- **Non-overlapping IP address spaces** if you customize the network configuration
- **Step CLI tool** installed for certificate generation ([installation guide](https://smallstep.com/docs/step-cli/installation/))

## Resource Naming Convention

Resources are automatically named with cluster-specific prefixes:

- **Cluster A**: `{resource_type}-{resource_prefix}-cluster-a-{environment}-{instance}`
- **Cluster B**: `{resource_type}-{resource_prefix}-cluster-b-{environment}-{instance}`

For example, with `resource_prefix="myorg"`, `environment="dev"`, and `instance="001"`:

- Cluster A VM: `vm-myorg-cluster-a-dev-001`
- Cluster B VM: `vm-myorg-cluster-b-dev-001`

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

### Example Deployment

```bash
# Initialize Terraform
terraform init

# Plan with custom network ranges and Terraform-based certificate generation
terraform plan \
  -var="environment=dev" \
  -var="resource_prefix=myorg" \
  -var="location=eastus2" \
  -var="should_deploy_custom_scripts=true" \
  -var="use_terraform_certificates=true" \
  -var="cluster_a_virtual_network_config={address_space=\"192.168.1.0/24\",subnet_address_prefix=\"192.168.1.0/28\"}" \
  -var="cluster_b_virtual_network_config={address_space=\"192.168.2.0/24\",subnet_address_prefix=\"192.168.2.0/28\"}"

# Apply the configuration
terraform apply
```

### Script Deployment Features

The blueprint includes automated certificate generation and deployment of custom scripts:

#### Certificate Generation vs Secret Provider Classes

The blueprint supports three mutually exclusive approaches for handling secrets and certificates:

**Certificate Generation Mode with Step CLI (Default)** - `should_create_certificates = true && use_terraform_certificates = false`:

- **Dynamic Certificate Generation**: Executes `certs.sh` script locally using the Step CLI to generate TLS certificates with the server VM's private IP address as SAN
- **Local Certificate Management**: All certificates are generated and managed locally during Terraform execution
- **Requires Step CLI**: Must have Step CLI installed on the machine running Terraform

**Certificate Generation Mode with Terraform TLS Provider** - `should_create_certificates = true && use_terraform_certificates = true`:

- **Pure Terraform Implementation**: Uses Terraform's TLS provider to generate the same certificates as the Step CLI script
- **No External Dependencies**: Does not require Step CLI or any external tools
- **State-based Management**: Certificates are tracked in Terraform state for lifecycle management
- **Cross-Platform**: Works on any platform that supports Terraform

**Secret Provider Class Mode** - `should_create_certificates = false`:

- **Azure Key Vault Integration**: Creates `Microsoft.SecretSyncController/azureKeyVaultSecretProviderClasses` resources for both clusters
- **Cloud-based Secret Management**: Secrets are managed and synchronized from Azure Key Vault
- **No Local Dependencies**: Does not require Step CLI or local certificate generation

#### Deployment Features (All Modes)

- **Server Central (Cluster A)**: Configures MQTT broker with authentication and TLS certificates (from Step CLI, Terraform, or Key Vault)
- **Client Technology (Cluster B)**: Sets up MQTT client endpoints with certificate-based authentication
- **Kubernetes Resources**: Applies necessary broker listeners, endpoints, and routing configurations from `scripts/` manifests
- **Template-Free Deployment**: Scripts are embedded as Terraform locals using templatefile() for clean separation of concerns

The certificate generation runs first using either Step CLI execution, Terraform TLS provider, or secret provider class configuration via Azure API, followed by script deployment via Azure VM Custom Script Extensions. All certificate and manifest files are base64-encoded and embedded directly into the script content for security and reliability.

### Certificate Options Comparison

| Feature | Step CLI | Terraform TLS | Key Vault |
|---------|----------|---------------|-----------|
| External Dependencies | Requires Step CLI | None | None |
| Certificate Format | Step CLI optimized | Standard X.509 | Azure managed |
| Platform Requirements | Step CLI availability | Terraform only | Azure only |
| State Management | File-based | Terraform state | Cloud-based |
| Security Considerations | Local files | State file | Azure security |
| Rotation Method | Re-run script | Terraform apply | Azure automation |
| Variable Configuration | `should_create_certificates=true, use_terraform_certificates=false` | `should_create_certificates=true, use_terraform_certificates=true` | `should_create_certificates=false` |

## Testing Connectivity

After deployment, you can test connectivity between clusters:

1. **Connect to Cluster A**: Use the output `cluster_a_azure_arc_proxy_command`
2. **Connect to Cluster B**: Use the output `cluster_b_azure_arc_proxy_command`
3. **Test network connectivity**: Deploy test pods and ping between cluster subnets

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
