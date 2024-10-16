# Scale deployment of Azure ML models to edge Arc-enabled Kubernetes clusters

Date: **2024-10-15**

## Decision

Using Azure ML Arc extension to deploy machine learning models registered in Azure ML into an edge computing cluster.

## Motivation

- Azure Arc is well integrated with Azure ML's training, re-training and scale deployment of models from cloud to edge. This feature enables a working POC that covers most key technical requirements presented to ISE customers.
- The approach seamlessly allows using the Edge Azure ML compute target also to train models on the edge.

## Future considerations

The choice not to use a GitOps approach at this time specifically to deploy Azure ML models does not prevent changing to a GitOps or a combination approach in the future. Both approaches deploy docker containers from a registry, and most components would be reused regardless of terminal decision.

Some elements to highlight influencing future decisions:

- Understanding the business processes of manufacturing facilities and the personas involved in deploying workloads and models into the clusters (who, when, configuration ownership, time bound impact, etc)
- System and networking requirements and constraints (ISA/Purdue networks, security/connectivity)
- Performing scale model deployments from Azure ML to edge environments can be extended to leverage UIs for non-data science roles, by using Azure ARM and Arc as the underlying technology; APIs may allow for additional flexibility and opportunity for automation.

## Appendix

### Options considered for Azure ML to edge deployment

1. Azure Machine Learning Arc extension
2. Azure Arc Flux GitOps extension and GitOps based deployment

### Option 1: Azure ML Arc Extension

[Azure ML Kubernetes compute target](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-attach-kubernetes-anywhere?view=azureml-api-2) is available as Arc extension for a Kubernetes cluster to be used as a compute target in AML for training and/or deploying inference models.

- Extends the Azure ML Kubernetes compute target to Arc-enabled Kubernetes clusters on multi-cloud or edge. Part of `Online deployments` feature of Azure ML.
- Hosts the base components to deploy (new & remove), rollout, scale, secure, load balance models to the edge where they become available for local inference.
- Allows the deployment of (re-)training jobs
- Integrated with Azure RBAC permission model (from Azure ML down to Azure Arc components)

#### Inference router

- Front-end to distribute traffic to deployed models
- Download dynamic configuration from Azure Storage offerings
- Authentication layer to models (AML keys)
- Scale deployments pods
- Deploy models
- A/B test models

#### Risks and dependencies

- The extension is a solution that deploys as set of workloads into Kubernetes, needs to be upgraded and managed. As a Microsoft supported product there is added solution bundling/integrated value, compared to some 3rd party open source solutions
- Identity pod - requirement to authenticate to the model through the front-end load balanced endpoints using Azure managed keys for the deployment. Unclear if federated workload identity is supported at edge (which is still in Preview).
- Evaluate networking requirements [Inference router and connectivity requirements - Azure Machine Learning](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-kubernetes-inference-routing-azureml-fe?view=azureml-api-2#understand-connectivity-requirements-for-aks-inferencing-cluster)
- System requirements might be higher than running standalone models on edge

#### Pros and cons for Option 1

Pros:

- The solution is integral part of Azure ML SDK, CLI and Portal with a focus on Dsta scientist and Ml Endineer personas
- Integrates model observability within Azure ML Workspace
- Does not require data scientist to understand specifics of edge deployment, it just works out of the box like for any online endpoint deployment

Cons:

- Scale limits:
  - Azure ML 'online endpoints' are limited to 50 per subscription. This scale limitation will be a blocker for most customers
  - Azure ML deployments are limited to 20 per online endpoint. Again this can be a tough limitation for many scenarios
- Offline support for the extension is not documented and needs to be evaluated
- Monitoring and observability is not exposed locally on the edge cluster and tunneled directly into the Azure ML workspace without clear documentation on how to store the signals within a customer's monitoring solution
- The model is deployed as a load balanced REST API endpoint which might not fit all use cases

#### Push based deployment vs pull (GitOps)

Arc extension triggers the deployment in a `push` mechanism. This mechanism allows for controlling the exact timing a deployment is triggered from the cloud side. This could be extended to implement strict approval/authorization and automation gates to trigger deployments only during specific operational windows (see. Azure IoT Operations Tool Chain Orchestrator).

#### Edge cluster system requirements

The following are the minimum requirements to running the Arc extension, which could change based on other workloads or performance requirements of actual models deployed into the cluster.

|Scenario | Enabled Inference | Enabled Training | CPU Request(m) |CPU Limit(m)| Memory Request(Mi) | Memory Limit(Mi) | Node count | Recommended minimum VM size | Corresponding AKS VM SKU |
|-- |-- |--|--|--|--|--|--|--|--|
|For Test | **&check;** | N/A | **1780** |8300 |**2440** | 12296 |1 Node |2 vCPU, 7 GiB Memory, 6400 IOPS, 1500Mbps BW| DS2v2|
|For Production |**&check;** | N/A | 3600 |**12700**|4240|**15296**|3 Node(s)|4 vCPU, 14 GiB Memory, 12800 IOPS, 1500Mbps BW|  DS3v2|

See details in [Recommended resource planning](https://learn.microsoft.com/en-us/azure/machine-learning/reference-kubernetes?view=azureml-api-2#recommended-resource-planning)

### Option 2: Azure Arc Flux GitOps extension and GitOps based deployment

GitOps with solutions like Flux or ArgoCD are a common approach to deploying and managing software in Kubernetes clusters, in the cloud and at the edge. For deploying Azure Machine Learning workloads, Flux GitOps through Azure Arc extension is a viable consideration. [Azure Arc GitOps Flux v2](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-gitops-flux2) extension simplifies installing Flux as a cluster extension and configuring Flux Configuration resources that sync Git repository sources and reconcile a cluster's desired state.

The missing piece in the Azure ML scale deployment flow is the additional step of creating, maintaining, and managing a Git repo-based deployment for a workload.

A new model published into the Azure ML repository, requires manual steps of creating a deployment manifest (or Helm Chart), updating an existing manifest in a Git repository, and updating settings of the new model into each edge cluster's configuration root. This is a manual process which can be partially automated through a UI or other automation processes, but adds additional complexity and effort during initial project iterations.

#### Pros and cons for Option 2

Pros:

- Desired state reconciliation based on approved branch changes, no deployments are done without a clear Git based validation flow
- Continuous reconciliation on an edge cluster
- Traceability by means of Git (commit, PR, merge, approve, ...)

Cons:

- Managing hundreds of targets clusters within a single Git repository structure, with automated tools that may impact manifest creation, is a complex task which Git is not optimized for
- RBAC separation per cluster is missing out of the box (as the Git permissions are for an entire repo)
- Flux reconciliation engine runs continuously preventing clear maintenance windows out of the box, often prohibitive in manufacturing scenarios, though this can be addressed with approaches such as [Refactoring GitOps repository to support both real-time and reconciliation window changes](https://dev.to/mahrrah/refactoring-gitops-repository-to-support-both-real-time-and-reconciliation-window-changes-2cc) and [How to enable reconciliation windows using Flux and K8s native components](https://dev.to/mahrrah/how-to-enable-reconciliation-windows-using-flux-and-k8s-native-components-2d4i)

### Future Options

Edge & Platform Product team is working on extending ML model and workload deployment with solutions like Toolchain Orchestrator and Configuration Management. These solutions are in Private Preview at this of writing.
