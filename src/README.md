# Source Code Structure

The source code for this project is organized into discrete steps optimized for enterprise
deployments of Arc-enabled Azure IoT Operations solutions, and takes project execution
phases into account. When a project first kicks off, pass the `000-subscription` IaC off
to Azure subscription managers to ensure that all resource providers are pre-registered
before work begins. Physical plant engineers can layer up `010`, `020` and `040` for on
premises cluster set-up. And so on.

1. [(000)](./000-subscription/README.md) Run-once scripts for Arc & AIO resource provider enablement in subscriptions, if necessary
2. [(005)](./005-onboard-reqs/README.md) Resource Groups, Site Management (optional), Role assignments/permissions for Arc onboarding
3. [(010)](./010-vm-host/README.md) VM/host provisioning, with configurable host operating system (initially limited to Ubuntu)
4. [(020)](./020-cncf-cluster/README.md) Installation of a CNCF cluster that is AIO compatible (initially limited to K3s) and Arc enablement of target clusters, workload identity
5. [(030)](./030-iot-ops-cloud-reqs/README.md) Cloud resource provisioning for Azure Key Vault, Storage Accounts, Schema Registry, Container Registry, and User Assigned Managed Identity
6. [(040)](./040-iot-ops/README.md) AIO deployment of core infrastructure components (MQ Broker, Edge Storage Accelerator, Secrets Sync Controller, Workload Identity Federation, OpenTelemetry Collector, OPC UA Simulator)
7. [(050)](./050-messaging/README.md) Cloud resource provisioning for cloud communication (MQTT protocol head for Event Grid (topic spaces, topics and cert-based authentication), Event Hubs, Service Bus, Relay, etc.)
8. [(060)](./060-storage/README.md) Cloud resource provisioning for data/event storage (Fabric by means of RTI, Data Lakes, Warehouses, etc.)
9. [(070)](./070-observability/README.md) Cloud resource provisioning for Azure Monitor and Container Insights
10. [(080)](./080-iot-ops-utility/README.md) AIO deployment of additionally selected components (OTEL Collector (Phase 2), OPC UA, AKRI, Strato, FluxCD/Argo)
11. (090) Customer defined custom workloads, and pre-built solution accelerators such as TIG/TICK stacks, InfluxDB Data Historian, reference data backup from cloud to edge, etc.
12. [(samples/dataflows-acsa-egmqtt-bidirectional)](./samples/dataflows-acsa-egmqtt-bidirectional/README.md) Sample that provides assets with Azure IoT Operations Dataflows and supported infrastructure creation to manage `AIO MQTT->ACSA` and `AIO MQTT-> Event Grid` bidirectional data flow.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- An Azure subscription
- [Visual Studio Code](https://code.visualstudio.com/)
- A Linux-based development environment or a [Windows system with WSL](https://code.visualstudio.com/docs/remote/wsl)

> NOTE: We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly particularly with Windows-bases systems.

Login to Azure CLI using the below command:

```sh
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

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

#### Terraform - Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)

#### Terraform - Create Resources

Login to Azure CLI using the below command:

```sh
# Optionally, specify the tenant-id or tenant login
az login # --tenant <tenant>.onmicrosoft.com
```

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

To simplify doc generation, this directory makes use of [terraform-docs](https://terraform-docs.io/). To generate docs for new modules or
re-generate docs for existing modules, run the following command from the root of this repository:

```sh
update-all-terraform-docs.sh
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
