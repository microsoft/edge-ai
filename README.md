# Introduction

[![Build Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_apis/build/status%2FIaC%20for%20the%20Edge?branchName=main)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_build/latest?definitionId=3&branchName=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Board Status](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/8567de21-1286-4352-a375-efb89ad55348/_apis/work/boardbadge/fd9375f1-e7c6-4439-b2c9-6969d853a2d4)](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/3bef5a01-44ac-4d6c-8c8d-f4b7d374def6/_boards/board/t/8567de21-1286-4352-a375-efb89ad55348/Stories/)
[![Open in Dev Containers](https://img.shields.io/static/v1?label=Dev%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://dev.azure.com/ai-at-the-edge-flagship-accelerator/_git/IaC%20for%20the%20Edge)

The IaC for Edge project, the first phase of ISE's "AI on Edge" Flagship Accelerator, will deliver a compiler/generator that outputs composable IaC. The IaC compiler/generator can grow with a customer's capabilities from innovative POCs and onto production system deployments. This solution will generate all the foundational cloud and edge solution components required to implement a “vision on edge” solution using Azure IoT Operations (AIO).

The IaC compiler/generator supports Terraform and Bicep outputs for base infrastructure and can interface with a limited selection of GitOps toolchains for core AIO components and custom customer workload deployment. Pre-built VM and cloud-hosted cluster setup scripts are also output from the generator, however the project only supports a very narrow set of configurations (Ubuntu & K3s clusters).

The IaC compiler/generator supports the following fine-grained output layers (though these layers can be flattened into larger chucks to fit a customer's operational model):

1. VM/host provisioning with configurable host operating system (initially limited to Ubuntu)
2. Installation of a CNCF cluster that is AIO compatible (initially limited to K3s)
3. Run-once scripts for Arc & AIO resource provider enablement in subscriptions, if necessary
4. Required cloud resources for Arc enabling of clusters (including Arc site management)
5. Arc enablement of (initially dev/test/lab) clusters
6. Cloud resource provisioning for MQTT protocol head for Event Grid, topic spaces, topics and cert-based authentication
7. AIO deployment of core infrastructure components (MQ Broker, Edge Storage Accelerator, Data Flow, Secretes Sync Controller, and Workload Identity Federation)
8. Cloud resource provisioning for cold data/event storage, connection to Fabric by means of RTI
9. Cloud resource provisioning for Azure Monitor (and required sub resources supporting edge and cloud infra)
10. AIO deployment of optionally selected components (OPC UA, AKRI, Strato, ADR((cloud)) & Schema Registry)
11. Customer defied custom workloads, and pre-built solution accelerators such as TIG/TICK stacks, InfluxDB Data Historian, Reference data backup from cloud to edge, etc.

IaC compiler/generator output can be further tuned for the following environments:

* Local Dev
* Cloud-hosted development clusters (initial scope)
* On-premises physical lab clusters
* Cloud-hosted QA clusters
* Cloud-hosted integration clusters
* Cloud-hosted pre-production
* Edge-hosted production
* Cloud-hosted production

Initial runs of the generator tool will generate a full Arc-enabled, cloud-hosted development cluster with a basic AIO deployment (Phases 1 through 7). After that, annotations and naming conventions can be used to generate any set or sub-set of IaC for a target environment and reclassify elements for inclusion in alternate layers of the output IaC.

Customers often approach with a wide variety of teams, roles and responsibilities to develop cloud-enabled edge computing solutions. There are often physical plant IT teams responsible for hardware through OSes at the edge, and enterprise IT responsible for cloud infrastructure deployment. There are teams managing cloud data estates, and specialist teams managing physical plant data systems. There are Data Science teams that often span edge and cloud and need to think of both edge and cloud environments in a unified (i.e. more uniform) way. This tool is built to directly address these constraints, and is positioned to accelerate customers through the POC phase with opinionated IaC, and the flexibility to grow and evolve IaC approaches to accommodate increasing solution complexity.

In the future, this generator tool will provide extensible (though custom component integration) GitOps outputs for AIO components and custom workloads, initially supporting Argo CD, Flux and Kalypso.

## Getting Started

Users can get started quickly by:

1. Clone the tool's Repository (this solution is not available via package distribution - please update all components after cloning and file issues if challenges are encountered)
2. Run the tool locally using `{tool} create {solution_template_file_path} {target_environment} {output_format}
3. Collect output artifacts and execute in runtime of choice using output format tooling (instructions provided in output readme)

## Build and Test

This repository only supports linting for the time being; follow the instructions below to lint any additions to the project.

### Linting

Run ALL linters

```bash
npm run lint
```

To fix basic linting issues, run the following:

```bash
npm run lint-fix
```

#### Markdown linting

The linter run as part of PR validation is installed and configured in the DevContainer, making it possible to check your markdown before committing & PR.

```bash
npm run mdlint
```

To fix basic markdown linting issues, run the following:

```bash
npm run mdlint-fix
```

> **NOTE**
>
> Because not all rules include fix information when reporting errors, fixes may overlap, and not all errors are fixable, `fix` will not usually address all errors.

#### Spell checking

Cspell checker runs as part of PR validation and is installed and configured in the DevContainer, which makes it possible to check your language basics before committing & PR.

```bash
npm run cspell
```

> **NOTE**
>
> If cspell detects an unknown word which should be ignored, add the word to the excluded word dictionary file `cspell-cse.txt`. If you think it's a common computing word, you can make a PR against [the cspell software terms dictionary](https://github.com/streetsidesoftware/cspell-dicts/tree/main/dictionaries/software-terms/src)

### Updates

If you need to change this DevContainer, please ensure that the changes maintain consistency with the production build pipeline.

## ADR Process

All design decisions for project direction, feature or capability implementation, and community decisions happen through an Architecture Decision Record (ADR) process. ADRs can be drafted by any project community member for consideration first by project leads, and secondarily by the project's community. Final ADR acceptance is performed via sign-off from 3/5ths of the project's leads: Technical Lead (Bill Berry), Product Owner (Larry Lieberman), Technical Program Manager (Mack Renard), Consulting cross-domain Architect (Paul Bower), and Architect (Tim Park).

ARDs move through a process that includes the following states:

* Draft - for all ADRs under development and in a drafting phase. May be committed to the main branch directly by project leads, but must be done via branches for community members
* Proposed - for all ADRs that have been reviewed by the ADR sign-off team (project leads), this phase indicates the ADR is now open for discussion amongst the broad project community for feedback.
* Accepted - for all ADRs that have completed the community RFC process. ADRs in this state have been ratified/accepted by the project community and may move to implementation.
* Deprecated - for all ADRs that are no longer relevant to the solution or have been superseded by more comprehensive ADRs; this is inclusive of retired components or features, but will be retained in perpetuity for historical context.

Please see [ADR README](./Project%20ADRs/README.MD) for a more detailed explanation of the ADR process flow and how to author and progress your ideas for this project, through to implementation.

## Contribute

Users and developers can contribute to make this solution better in several ways:

* [Contribute an ADR](./Solution%20ADR%20Library/README.md#contribute) from your engagement
* [Contribute a Security Plan](./Solution%20Security%20Plan%20Library//README.md#contribute) from your engagement
* [Find a user story or task from the backlog](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_sprints/taskboard/IaC%20for%20the%20Edge%20Team/IaC%20for%20the%20Edge/***REMOVED***) and help move the accelerator forward

When contributing to the project, please consider the following guidance:

* Assign a workitem to yourself before beginning any effort, and set the item's status field accordingly.
* If a work item for your contribution does not exist, [please file an issue](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/IaC%20for%20the%20Edge/_workitems/create/Issue) first to engage the project's PO, TPM, or Tech Lead for guidance.
* Commits (or at least one in a commit chain) should reference a User Story or Task item from the backlog for traceability.
* When creating a PR, ensure descriptions use [Azure DevOps notation to close associated work items](https://learn.microsoft.com/en-us/azure/devops/repos/git/resolution-mentions?view=azure-devops).
* All code PRs destined for the `main` branch must be reviewed by two reviewers including one of the follow personnel:
  * Tech Lead (Bill Berry)
  * Architect (Tim Park, Paul Bouwer)
  * Assistant Tech Lead (Vy Ta, Katrien De Graeve, or Allen Greaves)
* All ADRs and Security Plans must be reviewed by two reviewers including the following personnel:
  * Product Owner (Larry Lieberman) or TPM (Mack Renard)
  * AI/ML related ADRs (Cheng Chen, Ren Silva)
  * Security related ADRs & Plans (Andrew Malkov)
