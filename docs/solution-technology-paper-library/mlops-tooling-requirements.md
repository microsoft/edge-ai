# MLOps Tooling for Vision Model Edge Inference with Intensive Real-Time Video Stream

Date: **2025-01-07**

Drafted by: **Cheng Chen**

## Summary

The scenario discussed in this document is vision model inference at the edge with a high volume of real-time video streams being processed. Vision inference at the edge is essential for processing and analyzing image data locally for computer vision tasks like object detection, image classification, anomaly detection, etc.
These tasks benefit from real-time processing at the edge, which reduces latency, minimizes data transmission costs, preserves privacy on-site, and ensures faster inference to decision-making loops by processing data closer to the edge data source and point of action.

The data load of vision inference may be consistently large or having sudden bursts. Additionally, the discussion includes considerations for custom or proprietary models with complex model frameworks.

This document serves as a decision-making guide (and as a base for derived ADSs) to help teams evaluating important considerations when designing MLOps tooling approaches for edge vision inference scenarios; additional focus on top-level requirements of autoscaling is needed to address data bursts, cost efficiency, and details how to leverage available hardware acceleration features. It aims to:

- Highlight trade-offs and unique features of each MLOps tooling option in the context of vision inference workloads with additional considerations for autoscaling and hardware acceleration.
- Accelerate engineering teams to match and refine customer requirements, understand the MLOps landscape, and make more effective decisions in solution design.

The detailed technical algorithm and design for implementing autoscaling and hardware acceleration under each MLOps tooling option will be addressed in a separate technical position paper.

## Challenges

Challenges arise when the data volumes fluctuation of real-time video streams causes unpredictable behaviors of the inference workload such as incoming data loss during spikes, or compute resource wastage during low traffic periods. It becomes crucial to autoscale the edge inference workload to handle the data bursts and volume variation. Autoscaling can help to dynamically adjust the number of compute resources to match the workload demand, and save costs during idle times.

Meanwhile, the size, architecture, and framework of a model directly affect its performance and ability to utilize hardware acceleration. Optimizing models and utilizing hardware acceleration become essential when there is a large demand of compute resources and meeting latency requirements in real time vision tasks at the edge.
The optimization should be dictated by model architecture, for example, transformer-based models often require more optimization compared to CNN-based models to meet real-time processing needs. Large model training can benefit from distributed training to accelerate the process, while distributed inference can enhance efficiency when handling consistently high data volumes. These hardware acceleration approaches help streamline the MLOps lifecycle and reduce inference latency.

There are various options of MLOps tooling for the processes of model training, model packaging, and deployment and inferencing at the edge. Tooling workflows will further influence autoscaling and hardware acceleration strategies.

## Considered Scenarios

This document discusses three different scenarios of vision on edge MLOps tooling with associated design considerations.

Design considerations are discussed under the below scenarios:

1. The Azure Machine Learning (AML) training service is already in use in the existing system, or AML has been chosen to meet customer design requirements in the training of vision models. The model is flexible in its ability to be deployed either via AML's native deployment tooling by means of the AML Arc Extension, or other deployment tooling approaches, such as GitOps/Flux.
2. The customer wants to train a custom model with a local machine, any cloud provider, or any other training tools, or they already have a proprietary model. And they decide to use AML deployment service to pack and deploy the model.
3. The customer wants to train a custom model with a local machine, any cloud provider, or any other training tools, or they already have a proprietary model. And they want to deploy the model via other deployment tools like GitOps, instead of AML deployment. AML services will not be involved in this lifecycle.

### Scenario 1

Training: AML
Packaging: AML  
Deployment: flexible for any deployment tool

AML training service is used for model training and model packaging. The model package is deployed to the compute target via the AML deployment tooling or other deployment tool via a managed container registry.

AML provides a model optimization feature supporting ONNX during model training; for details on how ONNX can help optimizing model inferencing, check [here](https://learn.microsoft.com/en-us/azure/machine-learning/concept-onnx?view=azureml-api-2). You can use AML to train an ONNX model, use automated machine learning capabilities for ONNX format conversion, or use Azure AI Custom Vision to generate customized ONNX models.

Alternatively, if the model is built on one of the [frameworks which support ONNX conversion](https://onnx.ai/supported-tools), you can use [ONNX conversion tools](https://github.com/onnx/tutorials) to convert it.

Another important hardware acceleration feature that AML can provide is distributed training (e.g., TensorFlow’s MirroredStrategy or PyTorch DDP) across multiple GPUs to speed up model training. Without strong support of distributed training, models may not perform optimally in distributed edge environments. Distributed training can be used for traditional machine learning models, but it is better suited for compute and time intensive tasks, like the use of deep learning model for vision tasks.

The vision model trained with AML can be seamlessly deployed to Arc-enabled Kubernetes edge clusters with the AML native deployment service (arc extension) or can be flexibility packaged and saved in a container registry and subsequently deployed via other deployment tooling approaches.

If you decide to use AML native deployment, it has built-in support for autoscaling. For autoscaling design and configuration, check [here](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-kubernetes-inference-routing-azureml-fe?view=azureml-api-2#autoscaling) to become familiar with the AML autoscaling feature and its associated inferencing router component.

If you decide to use a deployment tool other than AML deployment, such as GitOps/Flux, Kubernetes Horizontal Pod Autoscaler (HPA) is a popular choice for autoscaling pods, which is also compatible with model containers created by AML. See [Scenario 3](#scenario-3) for more details.

Considerations for this option:

- Pros:
  - AML provides the convenience to manage training process, model optimization and packaging with AML workflow, and seamlessly integrates with Azure services and most Azure-supported compute target.
  - AML provides hardware acceleration features during model training, such as native support on ONNX format during model training, distributed GPU training, and other large model optimization features.
  If not using AML training and the above hardware acceleration required, you will need to find an alternative way, but you won't lose AML's other hardware acceleration features at later stages of packaging or deployment if you still use AML for deployment of your own trained model.
  - AML has built-in support for autoscaling with inference router component.

- Cons:
  - If using AML autoscaling component inference router, you cannot enable Kubernetes HPA for model deployment as doing so would cause the two auto-scaling components to compete with each other.
  - AML autoscaling component does not scale the number of nodes in an Kubernetes cluster, because this could lead to unexpected cost increases. Instead, it scales the number of replicas for the model within the physical cluster boundaries.
  - AML provides pre-built Docker images for common frameworks like TensorFlow, PyTorch, ONNX Runtime, etc. If you use a less common framework (e.g., a proprietary framework), you may need to build a custom Docker container.
  - MLflow integration is designed for popular frameworks like TensorFlow, PyTorch, and Scikit-learn. Custom frameworks may require additional effort for integration and testing. The MLflow supported frameworks are listed [here](https://mlflow.org/docs/latest/models.html#built-in-model-flavors).

### Scenario 2

Training: a custom model trained by own or a proprietary model  
Packaging: AML  
Deployment: AML  

You have a custom model trained in your own training environment or a proprietary model you are using and decide to use AML for model packaging and deployment due to its seamless integration with Azure services and compute target.

It's recommended to register your model to AML, package it with AML, and manage it in container registry or directly deploy it with AML workflow, so you can leverage the AML workflow for seamless model packaging and deployment, streamlined automation, and out-of-the-box best practices for AI/ML containerization.

Your custom model can be registered with AML by uploading the model artifact to the workspace, and AML allows model to be any serialized format, such as .pkl, .onnx, .h5, or a folder containing necessary files.

Vision model with CNN-based Architecture, such as ResNet, YOLO, and transformer-based architectures, such as Vision Transformers (ViT), DETr, are the common choices for vision tasks. CNN models are widely used for tasks like image classification, object detection, and segmentation.
Transformer models are widely used for tasks like multi-modal tasks combining vision and language, image-text retrieval, end-to-end object detection for improved detection accuracy, etc. where there is a need to capture long-range dependencies and process data in a global context more effectively. But the transformer model highly requires optimization for edge deployments due to its higher computational demands. AML supports both CNN-based and transformer-based architectures, and model optimization.

AML supports most computer vision model frameworks, especially the mainstream ML frameworks such as TensorFlow, PyTorch, ONNX, etc. However, for models with the less common model framework or proprietary frameworks, you must make sure to provide an environment definition conda.yml with the exact runtime dependencies such as libraries, OS packages, to ensure compatibility. For example, custom C++/Java-based frameworks require extra effort to package and integrate runtime dependencies.

For the scoring script, the specific functions, init() and run(), must be defined in this script for it to work with the inference router. During the deployment, it uses the registered model, inference environment, and scoring script to package the model and create a Kubernetes endpoint. Then AML will configure its inference router, other supporting services, and deploy all the components to edge.

During AML packaging and deployment, the inference router is retrieved from the Microsoft Container Registry (MCR) (Implied from [MS official document](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-kubernetes-inference-routing-azureml-fe?view=azureml-api-2&utm_source=chatgpt.com);
connection to the MCR is one of the connectivity requirements for deploying inference router to Arc AKS; though the documentation does not directly state that the inference router component is pulled from MCR. The Kubernetes EP created by AML is an abstract layer for all supporting Kubernetes services and exposes the model container via an HTTP REST API, with the inference router to be configured for traffic routing and autoscaling.

The model acceleration conversion is the same as in [Scenario 1](#scenario-1). During packaging, AML supports converting models from many frameworks. You need to check your custom model to make sure it is compatible with the ONNX format, via checking the supported ONNX conversion frameworks [here](https://onnx.ai/supported-tools).

For hardware acceleration model deployment, AML has native support to deploy, manage, and monitor your ONNX models in Azure like AML service, Ubuntu VM, Windows server VM.

For distributed inference acceleration, AML supports deploying models on GPU-enabled or FPGA compute targets, such as Azure Kubernetes Service (AKS). It supports inference scaling across multiple GPUs within a node or across multiple nodes in a cluster. The deployment configurations allow you to select hardware-accelerated nodes for inference. This feature is crucial for accelerating consistently high-demand inference workloads, e.g. real-time analytics.

For scenarios where GPUs are unavailable, AML supports optimized CPU inference using tools like Intel OpenVINO for ONNX models.

Considerations for this option:
Pros:

- Autoscaling and load balancing support are out-of-box if using AML deployment service.
- AML can handle the deployment of custom models regardless of the training environment or framework. Least effort of managing the model deployment in Azure, but not suitable for the production scenario where AML native deployment does not apply.
- For hardware acceleration of model deployment and inference, AML has native support for ONNX models in Azure, GPU nodes scaling, and CPU inference optimization.

Cons:

- AML-generated containers can be bulky though it has its own hardware acceleration support for model optimization. If there are other specific option of optimizing a model container more efficiently, AML won't be suitable for packing and deploy a large model.
- Overhead may be introduced by the AML built-in inference router feature for load balancing, scaling, and request handling, which may become a bottleneck for ultra-low-latency applications (for example, <10ms inference for high-speed video feeds). A configurable option with more manual control to reduce operational overhead would be helpful, unlike AML which fully controls the autoscaling logic and the user has less control of mitigating operational overhead.
- Custom frameworks and framework-specific dependencies may require extensive testing in your edge environment for compatibility with unique runtime dependencies and features. For example, a custom-built C++ libraries that are utilized by model but requires integration testing in a standard AML container.

### Scenario 3

Training: A custom model trained by own or a proprietary model  
Packaging: manual  
Deployment: other deployment tool such as GitOps/Flux, HPA (recommended)  

The vision processing tasks sometimes have more complexities than the case of using a statistical model for sensor data analysis and the vision model framework can be complex. Though the mainstream frameworks are still common and capable for most of the vision tasks, there might be the case that the core framework such as PyTorch or TensorFlow can be combined with other frameworks for the purpose of preprocessing, optimization, or image data fusion.
To make our evaluation more complete, we took the capability of supporting proprietary framework into consideration too.

In this scenario, AML is not chosen for model training, due to its lack of supporting the proprietary model framework, or the customer's preference for using other training tools and their own training environment. AML is also not used for model deployment, due to the lack of Git management support, or the customer's preference for using other deployment tools such as GitOps/Flux.

In this case, the ML workflow involves training a model, containerizing it as a standalone workload for the edge, and pushing it to a container registry. From there, GitOps/Flux is triggered to handle deployment and configure autoscaling control. This workflow is independent of AML services, providing complete control on customization and flexibility.

Since AML is bypassed, we lack the integrated hardware acceleration supports from AML. Therefore, alternative solutions are required for hardware optimization, such as ONNX runtime CPU/GPU execution provider for optimized inference, OpenVINO toolkit for computer vision CPU-based acceleration, model optimization toolkit for quantization and resizing, etc.

If the use case does not require AML native deployment but does require autoscaling (or manual scaling) during inference, there are two potential approaches for implementing autoscaling. The approach 2 is recommended due to its feasibility and broader support. A discussion of the two approaches is as below.

- Approach 1: Integrate AML inference router for autoscaling

  When using AML to containerize and deploy models, AML handles the fetching of the inference router component, configuration of the inference router, and other Kubernetes services with its created Kubernetes EP for autoscaling and routing.
  During AML deployment, the inference router is automatically configured by AML for each endpoint and is deployed alongside the model container in Kubernetes. The endpoint includes a scoring service (the model's HTTP REST API for inference), resource setting (CPU, memory limit, scaling), and additional AML-specific components.

  If you decide to bypass AML and use other deployment tool such as GitOps/Flux, but integrate AML inference router component for autoscaling control, the challenges would lie in
  - Fetching the inference router component from MCR. You have to ensure the permission to the inference router component from MCR.
  - Setting up routing configuration of the inference router with the model container, expose the model container via a Kubernetes EP, and setup resource limits, autoscaling, and other deployment parameters.
  This may require manual configuration of the inference router and EP with the same logic that AML service does. The inference router configuration is through [AML SDK AksWebService Class](https://learn.microsoft.com/en-us/python/api/azureml-core/azureml.core.webservice.akswebservice?view=azure-ml-py). The documentation for implementing this logic is limited.
  - Deploying the inference router with the model container during runtime.
  - Disabling HPA for the model container pod, as AML's inference router and HPA would conflict with each other. This may result in design complexity in managing the autoscaling and routing logic if combining with HPA for other workload autoscaling control.

- Approach 2: Use Kubernetes Horizontal Pod Autoscaler(HPA) for standalone model container autoscaling  

  HPA is a Kubernetes feature that scales the number of replicas of a deployment, stateful set, or replica set based on observed metrics such as CPU/memory utilization or custom-defined metrics. It functions similarly to the AML inference router scaling that allows the user to configure settings such as the model's utilization, or min/max replicas.
  But they conflict with each other, and as such, you should not use AML inference router while using HPA on the same inference workload pod. By using HPA, we can have more control with scaling approaches, such as manually setting the desired number of replicas, or setting custom thresholds for autoscaling.

  One thing to note is, using HPA to auto scale the model container is compatible with a model container created by AML since AML configures inference router as a separate component in AML-managed deployments, not directly embedded into the model container. Thus, a model container created by AML would not conflict with standalone deployment and HPA autoscaling.

  This approach provides flexibility and customization for generic scenarios of vision inference at the edge. It's capable for all types of model frameworks, even proprietary frameworks. The limitations and complexity of HPA will be discussed in a separate document.

Considerations for this option:
Pros:

- Because the AML inferencing router conflicts with HPA and other autoscaling tools, using HPA independently without integrating with AML autoscaling in its deployment service, provides greater control on autoscaling management and ensures a more cohesive solution design.
- This option is generic and capable of supporting proprietary model frameworks for complex vision tasks.
- HPA configurations provide greater flexibility and potentially lower operational overhead. In contrast, the autoscaling logic of the AML inference router is pre-defined and customization is less straightforward; thus, it offers less control for operational overhead concerns, which can be crucial in ultra-low-latency applications.

Cons:

- Unlike the previous options that utilize AML's out-of-box features for fully managed training platform and deployment configurations, this approach adds implementation and configuration complexities with custom training and deployment tool with HPA for standalone ML inference module.

## Recommendation and Future Considerations

This evaluation prioritizes popular tooling like GitOps/Flux and HPA for MLOps on edge preferred by customer projects nowadays, at the writing time for this document.

The preferred option depends on your design requirements and the model type. However, given current generally available (GA) Azure services, the MLOps option for the 3rd scenario is more generic for most vision model inferencing scenarios due to its flexibility; however, it is more complex to implement.

For future considerations, if any AIO deployment tool that will be publicly available later, we should consider using Azure tools and re-evaluate for the edge inference autoscaling and hardware acceleration capabilities.

## Resources

[AML ONNX acceleration support](https://learn.microsoft.com/en-us/azure/machine-learning/concept-onnx?view=azureml-api-2)

[Register your custom model to AML](https://learn.microsoft.com/en-us/azure/machine-learning/tutorial-deploy-model?view=azureml-api-2)

[How to package a model in AML](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-package-models?view=azureml-api-2&tabs=cli)

[Distributed training with AML](https://learn.microsoft.com/en-us/azure/machine-learning/concept-distributed-training?view=azureml-api-2)

[Understand the AML scoring script](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-online-endpoints?view=azureml-api-2&utm_source=chatgpt.com&tabs=cli#understand-the-scoring-script)

[Deploy a model to an hardware accelerated AKS cluster with AML](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-azure-kubernetes-service?view=azureml-api-1&tabs=python)

[Use Azure Machine Learning compute cluster to distribute a training or batch inference process across a cluster of CPU or GPU compute nodes in the cloud](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-create-attach-compute-cluster?view=azureml-api-2&tabs=python)

[Deploy AI using Microsoft Azure & ONNX for the OpenVINO Toolkit](https://www.intel.com/content/www/us/en/developer/videos/microsoft-azure-onnx-runtime-for-openvino.html#gs.j0ucc8)

[Implementing optimized CPU inference in AML using ONNX models and Intel's OpenVINO toolkit](https://learn.microsoft.com/en-us/shows/ai-show/combining-the-power-of-optimum-openvino-onnx-runtime-and-azure)
