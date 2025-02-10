# Introduction

[![Build Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_apis/build/status%2FIaC%20for%20the%20Edge?branchName=main)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_build/latest?definitionId=3&branchName=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Board Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/8567de21-1286-4352-a375-efb89ad55348/_apis/work/boardbadge/fd9375f1-e7c6-4439-b2c9-6969d853a2d4)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/_boards/board/t/8567de21-1286-4352-a375-efb89ad55348/Stories/)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/IaC%20for%20the%20Edge)

Implementing an Adaptive Cloud approach requires great tooling; we're excited to introduce the "IaC for the
Edge" project, our next generation Infrastructure as Code solution designed specifically for systems spanning
edge and cloud. This project encodes a decade of experience harvesting petabytes of edge telemetry and
extending the power and capabilites of Azure, to the edge. This project is just the first step in enabling our
*Edge AI Accelerator*, a suite of IaC, tools, and applications for designing, engineering, and deploying
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

If you are in need of Quickstarts for Azure IoT Operations or example implementations, they  can be found in official
Azure documentation:

- [Azure IoT Operations - Quickstart](https://learn.microsoft.com/en-us/azure/iot-operations/get-started-end-to-end-sample/quickstart-deploy)
- [Azure IoT Operations (AIO) documentation](https://learn.microsoft.com/en-us/azure/iot-operations/overview-iot-operations)
- [Azure Arc Jumpstart Agora Manufacturing Scenario](https://azurearcjumpstart.com/azure_jumpstart_ag/contoso_motors#overview).

## Getting Started

While enhanced documentation is under development, please start by reviewing this
project's [wiki](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_wiki/wikis/Edge%20AI/5/)

before you use the IaC (Terraform) in this repository. Then, get started bootstrapping Arc-enabled AIO environments:

1. [Cloning this repository locally](https://learn.microsoft.com/en-us/azure/devops/repos/git/clone?view=azure-devops&tabs=visual-studio-2022#get-the-clone-url-of-an-azure-repos-git-repo)
2. [Install pre-requisites](./src/README.md#prerequisites) or use [this project's integrated dev container](./.devcontainer/README.md).
3. Login to the Azure Portal.
4. From a terminal:
    - `cd ./src/000-subscription`
    - Run `./register-azure-providers.sh` to prepare your subscription
    - Follow instructions in the [./src/005-onboarding-reqs README](./src/005-onboard-reqs/README.md)
    - Deploy the IaC:
      - Select a `full-*` *blueprint* from the [blueprints](./blueprints) directory and follow deployment instructions
        located in those folders.

**Optionally**, this repository includes scripts to individually deploy each and every component. Follow the
instructions located at [./src/README.md](./src/README.md) for details.

### Video Demonstration

[See our demonstration of using IaC for Edge on your next project](https://microsoft-my.sharepoint.com/:v:/p/allengreaves/ERH-llkJDNdAoPNnGciRIVcBUmuCON1lkx3zfaXgDthX8g?e=oRRx8f)

## ADR Library

See and evaluate the decision records various teams have made when building cloud-enabled edge computing system,
using our [Architectural Decision Record Library](./docs/solution-adr-library/README.md).

## Technical Paper Library

Learn about key architectural approaches or find introductions to key edge technologies in our
[Technical Paper Library](./docs/solution-technology-paper-library/README.md).

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

| Folder                                                      | Description                                                                                                                                                                              |
|-------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [000-subscription](./src/000-subscription/README.md)        | Run-once scripts for Arc & AIO resource provider enablement in subscriptions, if necessary                                                                                               |
| [005-onboard-reqs](./src/005-onboard-reqs/README.md)        | Resource Groups, Site Management (optional), Role assignments/permissions for Arc onboarding                                                                                             |
| [010-vm-host](./src/010-vm-host/README.md)                  | VM/host provisioning, with configurable host operating system (initially limited to Ubuntu)                                                                                              |
| [020-cncf-cluster](./src/020-cncf-cluster/README.md)        | Installation of a CNCF cluster that is AIO compatible (initially limited to K3s) and Arc enablement of target clusters, enable workload identity                                         |
| [030-iot-ops-cloud](./src/030-iot-ops-cloud-reqs/README.md) | Cloud resource provisioning for Azure Key Vault, Schema Registry, Storage Accounts, Container Registry, and User Assigned Managed Identity                                               |
| [040-iot-ops](./src/040-iot-ops/README.md)                  | AIO deployment of core infrastructure components (MQ Broker, Edge Storage Accelerator, Secrets Sync Controller, Workload Identity Federation, OpenTelemetry Collector, OPC UA simulator) |
| [050-messaging](./src/050-messaging/README.md)              | Cloud resource provisioning for cloud communication (MQTT protocol head for Event Grid (topic spaces, topics and cert-based authentication), Event Hubs, Service Bus, Relay, etc.)       |
| [060-storage](./src/060-storage/README.md)                  | Cloud resource provisioning for data/event storage (Fabric by means of RTI, Data Lakes, Warehouses, etc.)                                                                                |
| [070-observability](./src/070-observability/README.md)      | Cloud resource provisioning for Azure Monitor and Container Insights                                                                                                                     |
| [080-iot-ops-utility](./src/080-iot-ops-utility/README.md)  | AIO deployment of additionally selected components (OTEL Collector (Phase 2), OPC UA, AKRI, Strato, FluxCD/Argo)                                                                         |
| 090                                                         | Customer defined custom workloads, and pre-built solution accelerators such as TIG/TICK stacks, InfluxDB Data Historian, reference data backup from cloud to edge, etc.                  |

#### Blueprints

This project includes *blueprints* that can be used as reference for deploying specific edge scenarios. Blueprints
are located in the [blueprints](./blueprints) folder and are organized by the supported IaC framework being used,
which includes Terraform, Bicep, and script-based.

### Using this project

This project can be used in two primary ways: 1) running the projects IaC and/or blueprints directly to bootstrap
environments such as labs, cloud-hosted development environments, integration/QA environments, or small
production deployments; or 2) cloning the repository and all its automation to have and out-of-the-box CI/CD
solution for your IaC. Feel free to pick and choose which components are needed or necessary to help start or
extend your project.

For running the IaC to bootstrap environments, please refer to the [Getting Started](#getting-started)
documentation below. For using this repository and it's automation to have a complete CI/CD system for your
IaC, please review the [build pipelines ReadMe](./.azdo/README.md) and reach out to the
[Microsoft ISE Edge Computing Technical Domain team](mailto:ectd@microsoft.com) if you need support.

### Supported Features

The Terraform, scripts, and documentation in this repository can provide you the following features and capabilities:

- Subscription resources supporting all "in-the-box" components of an Azure IoT Operations (AIO) solution
- Deployment of a cloud-hosted VM, sized and provisioned specifically for developing AIO solutions
- Deployment of a development-ready K3s cluster with all the basic AIO components installed
- [Integrated support for Azure Managed Identities](./src/010-vm-host/terraform/README.md)
- [Integrated support for "Bring-Your-Own" certificates](./src/040-iot-ops/terraform/README.md#create_resources) (and intermediate certificates) for intra-cluster TLS
- [A robust, matrix'ed IaC build system](./azure-pipelines.yml) with integrated testing and validation, to ensure your IaC deploys as you expect it to
- Auto-validation and auto-generation of Terraform Plans to support expedited CISO/Security/DevOps team approvals
- [A library of common "Architectural Decision Records" (ARDs)](./docs/solution-adr-library/README.md), ready to be modified to document your solution's requirements and the decisions you've made along the way
- [A library of technology papers](./docs/solution-technology-paper-library/README.md) to upskill your peers
- [A well-stocked development container](./.devcontainer) for you to take the IaC for your "AI on the Edge Solutions" to production with confidence, repeatability, and reliability your organization deserves
- [Blueprints](./blueprints) full scenario deployments that demonstrate how components are composed together

### Contribute

Before contributing, please review the project's [Code of Conduct](./CODE_OF_CONDUCT.md).

Users and project developers can contribute to make this solution better in several ways:

- [Review the project's Contributing doc](./CONTRIBUTING.md)
- [Contribute an ADR](./docs/solution-adr-library/README.md#contribute) from your engagement
- [Contribute a Security Plan](./docs/solution-security-plan-library/README.md#contribute) from your engagement
- [Find a user story or task from the backlog](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_sprints/taskboard/IaC%20for%20the%20Edge%20Team/IaC%20for%20the%20Edge/***REMOVED***) and help move the accelerator forward

#### Build and Test

We recommend using the project's [dev container](./.devcontainer/README.md) for all contribution work.

Start orienting yourself with this repository by referring to [blueprints](./blueprints) for your first deployment.

Pull requests made to the repository go through a through build process including linting, testing, and
in some cases deployment validation. After raising a PR, the build process with begin evaluating your
contribution. If errors arise from the build, please attend to them as soon as you can.

The project includes a [package.json script set](./package.json) that can be quite useful in development, and is worth a review.

#### ADR Process

Design decisions for project direction, feature or capability implementation, and community decisions
happen through an Architecture Decision Record (ADR) process. ADRs can be drafted by any project community
member for consideration first by project leads, and secondarily by the project's community. Final ADR
acceptance is performed via sign-off from 3/5ths of the project's leads: Technical Lead (Bill Berry), Product
Owner (Larry Lieberman), Technical Program Manager (Mack Renard), Consulting cross-domain Architect (Paul
Bower), and Architect (Tim Park).

ARDs move through a process that includes the following states:

- Draft - for all ADRs under development and in a drafting phase. May be committed to the main branch directly by project leads, but must be done via branches for community members
- Proposed - for all ADRs that have been reviewed by the ADR sign-off team (project leads), this phase indicates the ADR is now open for discussion amongst the broad project community for feedback.
- Accepted - for all ADRs that have completed the community RFC process. ADRs in this state have been ratified/accepted by the project community and may move to implementation.
- Deprecated - for all ADRs that are no longer relevant to the solution or have been superseded by more comprehensive ADRs; this is inclusive of retired components or features, but will be retained in perpetuity for historical context.

Please see [ADR README](./project-adrs/README.MD) for a more detailed explanation of the ADR process flow and how to author and progress your ideas for this project, through to implementation.
