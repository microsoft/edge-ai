# Source Code Structure

1. [`./rp_enablement`](rp_enablement/README.md) - scripts to set up required resource providers in your subscription.
2. [`./cluster_install](cluster_install/README.md) - Terraform modules to install an edge cluster in an Azure VM with an Azure IoT Operations deployment.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- Azure subscription

Login to Azure CLI using the below command:

```bash
# Login to Azure CLI, optionally specify the tenant-id
az login # --tenant <tenant-id>
```
