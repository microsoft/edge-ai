# Introduction

[![Build Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_apis/build/status%2FIaC%20for%20the%20Edge?branchName=main)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_build/latest?definitionId=3&branchName=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Board Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/8567de21-1286-4352-a375-efb89ad55348/_apis/work/boardbadge/fd9375f1-e7c6-4439-b2c9-6969d853a2d4)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/_boards/board/t/8567de21-1286-4352-a375-efb89ad55348/Stories/)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/IaC%20for%20the%20Edge)

Implementing an Adaptive Cloud approach requires great tooling; we're excited to introduce the "IaC for the
Edge" project, our next generation Infrastructure as Code solution designed specifically for systems spanning
edge and cloud. This project encodes a decade of experience harvesting petabytes of edge telemetry and
extending the power and capabilites of Azure, to the edge. This project is just the first step in enabling our
AI on Edge Accelerator, a suite of IaC, tools, and applications for designing, engineering, deploying and
managing scale AI solutions at the edge.

It takes a wide variety of teams, roles, and responsibilities to develop cloud-enabled edge computing
solutions. There are physical plant IT teams responsible for hardware at the edge, and enterprise IT
responsible for cloud infrastructure. There are teams managing cloud data estates, and specialist
teams managing physical plant data systems. There are Data Science teams that need to process
telemetry across edge and cloud and need to view both environments as a unified whole. This project is built to
address the needs of all stakeholders, and will accelerate POCs to production, with the flexibility to
tackle the increasing complexity of delivering business value from edge data.

## Composable IaC

This project is not a reference architecture; for that, please see
[Azure IoT Operations (AIO)](https://learn.microsoft.com/en-us/azure/iot-operations/overview-iot-operations)
documentation or the [Azure Arc Jumpstart](https://azurearcjumpstart.com/) project. This project is a
composable library of fine-grained, production ready IaC that can be easily layered to fit nearly any
operational model, from small, single machine systems, to orchestrated, globally-distributed solutions. The
project uses a decimal system to organize the IaC, scripts, and resources, which can be collated in myriad ways
to meet operational requirements:

1. [(000)](./src/000_rp_enablement/README.md) Run-once scripts for Arc & AIO resource provider enablement in subscriptions, if necessary
2. (005) Resource Groups, Site Management (optional), Role assignments/permissions for Arc onboarding
3. [(010)](./src/010_cluster_install/terraform/README.md) VM/host provisioning, with configurable host operating system (initially limited to Ubuntu)
4. [(020)](./src/010_cluster_install/terraform/README.md) Installation of a CNCF cluster that is AIO compatible (initially limited to K3s) and Arc enablement of target clusters, workload identity, and OTEL collector
5. [(030)](./src/010_cluster_install/terraform/README.md) Cloud resource provisioning for Azure Key Vault, Storage Accounts, Container Registry, and User Assigned Managed Identity
6. [(040)](./src/020_aio_install/terraform/README.md) AIO deployment of core infrastructure components (MQ Broker, Edge Storage Accelerator, Data Flow, Secretes Sync Controller, Workload Identity Federation, and Schema Registry)
7. (050) Cloud resource provisioning for cloud communication (MQTT protocol head for Event Grid (topic spaces, topics and cert-based authentication), Event Hubs, Service Bus, Relay, etc.)
8. (060) Cloud resource provisioning for data/event storage (Fabric by means of RTI, Data Lakes, Warehouses, etc.)
9. (070) Cloud resource provisioning for Azure Monitor and Container Insights
10. (080) AIO deployment of additionally selected components (OTEL Collector (Phase 2), OPC UA, AKRI, Strato, FluxCD/Argo)
11. (090) Customer defined custom workloads, and pre-built solution accelerators such as TIG/TICK stacks, InfluxDB Data Historian, reference data backup from cloud to edge, etc.

## Using this project

This project can be used in two primary ways: 1) running the projects IaC (Terraform) directly to bootstrap
environments such as labs, cloud-hosted development environments, integration/QA environments, or small
production deployments; or 2) cloning the repository and all its automation to have and out-of-the-box CI/CD
solution for your IaC.

For running the IaC to bootstrap environments, please refer to the [Getting Started](#getting-started)
documentation below. For using this repository and it's automation to have a complete CI/CD system for your
IaC, please review the [pipelines ReadMe](./.pipelines/README.md) and reach out to the
[Microsoft ISE Edge Computing Technical Domain team](mailto:ectd@microsoft.com) if you need support.

## Getting Started

While further documentation is under development, you can use the IaC (Terraform) in this repository
directly to get started bootstrapping environments by:

1. Ensuring you have all the [required pre-requisites](./src/README.md#prerequisites) met for your development machine. We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly.
2. [Cloning this repository locally](https://learn.microsoft.com/en-us/azure/devops/repos/git/clone?view=azure-devops&tabs=visual-studio-2022#get-the-clone-url-of-an-azure-repos-git-repo) (this solution is not available via package distribution - please consider updating all dependencies after cloning and file issues if challenges are encountered)
3. [Preparing an Azure Subscription with the required resource providers](./src/000_rp_enablement/README.md) to support Azure Arc and Azure IoT Operations.
4. [Deploy an Azure Arc-enabled K3s cluster](./src/010_cluster_install/terraform/README.md) to an Azure-hosted Virtual Machine.
5. [Deploy Azure IoT Operations](./src/020_aio_install/terraform/README.md) to the previously deployed Azure-hosted VM.

### Supported Features

The Terraform, scripts, and documentation in this repository can provide you the following features and capabilities:

* Subscription resources to support all "in-the-box" components of an Azure IoT Operations (AIO) solution
* Deployment of a cloud-hosted VM, sized and provisioned specifically for developing AIO solutions
* Deployment of a development-ready K3s cluster with all the basic AIO components installed
* [Integrated support for Azure Managed Identities](./src/010_cluster_install/terraform/README.md)
* [Integrated support for "Bring-Your-Own" certificates](./src/020_aio_install/terraform/README.md#create_resources) (and intermediate certificates) for intra-cluster TLS
* [A robust, matrix'ed IaC build system](./azure-pipelines.yml) with integrated testing and validation, to ensure your IaC deploys as you expect it to
* Auto-validation and auto-generation of Terraform Plans to support expedited CISO/Security/DevOps team approvals
* [A library of common "Architectural Decision Records" (ARDs)](./Solution%20ADR%20Library/README.md), ready to be modified to document your solution's requirements and the decisions you've made along the way
* [A library of technology papers](./Solution%20Technology%20Paper%20Library/README.md) to upskill your peers
* [A well-stocked development container](./.devcontainer) for you to take the IaC for your "AI on the Edge Solutions" to production with confidence, repeatability, and reliability your organization deserves

Happy Developing!
ISE's AI on the Edge Accelerator Team

## Build and Test

Currently, this repository only supports linting and Terraform validation/plans for the included IaC. We
recommend using the project's [dev container](./.devcontainer/README.md) for all contribution work. Please
refer to the project's [Azure Pipeline](./azure-pipelines.yml) to see the PR and `main` branch build approaches.

## ADR Process

Design decisions for project direction, feature or capability implementation, and community decisions
happen through an Architecture Decision Record (ADR) process. ADRs can be drafted by any project community
member for consideration first by project leads, and secondarily by the project's community. Final ADR
acceptance is performed via sign-off from 3/5ths of the project's leads: Technical Lead (Bill Berry), Product
Owner (Larry Lieberman), Technical Program Manager (Mack Renard), Consulting cross-domain Architect (Paul
Bower), and Architect (Tim Park).

ARDs move through a process that includes the following states:

* Draft - for all ADRs under development and in a drafting phase. May be committed to the main branch directly by project leads, but must be done via branches for community members
* Proposed - for all ADRs that have been reviewed by the ADR sign-off team (project leads), this phase indicates the ADR is now open for discussion amongst the broad project community for feedback.
* Accepted - for all ADRs that have completed the community RFC process. ADRs in this state have been ratified/accepted by the project community and may move to implementation.
* Deprecated - for all ADRs that are no longer relevant to the solution or have been superseded by more comprehensive ADRs; this is inclusive of retired components or features, but will be retained in perpetuity for historical context.

Please see [ADR README](./Project%20ADRs/README.MD) for a more detailed explanation of the ADR process flow and how to author and progress your ideas for this project, through to implementation.

## Contribute

Before contributing, please review the project's [Code of Conduct](./CODE_OF_CONDUCT.md).

Users and project developers can contribute to make this solution better in several ways:

* [Review the project's Contributing doc](./CONTRIBUTING.md)
* [Contribute an ADR](./Solution%20ADR%20Library/README.md#contribute) from your engagement
* [Contribute a Security Plan](./Solution%20Security%20Plan%20Library//README.md#contribute) from your engagement
* [Find a user story or task from the backlog](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_sprints/taskboard/IaC%20for%20the%20Edge%20Team/IaC%20for%20the%20Edge/***REMOVED***) and help move the accelerator forward
