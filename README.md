# Introduction

The IaC for Edge project, the first phase of ISE's "AI on Edge" Flagship Accelerator, will deliver a compiler/generator that outputs composable IaC. The IaC compiler/generator can grow with a customer's capabilities from innovative POCs and onto production system deployments. This solution will generate all the foundational cloud and edge solution components required to implement a “vision on edge” solution using Azure IoT Operations (AIO).

The CLI-based IaC compiler/generator supports Terraform and Bicep outputs for base infrastructure and can interface with a limited selection of GitOps toolchains for core AIO components and custom customer workload deployment. Pre-built VM and cloud-hosted cluster setup scripts are also output from the generator, however the project only supports a very narrow set of configurations (Ubuntu & K3s clusters).

The IaC compiler/generator supports the following fine-grained output layers (though these layers can be flattened into larger chucks to fit a customer's operational model):

1. VM/host provisioning with configurable host operating system (initially limited to Ubuntu)
2. Installation of CNCF cluster that is AIO compatible (initially limited to K3s)
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

Initial runs of the CLI will generate a full Arc-enabled, cloud-hosted development cluster with a basic AIO deployment (Phases 1 through 7). After that, annotations and naming conventions can be used to generate any set or sub-set of IaC for a target environment and reclassify elements for inclusion in alternate layers of the output IaC.

Customers often approach with a wide variety of teams, roles and responsibilities to develop cloud-enabled edge computing solutions. There are often physical plant IT teams responsible for hardware through OSes at the edge, and enterprise IT responsible for cloud infrastructure deployment. There are teams managing cloud data estates, and specialist teams managing physical plant data systems. There are Data Science teams that often span edge and cloud and need to think of both edge and cloud environments in a unified (i.e. more uniform) way. This tool is built to directly address these constraints, and is positioned to accelerate customers through the POC phase with opinionated IaC, and the flexibility to grow and evolve IaC approaches to accommodate increasing solution complexity. 

In the future, this CLI-based tool will provide extensible (though custom component integration) GitOps outputs for AIO components and custom workloads, initially supporting Argo CD, Flux and Kalypso.

## Getting Started

Users can get started quickly by:

1. Clone the CLI Repository (this solution is not available via package distribution - please update all components after cloning and file issues if challenges are encountered)
2. Run the CLI locally using `{cli} create {solution_template_file_path} {target_environment} {output_format} 
3. Collect output artifacts and execute in runtime of choice using output format tooling (instructions provided in output readme)

## Build and Test

Describe and show how to build your code and run the tests.

## ADR Process

All design decisions for project direction, feature or capability implementation, and community decisions happen through an Architecture Decision Record (ADR) process. ADRs can be drafted by any project community member for consideration first by project leads, and secondarily by the project's community. Final ADR acceptance is performed via sign-off from 3/5ths of the project's leads: Technical Lead (Bill Berry), Product Owner (Larry Lieberman), Technical Program Manager (Mack Renard), Consulting cross-domain Architect (Paul Bower), and Architect (Tim Park).

ARDs move through a process that includes the following states:

* Draft - for all ADRs under development and in a drafting phase. May be committed to the main branch directly by project leads, but must be done via branches for community members
* Proposed - for all ADRs that have been reviewed by the ADR sign-off team (project leads), this phase indicates the ADR is now open for discussion amongst the broad project community for feedback.
* Accepted - for all ADRs that have completed the community RFC process. ADRs in this state have been ratified/accepted by the project community and may move to implementation.
* Deprecated - for all ADRs that are no longer relevant to the solution or have been superseded by more comprehensive ADRs; this is inclusive of retired components or features, but will be retained in perpetuity for historical context.

Please see [ADR README](./ADRs/README.MD) for a more detailed explanation of the ADR process flow and how to author and progress your ideas for this project, through to implementation.

## Contribute

Users and developers can contribute to make this solution better.

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:

* [ASP.NET Core](https://github.com/aspnet/Home)
* [Visual Studio Code](https://github.com/Microsoft/vscode)
* [Chakra Core](https://github.com/Microsoft/ChakraCore)