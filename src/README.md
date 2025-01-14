# Source Code Structure

1. [`./000_rp_enablement`](000_rp_enablement/README.md) - scripts to set up required resource providers in your subscription.
2. [`./010_cluster_install](010_cluster_install/README.md) - Terraform modules to install an edge cluster in an Azure VM and connect it to Azure Arc.
3. [`./020_aio_install`](020_aio_install/README.md) - Terraform modules to install Azure IoT Operations deployment on an Azure Arc connected cluster.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- Azure subscription

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
