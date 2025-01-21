# Source Code Structure

1. [`./000_rp_enablement`](000_rp_enablement/README.md) - recommended scripts to set up required resource providers in target subscription.
2. [`./010_cluster_install`](010_cluster_install/README.md) - Terraform modules to install an edge cluster in an Azure VM and connect the VM to Azure Arc.
3. [`./020_aio_install`](020_aio_install/README.md) - Terraform modules to install Azure IoT Operations on an Azure Arc connected cluster.

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
terraform-docs .
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
