---
title: Dual Peered Single Node Cluster Blueprint
description: Deploys two complete Azure IoT Operations environments with different address spaces and VNet peering for cross-cluster communication
author: Edge AI Team
ms.date: 2025-01-11
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

This blueprint deploys two complete Azure IoT Operations (AIO) environments with secure MQTT communication between clusters. Each environment includes a single-node, Arc-enabled Kubernetes cluster with different virtual network address spaces connected through VNet peering. The blueprint demonstrates a site-to-enterprise communication pattern using certificate-based MQTT authentication.

Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint implements a **site-to-enterprise** MQTT communication pattern with two independent clusters:

### Cluster A - Site (10.1.0.0/16)

- **Role**: Site/edge location acting as MQTT client
- **Components**:
  - Linux VM host in Azure with K3s Kubernetes cluster
  - Azure Arc connection and complete cloud resources (Key Vault, Storage, etc.)
  - Azure IoT Operations with MQTT client configuration
  - Certificate-based client authentication for secure communication
  - Optional messaging, observability, and asset management components

### Cluster B - Enterprise (10.2.0.0/16)

- **Role**: Enterprise/central location acting as MQTT broker
- **Components**:
  - Independent set of all the same infrastructure as Cluster A
  - Azure IoT Operations with secure MQTT broker configuration (port 28883)
  - TLS server certificate for encrypted communication
  - Client certificate validation for authentication
  - Separate resource group and identity management

### Cross-Cluster Security & Connectivity

- **VNet Peering**: Bidirectional peering enabling secure Azure backbone communication
- **Certificate-based MQTT**: Full TLS encryption with mutual authentication
- **Automated Certificate Management**: Terraform-generated certificates stored in Azure Key Vault
- **Secret Synchronization**: Azure Key Vault Secret Sync Controller for certificate distribution
- **TrustBundle Configuration**: ConfigMaps for CA certificate distribution using Kubernetes TrustBundle CRs

### Certificate Infrastructure

The blueprint implements a complete PKI system with:

- **Server Certificates**: Root CA → Intermediate CA → Server leaf certificate for Enterprise MQTT broker
- **Client Certificates**: Root CA → Intermediate CA → Client leaf certificate for Site MQTT client
- **Key Vault Storage**: All certificates and private keys securely stored in Azure Key Vault
- **Automatic Sync**: Secret Provider Classes and TrustBundles for Kubernetes certificate distribution

## Use Cases

This blueprint is ideal for scenarios requiring:

- **Site-to-Enterprise MQTT Communication** with secure certificate-based authentication
- **Industrial IoT Deployments** where edge sites need to communicate with central enterprise systems
- **Multi-tenant Edge Solutions** with isolated but connected environments
- **Proof of Concept Implementations** for secure MQTT communication patterns
- **Testing Cross-site Connectivity** between geographically distributed locations
- **Development and Production Environments** with occasional secure data exchange
- **Certificate Management Validation** using Azure Key Vault and Kubernetes integration

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

Each cluster uses the same infrastructure modules with cluster-specific prefixes (`cluster_a_` or `cluster_b_`):

| Module Type               | Purpose                                   | Source Location                                          |
|---------------------------|-------------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates separate resource groups          | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity` | Handles identity and security per cluster | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`     | Sets up monitoring infrastructure         | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`              | Creates data storage resources            | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`         | Sets up messaging infrastructure          | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_networking`        | Creates virtual networks with peering     | `../../../src/000-cloud/050-networking/terraform`        |
| `cloud_vm_host`           | Creates VM hosts for each cluster         | `../../../src/000-cloud/051-vm-host/terraform`           |
| `cloud_acr`               | Deploys ACR for each cluster              | `../../../src/000-cloud/060-acr/terraform`               |
| `cloud_kubernetes`        | Optional AKS deployment                   | `../../../src/000-cloud/070-kubernetes/terraform`        |
| `edge_cncf_cluster`       | Deploys K3s Kubernetes clusters           | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations             | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_assets`             | Manages OPC UA assets                     | `../../../src/100-edge/111-assets/terraform`             |
| `edge_observability`      | Sets up edge monitoring                   | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components         | `../../../src/100-edge/130-messaging/terraform`          |

### Blueprint-Specific Modules

This blueprint includes custom modules for MQTT communication and certificate management:

| Module Type                        | Purpose                                           | Source Location                              |
|------------------------------------|---------------------------------------------------|----------------------------------------------|
| `terraform_certificate_generation` | Generates PKI certificates for MQTT communication | `./modules/terraform-certificate-generation` |
| `key_vault_publisher`              | Stores certificates in Azure Key Vault            | `./modules/key-vault-publisher`              |
| `secret_provider_class`            | Creates Kubernetes secret provider classes        | `./modules/secret-provider-class`            |
| `apply_scripts`                    | Deploys site and enterprise configuration scripts | `./modules/apply-scripts`                    |
| `mqtt_configuration`               | Configures MQTT broker listeners and endpoints    | `./modules/mqtt-configuration`               |

### Variable Reference

This blueprint includes all variables from the single cluster blueprint plus cluster-specific configurations:

#### Core Variables

| Variable          | Description                | Default  | Notes                                                      |
|-------------------|----------------------------|----------|------------------------------------------------------------|
| `environment`     | Environment type           | Required | "dev", "test", "prod", etc.                                |
| `resource_prefix` | Prefix for resource naming | Required | Short unique alphanumeric string (max 6 chars recommended) |
| `location`        | Azure region location      | Required | "eastus2", "westus3", etc.                                 |
| `instance`        | Deployment instance number | `"001"`  | For multiple deployments                                   |

#### Cluster A Configuration

| Variable                           | Description                     | Default                                                              | Notes                                       |
|------------------------------------|---------------------------------|----------------------------------------------------------------------|---------------------------------------------|
| `use_existing_resource_group_a`    | Use existing RG for Cluster A   | `false`                                                              | When true, looks up existing resource group |
| `resource_group_name_a`            | Cluster A resource group name   | `null`                                                               | Auto-generated when null                    |
| `cluster_a_virtual_network_config` | Cluster A network configuration | `{address_space="10.1.0.0/16", subnet_address_prefix="10.1.1.0/24"}` | CIDR blocks for Cluster A                   |

#### Cluster B Configuration

| Variable                           | Description                     | Default                                                              | Notes                                       |
|------------------------------------|---------------------------------|----------------------------------------------------------------------|---------------------------------------------|
| `use_existing_resource_group_b`    | Use existing RG for Cluster B   | `false`                                                              | When true, looks up existing resource group |
| `resource_group_name_b`            | Cluster B resource group name   | `null`                                                               | Auto-generated when null                    |
| `cluster_b_virtual_network_config` | Cluster B network configuration | `{address_space="10.2.0.0/16", subnet_address_prefix="10.2.1.0/24"}` | CIDR blocks for Cluster B                   |

#### Shared Configuration

All other variables from the single cluster blueprint are shared between both clusters, including:

- `should_get_custom_locations_oid`
- `custom_locations_oid`
- `should_create_anonymous_broker_listener`
- `should_create_aks`
- `should_create_acr_private_endpoint`
- `aio_features`
- `should_deploy_resource_sync_rules`
- `should_enable_opc_ua_simulator`
- Asset and messaging configuration variables

#### MQTT Configuration Variables

| Variable                                 | Description                                       | Default              | Notes                                  |
|------------------------------------------|---------------------------------------------------|----------------------|----------------------------------------|
| `enterprise_broker_port`                 | Port number for enterprise MQTT broker            | `28883`              | TLS-secured MQTT port                  |
| `enterprise_broker_tls_cert_secret_name` | Kubernetes secret name for broker TLS certificate | `"broker-tls-cert"`  | Used by Enterprise cluster MQTT broker |
| `enterprise_client_ca_configmap_name`    | ConfigMap name for client CA certificate          | `"client-ca"`        | Used for client certificate validation |
| `site_client_secret_name`                | Kubernetes secret name for client certificate     | `"client-secret"`    | Used by Site cluster MQTT client       |
| `site_tls_ca_configmap_name`             | ConfigMap name for TLS CA certificate             | `"tls-ca-configmap"` | Used for server certificate validation |

#### Certificate Configuration Variables

| Variable                | Description                                        | Default | Notes                                                    |
|-------------------------|----------------------------------------------------|---------|----------------------------------------------------------|
| `external_certificates` | External certificates to use instead of generating | `null`  | When null, certificates are auto-generated via Terraform |

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

## Resource Naming Convention

Resources are automatically named with cluster-specific prefixes to maintain separation:

- **Site Cluster (A)**: `{resource_type}-{resource_prefix}a-{environment}-{instance}`
- **Enterprise Cluster (B)**: `{resource_type}-{resource_prefix}b-{environment}-{instance}`

For example, with `resource_prefix="myorg"`, `environment="dev"`, and `instance="001"`:

- Site VM: `vm-myorga-dev-001`
- Enterprise VM: `vm-myorgb-dev-001`
- Site Resource Group: `rg-myorga-dev-001`
- Enterprise Resource Group: `rg-myorgb-dev-001`

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

### Example Deployment

```bash
# Initialize Terraform
terraform init

# Plan with basic configuration (uses auto-generated certificates)
terraform plan \
  -var="environment=dev" \
  -var="resource_prefix=myorg" \
  -var="location=eastus2"

# Plan with custom network ranges
terraform plan \
  -var="environment=dev" \
  -var="resource_prefix=myorg" \
  -var="location=eastus2" \
  -var="cluster_a_virtual_network_config={address_space=\"192.168.1.0/24\",subnet_address_prefix=\"192.168.1.0/28\"}" \
  -var="cluster_b_virtual_network_config={address_space=\"192.168.2.0/24\",subnet_address_prefix=\"192.168.2.0/28\"}"

# Apply the configuration
terraform apply
```

### Certificate Management Features

The blueprint includes comprehensive certificate management for secure MQTT communication:

#### Automated Certificate Generation

- **Terraform PKI Module**: Generates complete certificate chains using Terraform's `tls` provider
- **Server Chain**: Root CA → Intermediate CA → Server leaf certificate for Enterprise MQTT broker
- **Client Chain**: Root CA → Intermediate CA → Client leaf certificate for Site MQTT client
- **Azure Key Vault Storage**: All certificates and private keys stored securely in Azure Key Vault

#### Kubernetes Integration

- **Secret Provider Classes**: Azure Key Vault integration for Kubernetes secret synchronization
- **TrustBundle Resources**: ConfigMap creation from synced certificates for CA distribution
- **Automated Script Deployment**:
  - **Site Script** (`site.sh`): Deploys TrustBundle and Secret Provider Class for Site cluster
  - **Enterprise Script** (`enterprise.sh`): Deploys TrustBundle and Secret Provider Class for Enterprise cluster

#### MQTT Configuration

- **Enterprise Broker Configuration**: Secure MQTT broker listener on port 28883 with TLS and client authentication
- **Site Client Configuration**: MQTT client endpoints with certificate-based authentication
- **Cross-cluster Communication**: Secure MQTT messages flowing from Site to Enterprise through VNet peering

The certificate synchronization and MQTT configuration are fully automated through Terraform modules and Kubernetes manifests located in the `yaml/` directory.

## Deployment Outputs

After successful deployment, Terraform provides the following outputs for managing your clusters:

### Cluster Connection Commands

- `cluster_a_azure_arc_proxy_command`: AZ CLI command to connect to the Site cluster via Azure Arc
- `cluster_b_azure_arc_proxy_command`: AZ CLI command to connect to the Enterprise cluster via Azure Arc

### Resource Information

- `cluster_a_resource_group`: Site cluster resource group details
- `cluster_b_resource_group`: Enterprise cluster resource group details
- `cluster_a_virtual_network`: Site cluster VNet configuration
- `cluster_b_virtual_network`: Enterprise cluster VNet configuration

### Azure IoT Operations

- `cluster_a_aio_instance`: Site cluster AIO instance information
- `cluster_b_aio_instance`: Enterprise cluster AIO instance information
- `cluster_a_arc_connected_cluster`: Site cluster Arc connection details
- `cluster_b_arc_connected_cluster`: Enterprise cluster Arc connection details

### Network Peering

- `vnet_peering_cluster_a_to_cluster_b`: Peering configuration from Site to Enterprise
- `vnet_peering_cluster_b_to_cluster_a`: Peering configuration from Enterprise to Site

### Certificate Management

- `secret_provider_class_status`: Status and details of certificate synchronization setup

## Testing Connectivity

After deployment, you can test the MQTT communication between clusters:

### 1. Connect to Clusters

```bash
# Connect to Site cluster (Cluster A)
az connectedk8s proxy -n <site-cluster-name> -g <site-resource-group>

# Connect to Enterprise cluster (Cluster B)
az connectedk8s proxy -n <enterprise-cluster-name> -g <enterprise-resource-group>
```

Use the output commands `cluster_a_azure_arc_proxy_command` and `cluster_b_azure_arc_proxy_command` for exact connection strings.

### 2. Verify Certificate Synchronization

```bash
# Check Site cluster certificate sync
kubectl get secrets -n azure-iot-operations | grep client-secret
kubectl get configmaps -n azure-iot-operations | grep tls-ca-configmap

# Check Enterprise cluster certificate sync
kubectl get secrets -n azure-iot-operations | grep broker-tls-cert
kubectl get configmaps -n azure-iot-operations | grep client-ca
```

### 3. Verify MQTT Configuration

```bash
# Check Enterprise broker listener (Cluster B)
kubectl get brokerlistener -n azure-iot-operations

# Check Site MQTT endpoints (Cluster A)
kubectl get mqttbridgeconnector -n azure-iot-operations
```

### 4. Test Network Connectivity

```bash
# From Site cluster, test connectivity to Enterprise cluster
kubectl run test-pod --image=busybox -it --rm -- sh
# Inside the pod:
nc -zv <enterprise-vm-private-ip> 28883
```

### 5. Monitor MQTT Traffic

```bash
# Check MQTT broker logs on Enterprise cluster
kubectl logs -l app.kubernetes.io/name=aio-mq-dmqtt-frontend -n azure-iot-operations

# Check client connection logs on Site cluster
kubectl logs -l app.kubernetes.io/name=aio-mq-bridge-connector -n azure-iot-operations
```

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
