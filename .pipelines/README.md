# Configuring Azure Pipelines & CI/CD for this Repository

This repository can be cloned and used as the base image for an IaC repo with
integrated CI/CD. There is minimal configuration required to enable the pipelines,
though fully automated setup is under design.

## Engineering Principles

This project follows a set of guiding principles for all development and
automation:

- All IaC goes through a validation process on commit
- All IaC dependencies are monitored for outdated packages
- A reasonable effort will be made to test all IaC
- All Iac changes can be easily checked against
  - empty environments
  - QA and Integration Environments
  - Pre-production environments, and
  - Production Environments
- All IaC changes will produce detailed deployment plans for security reviews
- All IaC changes will use a decimal system for process organization
- All build processes will be built on each pull request
- Key build processes will be run on each merge to main

## Getting Started

The following sections will walk you through the process of configuring Azure
pipelines for this repository.

### Create Managed Identity

Default practices for establishing service connections between Azure Pipelines
and an Azure subscription is through the use of Managed Identity. Please follow
the Azure documentation for creating a [User Assigned Managed Identity](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp)
in your subscription, before proceeding. We recommend using contributor rights
until further, fine-grained access guidance is added to this repository. Please
also familiarize yourself with the [numerous identity options for Azure Pipelines](https://learn.microsoft.com/azure/devops/integrate/get-started/authentication/service-principal-managed-identity?view=azure-devops#option-1-create-an-application-service-principal).

### Optional: Service Principal for Azure Pipelines to Azure Service Connections

In some instances, Managed Identity may not be an option for configuring your pipelines.
This frequently occurs where a target Azure subscription is not in the same tenant as
the Azure Pipelines/DevOps instance, or where your account does not have authorization to
modify the subscription tenant with new Roles or Applications. If that is the case,
we recommend [creating a service principal](https://learn.microsoft.com/cli/azure/azure-cli-sp-tutorial-1?tabs=bash)
for establishing the service connection.

### Create Azure Pipelines Service Connection

Follow the Azure Pipelines documentation for creating a
[User Assigned Managed Identity Service Connection](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops).

### Required Pipeline Variables

The following variables are required to run this repository's main pipeline.
Please see, [Set variables in pipeline](https://learn.microsoft.com/azure/devops/pipelines/process/variables?view=azure-devops&tabs=classic%2Cbatch#set-variables-in-pipeline) for this process.

| variable                              | secret | suggested value            | details                                                                                                                                                                                                             |
|-:-------------------------------------|-:-:----|-:--------------------------|-:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `subscription_id`                     | Y      | Azure subscription GUID    |                                                                                                                                                                                                                     |
| `TF_VAR_CUSTOM_LOCATIONS_OID`         | Y      | OID of Arc Custom Location | [Create and manage custom locations on Azure Arc-enabled Kubernetes](https://learn.microsoft.com/azure/azure-arc/kubernetes/custom-locations)                                                                       |
| `TF_VAR_ENVIRONMENT`                  | N      | `prod`                     | e.g. `dev`, `stage`, `prod`                                                                                                                                                                                         |
| `TF_VAR_EXISTING_RESOURCE_GROUP_NAME` | N      | `build_system`             | useful for integration environments                                                                                                                                                                                 |
| `TF_VAR_LOCATION`                     | N      | `westus`                   | [Azure region](https://azure.microsoft.com/explore/global-infrastructure/geographies/) to deploy to                                                                                                                 |
| `TF_VAR_RESOURCE_PREFIX`              | N      | `build`                    | prefix for all created resources                                                                                                                                                                                    |
| `TF_VAR_VM_SKU_SIZE`                  | N      | `Standard_D8s_v3`          | [VM Size](https://learn.microsoft.com/azure/virtual-machines/sizes/overview?tabs=breakdownseries%2Cgeneralsizelist%2Ccomputesizelist%2Cmemorysizelist%2Cstoragesizelist%2Cgpusizelist%2Cfpgasizelist%2Chpcsizelist) |
| `TF_VAR_VM_USERNAME`                  | Y      | VM admin user name         |                                                                                                                                                                                                                     |

## Build Feature Sets

The build pipeline provides several key features, with more on the way:

- Checks Terraform Provider versions for update opportunities and publishes build warning
- Runs a lightweight vulnerability scan for all dependant packages
- Runs file linting on a wide variety of languages and file types
- Performs a matrix build on only resources that have been modified in the current PR
- Publishes Terraform Plans for all changed resources within the current PR
- Runs unit tests on changed Terraform within the current PR
