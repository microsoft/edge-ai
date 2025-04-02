# Configuring Azure Pipelines & CI/CD for this Repository

This repository can be cloned and used as the base image for an IaC repo with
integrated CI/CD. There is minimal configuration required to enable the pipelines,
though fully automated, IaC-based setup is under design/construction.

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
- All pipeline components should be templatized for reuse and consistency
- Pipeline templates should be modular and parameterized for flexibility and reuse

## Build Feature Sets

The build pipeline provides several key features, with more on the way:

- Checks Terraform Provider versions for update opportunities and publishes build warning
- Runs a lightweight vulnerability scan for all dependant packages
- Runs file linting on a wide variety of languages and file types using the MegaLinter template
- Performs a matrix build on only resources that have been modified in the current PR
- Publishes Terraform Plans for all changed resources within the current PR
- Runs unit tests on changed Terraform within the current PR
- Provides modular, templatized pipeline components for flexible pipeline creation
- Ensures consistent validation steps across all pipelines through shared templates
- Enables PR comment integration for linting results through the MegaLinter Azure Reporter
- Optimizes pipeline performance with intelligent caching mechanisms

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

### Templatized Build System

This repository implements a modular, templatized approach to pipeline definitions. Instead of monolithic pipeline files, we break down common tasks into reusable templates that can be combined in different ways. This approach provides several benefits:

1. **Consistency**: Ensures the same validation steps are applied across all pipelines
2. **Maintainability**: Changes to a pipeline component only need to be made in one place
3. **Reusability**: Common tasks can be easily reused across different pipelines and copied/referenced for additional projects
4. **Flexibility**: Templates can be parameterized for different scenarios

#### Available Templates

The following templates are available in the `.azdo` directory:

| Template                                     | Purpose                                                                                              | Documentation                                                                   |
|----------------------------------------------|------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `aio-version-checker-template.yml`           | Checks Azure IoT Operations component versions against latest available releases                     | [Template Documentation](./templates/aio-version-checker-template.md)           |
| `cluster-test-terraform-template.yml`        | Runs Terraform init, validate, plan and tests on component folders                                   | [Template Documentation](./templates/cluster-test-terraform-template.md)        |
| `docs-check-terraform-template.yml`          | Validates documentation quality including Terraform docs and URL checks                              | [Template Documentation](./templates/docs-check-terraform-template.md)          |
| `matrix-folder-check-template.yml`           | Checks for changes in source directories and creates a dynamic matrix of folders for downstream jobs | [Template Documentation](./templates/matrix-folder-check-template.md)           |
| `megalinter-template.yml`                    | Provides linting capabilities across multiple languages                                              | [Template Documentation](./templates/megalinter-template.md)                    |
| `resource-provider-pwsh-tests-template.yml`  | Runs tests to ensure resource provider registration scripts function as expected                     | [Template Documentation](./templates/resource-provider-pwsh-tests-template.md)  |
| `variable-compliance-terraform-template.yml` | Ensures consistent Terraform variable definitions across modules                                     | [Template Documentation](./templates/variable-compliance-terraform-template.md) |
| `wiki-update-template.yml`                   | Updates Azure DevOps wiki with markdown documentation from the repository                            | [Template Documentation](./templates/wiki-update-template.md)                   |

> **Note:** All template documentation follows a standardized format that includes overview,
> features, parameters, usage examples, implementation details, and troubleshooting sections.
> This consistent structure makes it easier to learn and use the templates effectively.

#### Documentation Template

To maintain consistency across all pipeline template documentation, this repository includes a standardized documentation template file: `docs/templates/function-name-template.md.template`. This file serves several important purposes:

- Provides a uniform structure for all template documentation
- Ensures comprehensive coverage of essential information (parameters, outputs, examples, etc.)
- Makes it easier for new team members to understand how pipeline templates work
- Helps GitHub Copilot generate properly formatted documentation when assisting with updates

When creating documentation for a new template or updating existing template documentation:

1. Use the `function-name-template.md.template` as a starting point
2. Replace the placeholder content with information specific to your template
3. Maintain the standardized formatting, especially for parameters and outputs tables
4. Include all relevant sections (Overview, Features, Parameters, Outputs, etc.)

This standardized approach significantly improves documentation quality and helps users find the information they need quickly and consistently across all templates.

#### How to Use Templates

Templates can be included in your pipeline definition using the `template` keyword:

```yaml
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/megalinter-template.yml
        parameters:
          displayName: 'Lint Code'
          enableAzureReporter: true
```

#### Advanced MegaLinter Template Usage

```yaml
# Advanced configuration of the MegaLinter template
- template: .azdo/templates/megalinter-template.yml
  parameters:
    displayName: 'Comprehensive Code Quality Analysis'
    dependsOn:
      - SecurityScan
      - DependencyScan
    condition: and(succeeded('SecurityScan'), succeeded('DependencyScan'))
    megalinterCachePath: '$(Build.ArtifactStagingDirectory)/megalinter-cache'
    enableAzureReporter: ${{ eq(variables['Build.Reason'], 'PullRequest') }}
    pullRequestId: $(System.PullRequest.PullRequestId)
    sourceRepoUri: $(System.PullRequest.SourceRepositoryURI)
```

This advanced configuration:

- Provides a custom display name for better pipeline readability
- Sets multiple job dependencies with an array
- Uses a more complex condition checking across multiple jobs
- Specifies a custom cache path in the build artifact staging directory
- Dynamically enables the Azure reporter only for pull requests
- Passes required PR information for commenting

#### Combining Multiple Templates

You can also combine multiple templates for a complete CI/CD workflow:

```yaml
jobs:
  - template: .azdo/templates/megalinter-template.yml
    parameters:
      # MegaLinter parameters...

  - template: .azdo/templates/resource-provider-pwsh-tests-template.yml
    parameters:
      dependsOn: MegaLinter
      # Resource Provider test parameters...

  - template: .azdo/templates/wiki-update-template.yml
    parameters:
      dependsOn: [MegaLinter, ResourceProviderShellScriptTest]
      # Wiki update parameters...
```

### Required Pipeline Variables

The following variables are required/optional to run this repository's main pipeline.
Please see, [Set variables in pipeline](https://learn.microsoft.com/azure/devops/pipelines/process/variables?view=azure-devops&tabs=classic%2Cbatch#set-variables-in-pipeline) for this process.

| variable                              | secret | suggested value            | details                                                                                                                                                                                                             |
|:--------------------------------------|:------:|:---------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `subscription_id`                     |   Y    | Azure subscription GUID    |                                                                                                                                                                                                                     |
| `TF_VAR_CUSTOM_LOCATIONS_OID`         |   Y    | OID of Arc Custom Location | [Create and manage custom locations on Azure Arc-enabled Kubernetes](https://learn.microsoft.com/azure/azure-arc/kubernetes/custom-locations)                                                                       |
| `TF_VAR_ENVIRONMENT`                  |   N    | `prod`                     | e.g. `dev`, `stage`, `prod`                                                                                                                                                                                         |
| `TF_VAR_EXISTING_RESOURCE_GROUP_NAME` |   N    | `build_system`             | useful for integration environments                                                                                                                                                                                 |
| `TF_VAR_LOCATION`                     |   N    | `westus`                   | [Azure region](https://azure.microsoft.com/explore/global-infrastructure/geographies/) to deploy to                                                                                                                 |
| `TF_VAR_RESOURCE_PREFIX`              |   N    | `build`                    | prefix for all created resources                                                                                                                                                                                    |
| `TF_VAR_VM_SKU_SIZE`                  |   N    | `Standard_D8s_v3`          | [VM Size](https://learn.microsoft.com/azure/virtual-machines/sizes/overview?tabs=breakdownseries%2Cgeneralsizelist%2Ccomputesizelist%2Cmemorysizelist%2Cstoragesizelist%2Cgpusizelist%2Cfpgasizelist%2Chpcsizelist) |
| `TF_VAR_VM_USERNAME`                  |   Y    | VM admin user name         |                                                                                                                                                                                                                     |
