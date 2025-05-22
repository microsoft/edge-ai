# Full Arc Multi-node Cluster Blueprint

## Overview

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on Arc-enabled servers that already exist in your environment. It configures these servers into a multi-node Kubernetes cluster and deploys all necessary AIO components, resulting in a production-grade edge computing environment with high availability that integrates with Azure cloud services.

Please follow general blueprint deployment and recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A K3s Kubernetes cluster on existing Arc-enabled servers
2. Cloud resources required by AIO (Key Vault, Storage, etc.)
3. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
4. Optional messaging and observability components

The resulting architecture provides a resilient, high-availability edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring suitable for production environments.

## Implementation Options

This blueprint is currently available in one implementation option:

- **Terraform** - Infrastructure as Code using HashiCorp Terraform

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
- **Versions** (`versions.tf`): Specifies the required provider versions

### Key Modules Used

| Module                    | Purpose                                          | Source Location                                          |
|---------------------------|--------------------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                          | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity` | Manages identities and security resources        | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`     | Sets up monitoring resources                     | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`              | Creates data storage resources                   | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`         | Deploys messaging components                     | `../../../src/000-cloud/040-messaging/terraform`         |
| `edge_cncf_cluster`       | Configures K3s Kubernetes on Arc-enabled servers | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations                    | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_observability`      | Sets up monitoring and observability             | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components                | `../../../src/100-edge/130-messaging/terraform`          |

### Variable Reference in Terraform

The blueprint requires several variables to configure the deployment:

| Variable                                  | Description                           | Default  | Notes                                                          |
|-------------------------------------------|---------------------------------------|----------|----------------------------------------------------------------|
| `environment`                             | Environment type                      | Required | "dev", "test", "prod", etc.                                    |
| `resource_prefix`                         | Prefix for resource naming            | Required | Short unique alphanumeric string                               |
| `location`                                | Azure region location                 | Required | "eastus2", "westus3", etc.                                     |
| `resource_group_name`                     | Name for the resource group           | Required | Name for new resource group to be created                      |
| `resource_group_tags`                     | Tags to add to resources              | `null`   | Optional map of tags                                           |
| `arc_machine_name_prefix`                 | Prefix for Arc machine names          | Required | Used to identify Arc-enabled servers                           |
| `arc_machine_count`                       | Number of Arc machines                | Required | Total count of Arc-enabled servers to use                      |
| `arc_machine_resource_group_name`         | Resource group for Arc machines       | Required | The resource group where Arc-enabled servers are registered    |
| `cluster_server_ip`                       | IP address for cluster server         | Required | IP address that worker nodes will use to connect to the server |
| `cluster_server_host_machine_username`    | Username for cluster server           | Required | Username for the server that will be given kubectl access      |
| `custom_locations_oid`                    | Custom Locations object ID            | Required | Retrieved via Azure CLI if not provided                        |
| `should_get_custom_locations_oid`         | Whether to get Custom Locations OID   | Required | Set to true to retrieve using Terraform's azuread provider     |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT broker listener | `false`  | For testing only - insecure                                    |
| `should_enable_opc_ua_simulator`          | Deploy OPC UA Simulator               | `true`   | Optional OPC UA simulator component                            |
| `should_enable_otel_collector`            | Deploy OpenTelemetry Collector        | `true`   | Optional observability component                               |

For additional configuration options, review the variables in `variables.tf`.

## Prerequisites

Ensure you have the following prerequisites:

1. **Arc-enabled servers**:
   - Multiple servers already onboarded to Azure Arc
   - At least 8 GB of RAM per server, recommended 16 GB of RAM
   - The first server (by index) will be used as the Kubernetes control plane

2. **Technical prerequisites**:
   - Registered resource providers (see deployment instructions)
   - Appropriate permissions to create resources
   - Network connectivity between the Arc-enabled servers

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

## Related Blueprints

- **[Full Multi-node Cluster](../full-multi-node-cluster/README.md)**: Complete deployment with newly created VMs
- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment on a single-node cluster
- **[Only Cloud Single Node Cluster](../only-cloud-single-node-cluster/README.md)**: Deploy only the cloud resources
- **[Only Edge IoT Ops](../only-edge-iot-ops/README.md)**: Deploy only the edge components assuming cloud infrastructure exists
