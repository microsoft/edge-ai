# Introduction

[![Build Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_apis/build/status%2FIaC%20for%20the%20Edge?branchName=main)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_build/latest?definitionId=3&branchName=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Board Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/8567de21-1286-4352-a375-efb89ad55348/_apis/work/boardbadge/fd9375f1-e7c6-4439-b2c9-6969d853a2d4)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/_boards/board/t/8567de21-1286-4352-a375-efb89ad55348/Stories/)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/edge-ai)

Implementing an Adaptive Cloud approach requires great tooling; we're excited to introduce the "IaC for the
Edge" project, our next generation Infrastructure as Code solution designed specifically for systems spanning
edge and cloud. This project encodes a decade of experience harvesting petabytes of edge telemetry and
extending the power and capabilites of Azure, to the edge. This project is just the first step in enabling our
_Edge AI Accelerator_, a suite of IaC, tools, and applications for designing, engineering, and deploying
edge AI solutions that are resilient, scalable, and maintainable.

It takes a wide variety of teams, roles, and responsibilities to develop cloud-enabled edge computing
solutions. There are physical plant IT teams responsible for hardware at the edge, and enterprise IT
responsible for cloud infrastructure. There are teams managing cloud data estates, and specialist
teams managing physical plant data systems. There are Data Science teams that need to process
telemetry across edge and cloud and need to view both environments as a unified whole. This project is built to
address the needs of all stakeholders, and will accelerate POCs to production, with the flexibility to
tackle the increasing complexity of delivering business value from edge data.

## Production Ready Edge IaC Acceleration

The primary objective of this repository is to provide production ready IaC for scale Edge AI solutions. This
repository provides Terraform for building edge and cloud infrastructure, with a Bicep implementation on the roadmap
for delivery in Q2 CY2025.

If you are in need of Quickstarts for Azure IoT Operations or example implementations, they can be found in official
Azure documentation:

- [Azure IoT Operations - Quickstart](https://learn.microsoft.com/azure/iot-operations/get-started-end-to-end-sample/quickstart-deploy)
- [Azure IoT Operations (AIO) documentation](https://learn.microsoft.com/azure/iot-operations/overview-iot-operations)
- [Azure Arc Jumpstart Agora Manufacturing Scenario](https://azurearcjumpstart.com/azure_jumpstart_ag/contoso_motors#overview).

## Quick Getting Started on Existing Developer Environments

Check out the
project's [wiki](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/edge-ai/_wiki/wikis/Edge%20AI/5/), or after
cloning the repository, open a
Copilot chat and ask `@workspace What should I know before I use this repository?`

Then, get started bootstrapping Arc-enabled AIO environments:

1. [Cloning this repository locally](https://learn.microsoft.com/azure/devops/repos/git/clone?view=azure-devops&tabs=visual-studio-2022#get-the-clone-url-of-an-azure-repos-git-repo)
2. Use [this project's integrated dev container](./.devcontainer/README.md).
3. Login with Azure CLI and set your subscription context.
4. From a terminal:
    1. `cd ./src/azure-resource-providers`
    2. Run `./register-azure-providers.sh <providers-file>` to prepare your subscription
5. Follow instructions in the [./src/azure-resource-providers/README](./src/azure-resource-providers/README.md) to
   register the required Azure resource providers for AIO and Arc in your subscription.
6. Deploy the IaC:
    1. Select a _blueprint_ from the [blueprints](./blueprints/README.md) directory.
    2. Ask Copilot to guide you through blueprint deployment (see below) or follow the deployment instructions located in
        the root blueprint folder.

**Optionally**, this repository includes scripts to individually deploy each and every component. Follow the
instructions located at [./src/README.md](./src/README.md) for details.

**✨ GitHub Copilot Agent-assisted deployment (experimental)**: Open Copilot, switch to the 'Edit' Tab, and to 'Agent'
mode. Then ask `Deploy this solution` to be guided through the setup in your subscription. (Copilot will use the README
and extra prompting in this repo to run the deployment steps listed above.)

### Video Demonstration

[See our demonstration of using IaC for Edge on your next project](https://microsoft-my.sharepoint.com/:v:/p/allengreaves/ERH-llkJDNdAoPNnGciRIVcBUmuCON1lkx3zfaXgDthX8g?e=oRRx8f)

## Getting Started and Prerequisites Setup

This sections provides a _How-To_ guide on getting started with Edge-AI.

### Environment Setup Guide

#### Option 1: Using Dev Container 🚀 (highly recommended)

The simplest way to get started is using our pre-configured development container:

1. **Install Prerequisites**
   - [VS Code](https://code.visualstudio.com/) or [VS Code Insiders for using experimental Copilot features](https://code.visualstudio.com/insiders/)
   - [VS Code Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - [GitHub Copilot Extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) (requires subscription)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop/)

    **Docker System Requirements**

    Ensure your local Docker installation has adequate resources allocated:

    | Resource | Minimum Requirement | Recommended        |
    |----------|---------------------|--------------------|
    | CPU      | 4 cores             | 8+ cores           |
    | RAM      | 8 GB                | 16+ GB             |
    | Storage  | 50 GB free space    | 100+ GB free space |

2. **Clone this repository to your local machine**

   ```bash
   git clone https://ai-at-the-edge-flagship-accelerator@dev.azure.com/ai-at-the-edge-flagship-accelerator/edge-ai/_git/edge-ai
   cd edge-ai
   ```

3. **Open the Repository in VS Code**

   - Open the cloned repository in VS Code Insiders

   ```bash
   code-insiders .
   # Or VS Code GA version:
   code .
   ```

   - Click the popup to "Reopen in Container". If the popup doesn't appear, press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac) and select "Dev Containers: Reopen in Container"
   - The container will automatically install all required tools and dependencies
   - For any issues with Dev Container setup, refer to the [official documentation](https://code.visualstudio.com/docs/devcontainers/containers) for Dev Containers in VS Code

#### Option 2: Configure Your Own Environment

If you prefer not to use the Dev Container, make sure you have a Linux environment set up.

> **For Windows Users Only:**
> If you are using Windows, we recommend using the Windows Subsystem for Linux (WSL 2) to run the scripts and any IaC commands. This is because some of the scripts and commands require a Bash terminal and WSL 2 offers this functionality.
>
> - **Install WSL 2:**
>   Follow the [official WSL installation guide](https://docs.microsoft.com/windows/wsl/install)
>
> - **Choose a Linux Distribution:**
>   We recommend using Ubuntu as your Linux distribution

1. **Install Required Tools and Prerequisites**
   - [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli), ensure you have the latest version
   - Bicep CLI is included as part of Azure CLI. To upgrade to the latest version [Bicep tools with Azure CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
   - [Azure CLI extensions](https://learn.microsoft.com/cli/azure/azure-cli-extensions-overview) `amg`, `azure-iot-ops`, `connectedk8s`, `k8s-extension`
   - [Terraform](https://developer.hashicorp.com/terraform/install)
   - [Git](https://git-scm.com/downloads)
   - CLI tools for Kubernetes (`kubectl`, `helm`)
   - You might also need to manually install some of the VS Code extensions, please review the selection of extensions under `customizations.extensions` in
   `.devcontainer/devcontainer.json` and install them in your local VS Code instance
   - To run some of the linting or build scripts you may need to install Node.js, NPM, Python and PowerShell

### Quick Start Deployment Guide

1. **Azure CLI Authentication**

   ```bash
   # Login to Azure CLI, selecting the correct tenant if needed
   az login --tenant your-tenant-id.onmicrosoft.com

   # Set the subscription context
   # If you have multiple subscriptions the command will prompt you to select the subscription for your context
   # To set it manually:
   az account set --subscription "your-subscription-name-or-id"
   ```

2. **Register Required Azure Resource Providers**
   **IMPORTANT**: These scripts need to be run once per subscription to ensure all necessary provider services are available

   ```bash
   # Navigate to resource providers directory
   cd ./src/azure-resource-providers

   # Register all required providers
   ./register-azure-providers.sh azure-providers.txt
   ```

3. **Blueprint Initialization for Terraform**

   ```bash
   # Navigate to your chosen blueprint directory
   cd ./blueprints/full-single-node-cluster

   # Set required environment variable for Terraform
   export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

   # Create terraform.tfvars file with required parameters
   cat > terraform.tfvars << EOF
   environment     = "dev"
   resource_prefix = "myproject"
   location        = "eastus2"
   instance        = "001"
   EOF

4. **Terraform Deployment**

   ```bash
   # Initialize and apply Terraform
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

### GitHub Copilot for Assistance

Use these Copilot prompts to get help throughout your deployment:

1. For environment setup help:

   ```text
   I'm new to this repository and need to set up my development environment.
   Can you walk me through setting up VS Code, Docker, and the dev container?
   ```

2. For Azure CLI configuration:

   ```text
   I need to configure Azure CLI to access my tenant and subscription.
   Please guide me through the steps.
   ```

3. For blueprint deployment:

   ```text
   I want to deploy the full-single-node-cluster blueprint.
   Can you help me create the terraform.tfvars file and run the necessary commands?
   ```

4. For troubleshooting help:

   ```text
   I'm getting an error when running terraform apply.
   Can you help me understand what's happening and how to fix it?
   ```

## ADR Library

See and evaluate the decision records various teams have made when building cloud-enabled edge computing system,
using our [Architectural Decision Record Library](./docs/solution-adr-library/README.md).

## Technical Paper Library

Learn about key architectural approaches or find introductions to key edge technologies in our
[Technical Paper Library](./docs/solution-technology-paper-library/README.md).

## Using Copilot to explore the repository

This project includes comprehensive documentation and tooling to optimize your experience with GitHub Copilot. We've
invested in making the repository Copilot-friendly through structured documentation, prompt files, and best practices.

### Quick exploration with @workspace

You can use Copilot to easily explore this repository with `@workspace` queries. Here are a few prompts to get you
started:

- `@workspace Where is the terraform code for the event grid deployment?`
- `@workspace Is there a script in this repository that can help me check my terraform provider version numbers?`
- `@workspace Does this repository include an observability solution?`
- `@workspace Does this repository include UAMI for any of its resources?`

If you encounter friction with `@workspace` questions to Copilot, please file an issue with your prompt and what you
hoped Copilot would return you.

### Advanced Copilot usage

For developers and contributors who want to leverage GitHub Copilot more effectively with this repository:

- [AI-Assisted Engineering Guide](./docs/ai-assisted-engineering.md) - A comprehensive guide to all resources in this
  project that enhance Copilot's capabilities, including contextual and reusable prompt files, documentation structures,
  and real-world examples.

## The Details

### Composable IaC

This project is a composable library of fine-grained, production ready IaC that can be easily layered to fit
nearly any operational model, from small, single machine systems, to orchestrated, globally-distributed solutions.
The project uses a decimal system to organize IaC, scripts, and supplementary resources, which can be collated in a
myriad of ways to meet operational requirements. Refer to [blueprints](./blueprints) for example "full scenario" level
deployments, to help build your understanding and knowledge of how best to leverage this repository.

#### Components

Components for this composable architecture are located under the [src](./src) directory of this repository. Each
component is organized as a separate module that can be used individually, duplicated to where it's required, or
pulled in as a dependency.

Each component directory includes the different forms of IaC that's supported as folders, e.g. Terraform and Bicep.
Additionally, a `ci` directory is included for verification and deployment within this repository's build
system. This directory can also be referenced as an example for a straightforward deployment, typically only including
default variables and assumes that prior requirements have been deployed from other component directories.

The components are organized into categories based on their purpose and deployment location:

##### Cloud Infrastructure (000-cloud)

| Folder                                                                   | Description                                                                                   |
|--------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [000-resource-group](./src/000-cloud/000-resource-group/README.md)       | Resource Groups for all Azure resources                                                       |
| [010-security-identity](./src/000-cloud/010-security-identity/README.md) | Identity and security resources including Key Vault, Managed Identities, and role assignments |
| [020-observability](./src/000-cloud/020-observability/README.md)         | Cloud-side monitoring and observability resources                                             |
| [030-data](./src/000-cloud/030-data/README.md)                           | Data storage and Schema Registry resources                                                    |
| [031-fabric](./src/000-cloud/031-fabric/README.md)                       | Microsoft Fabric resources for data warehousing and analytics                                 |
| [040-messaging](./src/000-cloud/040-messaging/README.md)                 | Event Grid, Event Hubs, Service Bus and messaging resources                                   |
| [050-vm-host](./src/000-cloud/050-vm-host/README.md)                     | VM provisioning resources with configurable host operating system                             |

##### Edge Infrastructure (100-edge)

| Folder                                                          | Description                                                                                                                                                                  |
|-----------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [100-cncf-cluster](./src/100-edge/100-cncf-cluster/README.md)   | Installation of a CNCF cluster that is AIO compatible (initially limited to K3s) and Arc enablement of target clusters, workload identity                                    |
| [110-iot-ops](./src/100-edge/110-iot-ops/README.md)             | AIO deployment of core infrastructure components (MQ Broker, Edge Storage Accelerator, Secrets Sync Controller, Workload Identity Federation, OpenTelemetry Collector, etc.) |
| [120-observability](./src/100-edge/120-observability/README.md) | Edge-specific observability components and monitoring tools                                                                                                                  |
| [130-messaging](./src/100-edge/130-messaging/README.md)         | Edge messaging components and data routing capabilities                                                                                                                      |

##### Applications & Samples

| Folder                                                                                                     | Description                                                                                                                                    |
|------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| [500-application](./src/500-application/README.md)                                                         | Custom workloads and applications, including a basic Inference Pipeline, TIG/TICK stacks, InfluxDB Data Historian, reference data backup, etc. |
| [900-tools-utilities](./src/900-tools-utilities/README.md)                                                 | Utility scripts, tools, and supporting resources for edge deployments                                                                          |
| [samples/dataflows-acsa-egmqtt-bidirectional](./src/samples/dataflows-acsa-egmqtt-bidirectional/README.md) | Sample that provides assets with Azure IoT Operations Dataflows and supported infrastructure creation                                          |
| [azure-resource-providers](./src/azure-resource-providers/README.md)                                       | Scripts to register required Azure resource providers for AIO and Arc in your subscription                                                     |

### Using this project

This project can be used in two primary ways: 1) running the projects IaC and/or blueprints directly to bootstrap
environments such as labs, cloud-hosted development environments, integration/QA environments, or small
production deployments; or 2) cloning the repository and all its automation to have and out-of-the-box CI/CD
solution for your IaC. Feel free to pick and choose which components are needed or necessary to help start or
extend your project.

For running the IaC to bootstrap environments, please refer to the [Quick Getting Started](#quick-getting-started-on-existing-developer-environments)
documentation. For using this repository and its automation to have a complete CI/CD system for your
IaC, please review the [build pipelines ReadMe](./.azdo/README.md) and reach out to the
[Microsoft ISE Edge Computing Technical Domain team](mailto:ectd@microsoft.com) if you need support.

### Supported Features

The Terraform, scripts, and documentation in this repository can provide you the following features and capabilities:

- Subscription resources supporting all "in-the-box" components of an Azure IoT Operations (AIO) solution
- Deployment of a cloud-hosted VM, sized and provisioned specifically for developing AIO solutions
- Deployment of a development-ready K3s cluster with all the basic AIO components installed
- [Integrated support for Azure Managed Identities](./src/000-cloud/050-vm-host/terraform/README.md)
- [Integrated support for "Bring-Your-Own" certificates](./src/100-edge/110-iot-ops/terraform/README.md#create_resources) (and
  intermediate certificates) for intra-cluster TLS
- [A robust, matrix'ed IaC build system](./azure-pipelines.yml) with integrated testing and validation, to ensure your
  IaC deploys as you expect it to
- Auto-validation and auto-generation of Terraform Plans to support expedited CISO/Security/DevOps team approvals
- [A library of common "Architectural Decision Records" (ADRs)](./docs/solution-adr-library/README.md), ready to be
  modified to document your solution's requirements and the decisions you've made along the way
- [A library of technology papers](./docs/solution-technology-paper-library/README.md) to upskill your peers
- [A well-stocked development container](./.devcontainer) for you to take the IaC for your "AI on the Edge Solutions" to
  production with confidence, repeatability, and reliability your organization deserves
- [Blueprints](./blueprints) full scenario deployments that demonstrate how components are composed together

### Contribute

Before contributing, please review the project's [Code of Conduct](./CODE_OF_CONDUCT.md).

Users and project developers can contribute to make this solution better in several ways:

- [Review the project's Contributing doc](./CONTRIBUTING.md)
- [Contribute an ADR](./docs/solution-adr-library/README.md#contribute) from your engagement
- [Contribute a Security Plan](./docs/solution-security-plan-library/README.md#contribute) from your engagement
- Pick up from the backlog
  a [#GoodFirstIssue or a #GoodFirstStory](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_queries/query/?tempQueryId=a44d85ba-bc5b-43fc-954d-78e15bc8f68f)
  and help move this accelerator forward

#### Build and Test

We recommend using the project's [dev container](./.devcontainer/README.md) for all contribution work.

Start orienting yourself with this repository by referring to [blueprints](./blueprints/README.md) for your first
deployment.

Pull requests made to the repository go through a thorough build process including linting, testing, and
in some cases deployment validation. After raising a PR, the build process with begin evaluating your
contribution. If errors arise from the build, please attend to them as soon as you can.

The project includes a [package.json script set](./package.json) that can be quite useful in development, and is worth a
review.

#### ADR Process

Design decisions for project direction, feature or capability implementation, and community decisions
happen through an Architecture Decision Record (ADR) process. ADRs can be drafted by any project community
member for consideration first by project leads, and secondarily by the project's community. Final ADR
acceptance is performed via sign-off from 3/5ths of the project's leads defined by auto-injected build reviewer groups.

ADRs move through a process that includes the following states:

- Draft - for all ADRs under development and in a drafting phase. May be committed to the main branch directly by
  project leads, but must be done via branches for community members
- Proposed - for all ADRs that have been reviewed by the ADR sign-off team (project leads), this phase indicates the ADR
  is now open for discussion amongst the broad project community for feedback.
- Accepted - for all ADRs that have completed the community RFC process. ADRs in this state have been ratified/accepted
  by the project community and may move to implementation.
- Deprecated - for all ADRs that are no longer relevant to the solution or have been superseded by more comprehensive
  ADRs; this is inclusive of retired components or features, but will be retained in perpetuity for historical context.

Please see [ADR README](./project-adrs/README.MD) for a more detailed explanation of the ADR process flow and how to
author and progress your ideas for this project, through to implementation.

## Trademark Notice

> This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
> trademarks or
> logos is subject to and must follow Microsoft’s Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in
> modified
> versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or
> logos
> are subject to those third-party’s policies.
