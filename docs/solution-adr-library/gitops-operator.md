---
title: GitOps operator for an Azure Arc enabled cluster
description: Architecture Decision Record comparing GitOps operators (Flux vs Argo CD) for Azure Arc-enabled Kubernetes clusters. Evaluates Azure Arc GitOps extension integration with Flux v2, deployment observability through Azure Resource Graph, fleet management capabilities, and Microsoft support considerations for edge and cloud cluster deployments.
author: Eugene Fedorenko
ms.date: 2025-06-06
ms.topic: architecture-decision-record
estimated_reading_time: 6
keywords:
  - gitops
  - gitops-operator
  - azure-arc
  - azure-arc-gitops
  - flux
  - flux-v2
  - argo-cd
  - kubernetes
  - azure-resource-graph
  - deployment-observability
  - fleet-management
  - microsoft-flux
  - edge-computing
  - cluster-management
  - continuous-deployment
  - kalypso-observability-hub
  - azure-arc-extension
  - architecture-decision-record
  - adr
---

## Status

- [ ] Draft
- [ ] Proposed
- [X] Accepted
- [ ] Deprecated

## Context

The most common GitOps operators today are the open-source projects [Flux](https://fluxcd.io/flux/) and [Argo CD](https://argo-cd.readthedocs.io/en/stable/). Both provide similar functionality, though their implementations have some differences.
Additionally, Azure Arc-enabled clusters, including AKS, can leverage the Azure Arc GitOps extension, which is currently integrated with Flux.
This ADR aims to decide which option to use across a fleet of Azure Arc-enabled clusters at the Edge and in the cloud.

## Decision

[Azure Arc GitOps (Flux v2)](https://learn.microsoft.com/azure/azure-arc/kubernetes/conceptual-gitops-flux2) extension has been determined as the GitOps operator for Azure Arc enabled Kubernetes clusters across Edge and Cloud.

## Decision Drivers

### Integration with Azure

- The Azure Arc GitOps extension monitors the GitOps operator on each cluster and reports its state to Azure Resource Graph (ARG), which serves as a central storage for deployment states.
This feature is crucial for enabling deployment observability across a fleet of clusters.
Microsoft provides out-of-the-box [observability dashboards](https://learn.microsoft.com/azure/azure-arc/kubernetes/monitor-gitops-flux-2) that display the health of GitOps operators.
Additionally, solutions like the [Deployment Observability Hub](https://github.com/microsoft/kalypso-observability-hub?tab=readme-ov-file#deployment-observability-hub)
utilize deployment state data from ARG to offer a comprehensive historical view of deployment observability. For more details, refer to the Deployment Observability ADR.

- Installing and configuring a GitOps operator on a cluster involves installing the Azure Arc GitOps extension.
This can be done using various tools such as Azure CLI, Bicep, Terraform, or through the Azure Portal.

### Support

Currently, the Azure Arc GitOps extension is built on a forked version of Flux V2, known as *microsoft.flux*. This extension is fully supported by the Microsoft Azure Arc GitOps product team.

There are also plans to integrate the Azure Arc GitOps extension with Argo CD, although no specific timelines have been provided at this point.

## Other options

Another option would be to use the open-source versions of Flux or Argo CD. Both tools offer similar functionalities, with each having its own strengths and weaknesses.
A detailed comparison of these tools is beyond the scope of this ADR, and often the choice between them comes down to developer's preference.
However, neither of these solutions provides the additional benefits outlined in the [Decision Drivers](#decision-drivers) section.

## Future Considerations

The related topics are highlighted in separate ADRs:

- [CI/CD. Multi-Environment Promotional Flow with GitOps](./cicd-gitops.md)
- [Deployment on the Edge with GitOps](./deployment-on-edge-gitops.md)
- [Workload and Configuration Management](./workload-configuration-management.md)
- Deployment Observability
- Secret Management on the Edge with GitOps

*AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*
