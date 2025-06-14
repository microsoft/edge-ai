---
title: Source Code Structure
description: Infrastructure as Code components organized by deployment location and purpose for enterprise deployments of Arc-enabled Azure IoT Operations solutions
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - source code
  - infrastructure as code
  - azure iot operations
  - arc-enabled
  - terraform
  - bicep
  - edge computing
  - cloud infrastructure
  - components
  - deployment
estimated_reading_time: 6
---

## Source Code Structure

The source code for this project is organized into discrete categories optimized for enterprise
deployments of Arc-enabled Azure IoT Operations solutions. The components are grouped by their
deployment location (cloud vs. edge) and purpose, taking project execution phases into account.
When a project first kicks off, pass the `azure-resource-providers` scripts off to Azure subscription
managers to ensure that all resource providers are pre-registered before work begins.
Cloud infrastructure teams can handle the `000-cloud` components, while physical plant
engineers can deploy the `100-edge` components for on-premises cluster set-up.

## Cloud Infrastructure (000-cloud)

1. [(000-cloud/000-resource-group)](./000-cloud/000-resource-group/README.md) - Resource Groups for all Azure resources
2. [(000-cloud/010-security-identity)](./000-cloud/010-security-identity/README.md) - Identity and security resources
   including Key Vault, Managed Identities, and role assignments
3. [(000-cloud/020-observability)](./000-cloud/020-observability/README.md) - Cloud-side monitoring and observability
   resources
4. [(000-cloud/030-data)](./000-cloud/030-data/README.md) - Data storage and Schema Registry resources
5. [(000-cloud/031-fabric)](./000-cloud/031-fabric/README.md) - Microsoft Fabric resources for data warehousing and
   analytics
6. [(000-cloud/040-messaging)](./000-cloud/040-messaging/README.md) - Event Grid, Event Hubs, Service Bus and messaging
   resources
7. [(000-cloud/051-vm-host)](./000-cloud/051-vm-host/README.md) - VM provisioning resources with configurable host
   operating system

## Edge Infrastructure (100-edge)

1. [(100-edge/100-cncf-cluster)](./100-edge/100-cncf-cluster/README.md) - Installation of a CNCF cluster that is AIO
   compatible (initially limited to K3s) and Arc enablement of target clusters, workload identity
2. [(100-edge/110-iot-ops)](./100-edge/110-iot-ops/README.md) - AIO deployment of core infrastructure components (MQ
   Broker, Edge Storage Accelerator, Secrets Sync Controller, Workload Identity Federation, OpenTelemetry Collector,
   etc.)
3. [(100-edge/120-observability)](./100-edge/120-observability/README.md) - Edge-specific observability components and
   monitoring tools
4. [(100-edge/130-messaging)](./100-edge/130-messaging/README.md) - Edge messaging components and data routing
   capabilities

## Applications & Utilities

1. [(500-application)](./500-application/README.md) - Custom workloads and applications, including a basic Inference
   Pipeline, TIG/TICK stacks, InfluxDB Data Historian, reference data backup from cloud to edge, etc.
2. [(900-tools-utilities)](./900-tools-utilities/README.md) - Utility scripts, tools, and supporting resources for edge
   deployments
3. [(starter-kit/dataflows-acsa-egmqtt-bidirectional)](./starter-kit/dataflows-acsa-egmqtt-bidirectional/README.md) - Sample
   that provides assets with Azure IoT Operations Dataflows and supported infrastructure creation
4. [(azure-resource-providers)](./azure-resource-providers/README.md) - Scripts to register required Azure resource
   providers for AIO and Arc in your subscription

## Prerequisites and Setting Up Your Environment

> Please refer to the [Root README](../README.md) for a complete list of prerequisites and setup instructions, ensure your Azure CLI is correctly configured with your subscription context set correctly.
> For a step-by-step guide with details, follow the instructions [Getting Started and Prerequisites Setup](../README.md#getting-started-and-environment-setup).

## Terraform Components - Getting Started

Each component directory that contains Terraform IaC will have a corresponding `terraform` directory which is a
[Terraform Module](https://developer.hashicorp.com/terraform/language/modules). This directory may
also contain:

- `tests` → Terraform tests used for testing the component module.
- `modules` → Internal Terraform modules that will set up individual parts of the component.

To use and deploy these component modules, either refer to a [blueprint](../blueprints) that will use these components
in tandem for a full or partial scenario deployment, or step into the `ci/terraform` directory to individually deploy
each component. The `ci` directory will handle deploying default configurations and is meant to
be used in a CI system for module verification.

### Terraform - Local CI

The following steps are for `ci` deployment completed from a local machine.

#### ⚠️ Terraform Prerequisites Required Before Proceeding

> **You must complete all [prerequisites and environment setup](../README.md#getting-started-and-environment-setup) before running these steps.**
> Ensure your Azure CLI is logged in and your subscription context is set correctly.

**Note on Telemetry:** If you wish to opt-out of sending telemetry data to Microsoft when deploying Azure resources with Terraform, you can set the environment variable `ARM_DISABLE_TERRAFORM_PARTNER_ID=true` before running any `terraform` commands.

#### Terraform - Create Resources

Set up terraform settings and apply them:

1. cd into the `<component>/ci/terraform` directory

   ```sh
   cd ./ci/terraform
   ```

2. Set up required env vars:

   ```sh
   # Dynamically get the Subscription ID or manually get and pass to ARM_SUBSCRIPTION_ID
   current_subscription_id=$(az account show --query id -o tsv)
   export ARM_SUBSCRIPTION_ID="$current_subscription_id"
   ```

3. Create a `terraform.tfvars` file with at least the following minimum configuration settings:

   ```hcl
   # Required, environment hosting resource: "dev", "prod", "test", etc...
   environment     = "<environment>"
   # Required, short unique alphanumeric string: "sample123", "plantwa", "uniquestring", etc...
   resource_prefix = "<resource-prefix>"
   # Required, region location: "eastus2", "westus3", etc...
   location        = "<location>"
   # Optional, instance/replica number: "001", "002", etc...
   instance        = "<instance>"
   ```

   For additional variables to configure, refer to the `variables.tf` or any of the `variables.*.tf` files located
   in the `terraform` directory for the component.

   > [!NOTE]: To have Terraform automatically use your variables you can name your tfvars file `terraform.auto.tfvars`.
   > Terraform will use variables from any `*.auto.tfvars` files located in the same deployment folder.

4. Initialize and apply terraform

   ```sh
   # Pulls down providers and modules, initializes state and backend
   # Use '-update -reconfigure' if provider or backend updates are required
   terraform init # -update -reconfigure

   # Review resource change list, then type 'y' enter to deploy, or, deploy with '-auto-approve'
   terraform apply -var-file=terraform.tfvars # -auto-approve
   ```

#### Terraform - Destroy Resources

To destroy the resources created by Terraform, run the following command:

```sh
# Remove all resources deployed by this terraform component
terraform destroy
```

This may take sometime to complete, the resources can also be deleted from the [Azure portal](https://portal.azure.com).
If deleting manually, be sure delete your local state representation by removing the following:

- `terraform.tfstate` → Local `tfstate` file representing what was deployed by Terraform.
- `.terraform.lock.hcl` → Local lock file for `tfstate`, prevents conflicting updates.
- `.terraform` → (Optional) Terraform providers and modules pulled down from `terraform init`

#### Terraform - Scripts

Scripts for deploying all Terraform CI is included with the `operate-all-terraform.sh` script. This script helps
assist in automatically deploying each individual Terraform component, in order:

1. Refer to [Terraform - Create Resources](#terraform---create-resources) above to add a `terraform.tfvars`
   located at `src/terraform.tfvars`.

2. Execute `operate-all-terraform.sh`

   ```sh
   # Use '--start-layer' and '--end-layer' to specify where the script should start and end deploying.
   ./operate-all-terraform.sh # --start-layer 030-iot-ops-cloud-reqs --end-layer 040-iot-ops
   ```

### Terraform - Generating Docs

To simplify doc generation, this directory makes use of [terraform-docs](https://terraform-docs.io/). To generate docs
for new modules or
re-generate docs for existing modules, run the following command from the root of this repository:

```sh
./scripts/update-all-terraform-docs.sh
```

This generates docs based on the configuration defined in `terraform-docs.yml`, located at the root of this repository.

### Terraform - Testing

Each Terraform component under `src/<component>/terraform` includes Terraform tests. To run these tests, ensure you have
completed an `az login` into your Azure subscription. `cd` into the `terraform` directory that you would like to test.
Then execute following commands:

```sh
# Required by the azurerm terraform provider
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
# Runs the tests if there is a tests folder in the same directory.
terraform test
```

Optionally, if needed (due to restrictive subscription level permissions), testing with the pre-fetched value for
[OID for Azure Arc Custom Locations](https://learn.microsoft.com/azure/azure-arc/kubernetes/custom-locations#to-enable-the-custom-locations-feature-with-a-service-principal-follow-the-steps-below)
can be done by using the following set of commands:

```sh
# Terraform is case-sensitive with variable names provided by environment variables
export TF_VAR_custom_locations_oid
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
terraform test

# Additionally, you can use the '-var' parameter to pass variables on the command line
# terraform test -var custom_locations_oid=$(TF_VAR_CUSTOM_LOCATIONS_OID)
```

## Bicep Components - Getting Started

Each component directory that contains Bicep IaC will have a corresponding `bicep` directory with Bicep templates.
Similar to Terraform modules, these templates are designed to be reusable building blocks for your infrastructure
deployments.

### Bicep - Local CI

The following steps are for manual local deployment of Bicep components.

#### ⚠️ Bicep Prerequisites Required Before Proceeding

> **You must complete all [prerequisites and environment setup](../README.md#getting-started-and-environment-setup) before running these steps.**
> Ensure your Azure CLI is logged in and your subscription context is set correctly.

#### Bicep - Create Resources

Set up Bicep parameters and deploy:

1. cd into the `<component>/ci/bicep` directory

   ```sh
   cd ./component-directory/ci/bicep
   ```

1. Create a resource group for your deployment

   ```sh
   # Replace with your preferred location
   LOCATION="eastus2"
   # Create a unique resource group name
   RESOURCE_GROUP_NAME="rg-aio-bicep-deployment"

   # Create the resource group
   az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
   ```

1. Create a parameter file named `main.dev.bicepparam` in the `ci/bicep` directory with your deployment parameters:

   ```bicep
   // Parameters for component deployment
   using './bicep/main.bicep'

   // Required parameters
   param common = {
     resourcePrefix: 'myprefix'     // Replace with a unique prefix
     location: 'eastus2'            // Replace with your Azure region
     environment: 'dev'             // 'dev', 'test', or 'prod'
     instance: '001'                // Instance identifier
   }

   // Component-specific parameters will vary based on the component
   // Example additional parameters:
   // param storageAccountSku = 'Standard_LRS'
   // param enableDiagnostics = true
   ```

1. Deploy the Bicep template

   ```sh
   # Deploy a specific component
   az deployment group create \
     --name <deployment-name> \
     --resource-group $RESOURCE_GROUP_NAME \
     --parameters ./main.dev.bicepparam
   ```

#### Bicep - Cleanup Resources

To remove resources created by Bicep deployments, you can:

```sh
# Remove a specific deployment
az deployment group delete --resource-group $RESOURCE_GROUP_NAME --name <deployment-name>

# Remove the entire resource group and all resources
az group delete --name $RESOURCE_GROUP_NAME --no-wait
```

### Bicep - Generating Docs

To simplify doc generation, this directory makes use of scripts to generate documentation for Bicep modules.
To generate docs for new modules or re-generate docs for existing modules, run the following command from the root of
this repository:

```sh
./scripts/update-all-bicep-docs.sh
```

This generates documentation based on the configuration defined in the repository, using the metadata from your Bicep
files.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
