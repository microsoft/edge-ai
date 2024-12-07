# Overview

This folder contains the IaC configuration for deploying an Azure Arc Connected K3s Kubernetes cluster on a single Azure Virtual Machine.

- [terraform](./terraform/README.md) - Terraform configuration

## Generating docs for modules

To simplify doc generation, this directory makes use of [terraform-docs](https://terraform-docs.io/). To generate docs for new modules or re-generate docs for existing modules, run the following command from the `terraform` directory:

```sh
terraform-docs .
```

This generates docs based on the configuration defined in `terraform/.terraform-docs.yml`
