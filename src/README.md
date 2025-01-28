# Source Code Structure

1. [(000)](./000-subscription/README.md) Run-once scripts for Arc & AIO resource provider enablement in subscriptions, if necessary
2. [(005)](./005-onboard-reqs/README.md) Resource Groups, Site Management (optional), Role assignments/permissions for Arc onboarding
3. [(010)](./010-vm-host/README.md) VM/host provisioning, with configurable host operating system (initially limited to Ubuntu)
4. [(020)](./020-cncf-cluster/README.md) Installation of a CNCF cluster that is AIO compatible (initially limited to K3s) and Arc enablement of target clusters, workload identity
5. [(030)](./030-iot-ops-cloud-reqs/README.md) Cloud resource provisioning for Azure Key Vault, Storage Accounts, Schema Registry, Container Registry, and User Assigned Managed Identity
6. [(040)](./040-iot-ops/README.md) AIO deployment of core infrastructure components (MQ Broker, Edge Storage Accelerator, Secrets Sync Controller, Workload Identity Federation, OpenTelemetry Collector, OPC UA Simulator)
7. [(050)](./050-messaging/README.md) Cloud resource provisioning for cloud communication (MQTT protocol head for Event Grid (topic spaces, topics and cert-based authentication), Event Hubs, Service Bus, Relay, etc.)
8. (060) Cloud resource provisioning for data/event storage (Fabric by means of RTI, Data Lakes, Warehouses, etc.)
9. (070) Cloud resource provisioning for Azure Monitor and Container Insights
10. (080) AIO deployment of additionally selected components (OTEL Collector (Phase 2), OPC UA, AKRI, Strato, FluxCD/Argo)
11. (090) Customer defined custom workloads, and pre-built solution accelerators such as TIG/TICK stacks, InfluxDB Data Historian, reference data backup from cloud to edge, etc.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- An Azure subscription
- [Visual Studio Code](https://code.visualstudio.com/)
- A Linux-based development environment or a [Windows system with WSL](https://code.visualstudio.com/docs/remote/wsl)

> NOTE: We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly particularly with Windows-bases systems.

Login to Azure CLI using the below command:

```bash
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```

## Generating docs for modules

To simplify doc generation, this directory makes use of [terraform-docs](https://terraform-docs.io/). To generate docs for new modules or re-generate docs for existing modules, run the following command from the `terraform` directory:

```sh
update-all-terraform-docs.sh
```

This generates docs based on the configuration defined in `terraform/.terraform-docs.yml`

## Testing

Each Terraform module within the sub-folders of the `./src` directory include Terraform tests. These tests can be run from the command line, assuming you have logged into the Azure CLI, and selected a target subscription.

```sh
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
terraform test 
```

Optionally, to test passing the pre-fetched value for
[OID for Azure Arc Custom Locations](https://learn.microsoft.com/azure/azure-arc/kubernetes/custom-locations#to-enable-the-custom-locations-feature-with-a-service-principal-follow-the-steps-below),
use the command:

```sh
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
terraform test -var custom_locations_oid=$(TF_VAR_CUSTOM_LOCATIONS_OID)
```
