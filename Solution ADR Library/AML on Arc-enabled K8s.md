# Scale deployment of Azure ML models to edge Arc-enabled K&s clusters in an PoC

Date: **2024-09-06**

## Status

[For this library of ADRs, mark the most applicable status at which it was stored in the original project. This can help provide context and validity for folks reviewing this ADR. If it has been deprecated you can add a note on why and date it.]

- [ ] Draft
- [ ] Proposed
- [X] Accepted (in scope of the MVE/Demonstrator)
- [ ] Deprecated

## Context

For a manufacturing customer, a **Demonstrator** needed to be created in a short period of time to showcase technology capabilities and choices that can solve the customer's requirements.

The Demonstrator aims to solve these requirements within the scope of Machine Learning model deployment to Arc-enabled Kubernetes clusters (edge):

- Enable an edge platform at the factories for running (near) real-time workloads that process data from the factory, prepare the data, call an inferencing endpoint of an ML model, and process the prediction.
- Showcase how to integrate ML Ops processes to streamline ML model training, re-training, monitoring, deployment, re-deployment to edge clusters, at scale.
- Showcase model monitoring and lifecycle from edge to cloud for improving models in a continuous process, triggering model re-training through Azure ML workspace functionality.
- Customer stretch goal of showcasing model training at the edge.

## Decision

Using Azure ML Arc extension to deploy Machine Learning models registered in Azure ML into an edge computing Arc-enabled Kubernetes cluster.

### Decision drivers

- Azure Machine Learning (AML) Arc Extension is well integrated with Azure ML's training, re-training and scale deployment of models from cloud to edge. This feature enables a working MVE that covers most key technical requirements presented to ISE customers.
- The approach seamlessly allows the use of the Edge Azure ML compute target to train models on the edge, which is a stretch goal of the Demonstrator.
- The scope and timing limitations of the Demonstrator moved the decision towards out-of-the-box functionality where possible to prove more requirements in a limited amount of time.

## Considered Options

### Option 1: Azure Machine Learning (AML) Arc Extension

[Azure ML Kubernetes compute target](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-anywhere?view=azureml-api-2) is available as Arc extension for a remote Kubernetes cluster to be used as a compute target in AML for training and/or deploying inference models.

- Extends the Azure ML Kubernetes compute target to Arc-enabled Kubernetes clusters on multi-cloud or edge. Part of `Online deployments` feature of Azure ML workspace. This addresses the scenario requirements for showcasing AML model training and seamless deployment pipeline to Kubernetes edge clusters.
- Hosts the base components to deploy (new & remove), rollout, scale, secure, load balance models to the edge where they become available for local inference.
- Allows the deployment of (re-)training jobs on edge clusters, addressing the stretch goal requirement
- Integrated with Azure RBAC permission model (from Azure ML down to Azure Arc components), ensuring a security-first mindset.

#### Inference router

The AML Arc Extension implements an Inference Router functionality which takes care of several model hosting features automatically:

- Front-end to distribute traffic to deployed models
- Download dynamic configuration from Azure Storage offerings
- Authentication layer to models (AML keys)
- Scale deployments pods
- Deploy models
- A/B test models

#### Edge cluster system requirements

The following are the minimum requirements to running the Arc extension, which could change based on other workloads or performance requirements of actual models deployed into the cluster.

| Scenario       | Enabled Inference | Enabled Training | CPU Request (m) | CPU Limit (m) | Memory Request (Mi) | Memory Limit (Mi) | Node count | Recommended minimum VM size                    | Corresponding AKS VM SKU |
|----------------|-------------------|------------------|-----------------|---------------|---------------------|-------------------|------------|------------------------------------------------|--------------------------|
| For Test       | **✓**             | N/A              | **1780**        | 8300          | **2440**            | 12296             | 1 Node     | 2 vCPU, 7 GiB Memory, 6400 IOPS, 1500Mbps BW   | DS2v2                    |
| For Production | **✓**             | N/A              | 3600            | **12700**     | 4240                | **15296**         | 3 Node(s)  | 4 vCPU, 14 GiB Memory, 12800 IOPS, 1500Mbps BW | DS3v2                    |

See details in [Recommended resource planning](https://learn.microsoft.com/en-us/azure/machine-learning/reference-kubernetes?view=azureml-api-2#recommended-resource-planning)

#### Pros and Cons for Option 1

Pros:

- The solution is an integral part of Azure ML SDK, CLI, and Portal, with a focus on Data Scientist and ML Engineer personas.
- Integrates model observability within Azure ML Workspace.
- Does not require data scientist to understand specifics of edge deployment, it just works out of the box like for any online endpoint deployment.
- Push vs Pull: Arc extension triggers the deployment in a `push` mechanism. This mechanism allows for controlling the exact timing a deployment is triggered from the cloud side. This could be extended to implement strict approval/authorization and automation gates to trigger deployments only during specific operational windows.
- The extension is a solution that deploys as set of workloads into Kubernetes, needs to be upgraded and managed. As a Microsoft supported product there is added solution bundling/integrated value, compared to some 3rd party open-source solutions.
- Identity pod - requirement to authenticate to the model through the front-end load balanced endpoints using Azure managed keys for the deployment. Unclear if federated workload identity is supported at edge (which is still in Preview).

Cons:

- Scale limits:
  - Azure ML 'online endpoints' are limited to 50 per subscription. This scale limitation will be a blocker for most customers.
  - Azure ML deployments are limited to 20 per online endpoint. Again this can be a tough limitation for many scenarios.
- Offline support for the extension is not documented and needs to be evaluated and confirmed.
- Monitoring and observability is not exposed locally on the edge cluster and tunnelled directly into the Azure ML workspace without clear documentation on how to store the signals within a customer's monitoring solution
- The model is deployed as a load balanced REST API endpoint which might not fit all use cases.
- Azure ML Arc extension does not solve the requirement for creating, maintaining, and managing a Git repo-based deployment for a workload that interact with the deployed models for inferencing calls, so an additional solution needs to be implemented regardless.
- Evaluate networking requirements [Inference router and connectivity requirements - Azure Machine Learning](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-kubernetes-inference-routing-azureml-fe?view=azureml-api-2#understand-connectivity-requirements-for-aks-inferencing-cluster)
- System requirements might be higher than running standalone models on edge.

### Option 2: Azure Arc Flux GitOps extension and GitOps based deployment

GitOps with solutions like Flux or ArgoCD are a common approach to deploying and managing software in
Kubernetes clusters, in the cloud and at the edge. For deploying Azure Machine Learning workloads, Flux GitOps
through Azure Arc extension is a viable consideration. [Azure Arc GitOps Flux v2](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-gitops-flux2)
extension simplifies installing Flux as a cluster extension and configuring Flux Configuration resources that
sync Git repository sources and reconcile a cluster's desired state.

A new model published into the Azure ML repository requires manual steps of creating a deployment manifest
(or Helm Chart), updating an existing manifest in a Git repository, and updating settings of the new model
into each edge cluster's configuration root. This is a manual process which can be partially automated through
a UI or other automation processes but adds additional complexity and effort during initial project iterations.

#### Pros and Cons for Option 2

Pros:

- Pull vs push: GitOps (with Flux) implements a `pull`-based model with desired state reconciliation based on approved Git branch changes, with no deployments are done without a clear Git based validation flow.
- Continuous reconciliation on a edge cluster.
- Traceability by means of Git (commit, PR, merge, approve, ...).

Cons:

- Managing hundreds of targets clusters within a single Git repository structure, with automated tools that may impact manifest creation, is a complex task which Git is not optimized for.
- Requires additional workflows and tooling for fleet configuration management at scale, see [Workload management in a multi-cluster environment with GitOps](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-workload-management).
- RBAC separation per cluster is missing out of the box (as the Git permissions are for an entire repo).
- Flux reconciliation engine runs continuously preventing clear maintenance windows out of the box, often
prohibitive in manufacturing scenarios, though this can be addressed with approaches such as [Refactoring GitOps repository to support both real-time and reconciliation window changes](https://dev.to/mahrrah/refactoring-gitops-repository-to-support-both-real-time-and-reconciliation-window-changes-2cc)
and [How to enable reconciliation windows using Flux and K8s native components](https://dev.to/mahrrah/how-to-enable-reconciliation-windows-using-flux-and-k8s-native-components-2d4i).

## Consequences

The decision to go for the integrated offering of AML Arc Extension allows for building a Demonstrator that
achieves the goals, within a period of less than 3 weeks.
It does not however aim to solve the scale problem of 100's of edges, models and versions of models.

## Future considerations

The choice not to use a GitOps approach currently to deploy Azure ML models does not prevent changing to a
GitOps or a combination approach in the future. Both approaches deploy docker containers from a registry, and
most components would be reused regardless of terminal decision.

Some elements to highlight influencing future decisions:

- Understanding the business processes of manufacturing facilities and the personas involved in deploying workloads and models into the clusters (who, when, configuration ownership, time bound impact, etc)
- System and networking requirements and constraints (ISA/Purdue networks, security/connectivity)
- Performing scale model deployments from Azure ML to edge environments can be extended to leverage UIs for non-data science roles, by using Azure ARM and Arc as the underlying technology; APIs may allow for additional flexibility and opportunity for automation.

Product team offering:

Edge & Platform Product team is working on extending ML model and workload deployment with solutions like
Toolchain Orchestrator and Configuration Management. These solutions are in Private Preview at time of writing
but should be evaluated in future engagements.
