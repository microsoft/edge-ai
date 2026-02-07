---
title: 'Kata: 500 - Edge AI Inference Platform Selection'
description: Compare edge AI inference platforms for real-time drone defect detection with performance, MLOps, and connectivity resilience requirements
author: Edge AI Team
ms.date: 2025-01-20
kata_id: adr-creation-500-edge-ai-inference-platform-selection
kata_category:
  - adr-creation
kata_difficulty: 5
estimated_time_minutes: 150
learning_objectives:
  - Evaluate edge AI inference platforms for real-time computer vision workloads
  - Balance performance optimization with MLOps automation and operational complexity
  - Design offline-capable edge inference architecture for connectivity-challenged environments
  - Create strategic ADRs for ML platform selection with deployment roadmaps
prerequisite_katas:
  - adr-creation-100-basic-messaging-architecture
  - adr-creation-200-advanced-observability-stack
  - adr-creation-400-service-mesh-selection
technologies:
  - Azure IoT Edge
  - ONNX Runtime
  - NVIDIA Triton
  - Azure Machine Learning
  - TensorRT
  - edge-ai
  - mlops
  - computer-vision
success_criteria:
  - Compare three edge AI inference platforms against performance, MLOps, and operational criteria
  - Analyze real-time inference requirements with latency budgets and throughput constraints
  - Evaluate offline operation capabilities and connectivity resilience strategies
  - Create strategic ADR with platform recommendation and 6-month deployment roadmap
ai_coaching_level: adaptive
scaffolding_level: light
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - adr-creation
search_keywords:
  - edge-ai-platform-selection
  - inference-platform-comparison
  - real-time-computer-vision
  - mlops-edge-deployment
  - drone-ai-inspection
  - nvidia-triton-azure-ml
  - onnx-edge-inference
  - offline-ml-inference
  - expert-adr-creation
---

## Quick Context

**You'll Learn**: Create sophisticated edge AI platform ADRs comparing inference engines, MLOps pipelines, and deployment strategies for real-time computer vision workloads.

**Prerequisites**: Completion of all previous ADR katas, understanding of machine learning inference, edge computing concepts, and computer vision fundamentals

**Real Challenge**: You're the Solutions Architect at **AeroSurvey Industries**, a drone inspection company serving power utilities, state DOTs, and telecom providers. Your current cloud-based AI defect detection pipeline causes **2-hour post-flight processing delays** and **fails completely in 30% of rural inspection sites** with poor connectivity. Inspectors waste time manually reviewing 50,000+ images per mission, and re-flights cost $250K/year due to missed defects.

**Fleet Context**:

- **20 Industrial Inspection Drones**: RTK-enabled professional drones (42MP camera, thermal imaging, LiDAR)
- **5 Ground Control Station Vehicles**: Field deployment with edge compute (NVIDIA Jetson AGX Orin)
- **Workload**: 50,000 images/mission × 5 missions/day = 250,000 images/day
- **Inspection Types**: Power line defects, bridge structural cracks, cell tower corrosion, wind turbine blade erosion
- **Detection Requirements**: Cracks, corrosion, thermal hotspots, structural damage with 95%+ accuracy

**The Stakes**: Need **real-time edge AI inference** (<2 seconds from image capture to defect alert) so drones can re-inspect identified defects **while still on-site**. $15M/year in inspection contracts require 48-hour reporting SLAs. Must operate in connectivity-challenged environments with full offline autonomy.

**Your Task**: Compare **three edge AI inference platforms** and create strategic ADR recommending platform with 6-month deployment roadmap covering pilot (1 station) → production (5 stations) → scale (15 stations).

## Essential Setup

**Required** (check these first):

- [ ] Completion of all previous ADR katas (messaging, observability, service mesh, cross-site VPN) with ADR evaluation framework expertise
- [ ] ML inference concepts: model serving (loading models into inference engine, accepting input data, running forward pass, returning predictions), quantization (FP32→INT8/FP16 for 4-8x size reduction and 2-4x speedup), model optimization (operator fusion, constant folding, pruning, knowledge distillation), training vs inference differences (backpropagation vs forward-only, hours vs milliseconds), hardware acceleration (GPUs for parallel operations, NPUs/TPUs for low power, CPU fallback)
- [ ] Model formats and framework trade-offs: ONNX (cross-framework, optimized for ONNX Runtime, framework-agnostic deployment), TensorFlow SavedModel (native TF format, TF Serving/Lite support, versioning built-in), PyTorch TorchScript (JIT compilation, PyTorch ecosystem compatibility, mobile deployment), framework selection criteria (cross-platform performance vs ecosystem integration vs debugging capabilities)
- [ ] Computer vision task types: image classification (single label per image, ResNet/EfficientNet/MobileNet/ViT architectures, 224x224 input), object detection (multiple objects with bounding boxes, YOLOv8/Faster R-CNN/EfficientDet, 640x640-1024x1024 input, NMS post-processing), semantic segmentation (per-pixel classification, U-Net/DeepLabV3+/Mask R-CNN/SegFormer, highest computational cost)
- [ ] Real-time processing constraints: AeroSurvey <2s end-to-end requirement (image capture 300-500ms, inference 500-1200ms, post-processing/alert 200-300ms), NVIDIA Jetson AGX Orin hardware (2048 CUDA cores, 64 Tensor cores, 32GB RAM, 275 TOPS INT8), power budget trade-offs (15W CPU-only 5-10 FPS, 30W balanced, 60W maximum 30-60 FPS)
- [ ] Edge compute resource constraints: ARM Cortex-A78AE CPU (12 cores 2.2 GHz for preprocessing/control), GPU (2048 CUDA cores Ampere for parallel inference), memory (32GB shared, 8-16GB for models/buffers, 2-4GB model size limit), power modes (15W/30W/60W with performance trade-offs)
- [ ] Edge-to-cloud connectivity patterns: connected mode (real-time telemetry streaming, cloud model management, centralized monitoring), occasionally connected (autonomous drone missions, sync after landing, deferred updates), offline-first (days/weeks without connectivity, local versioning/rollback, cached configuration)
- [ ] Offline operation requirements: model version mismatches during offline periods (continue with cached model, queue updates), telemetry queuing (store inference results/images on 500GB-1TB SSD, automatic sync with retry), degraded mode (critical operations with outdated model or reduced functionality until connectivity restored)
- [ ] MLOps workflows: model versioning (semantic Major.Minor.Patch, model registry with metadata/lineage, Git tag integration), deployment pipelines (CI/CD triggered by registry updates, validation→packaging→deployment→monitoring stages, staged rollout dev→staging→production), edge-specific considerations (OTA updates, bandwidth constraints with compression, offline device update queuing)
- [ ] Model monitoring and drift detection: inference monitoring (prediction distribution shifts, confidence score trends, latency/throughput tracking), data drift (input distribution changes vs training baseline), model drift (performance degradation, ground truth tracking), retraining triggers (accuracy drop >5%, confidence thresholds, quarterly scheduled retraining)
- [ ] Azure ML and IoT ecosystem: Azure ML workspace (compute resources, datastores, model registry, experiment tracking, pipeline orchestration), IoT Edge module deployment (container-based runtime, module lifecycle management, device manifests via IoT Hub), IoT Operations integration (unified data plane, MQTT/Kafka/HTTP support, dataflow pipelines, bidirectional edge-cloud communication)
- [ ] Time allocated: 150 minutes for ML/AI experts (Task 1 platform comparison 30 min, Task 2 decision framework 45 min, Task 3 ADR creation 75 min), or 180-240 minutes for learners new to ML/computer vision/edge AI (includes additional time for Azure ML documentation review, computer vision fundamentals study, edge AI best practices)

**Quick Validation**: Verify all previous ADR kata completion and access to Azure Machine Learning and IoT documentation.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 05 - Edge AI Inference Platform Selection kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Edge AI Inference Platform Research (25 minutes)

**What You'll Do**: Research three distinct edge AI inference platforms evaluating architecture, performance characteristics, MLOps capabilities, and deployment models for real-time computer vision at the edge.

**Steps**:

1. **Research** Azure IoT Edge + Custom ONNX Runtime architecture
   - [ ] Analyze Azure IoT Edge module deployment and ONNX Runtime inference capabilities
   - [ ] Focus on: custom model pipeline control, multi-framework support (PyTorch, TensorFlow, ONNX), Azure ecosystem integration
   - [ ] Evaluate: manual optimization requirements, DIY deployment pipeline complexity, hardware acceleration options
   - [ ] **Expected result**: Clear understanding of flexible, Azure-native approach with manual optimization trade-offs

2. **Research** NVIDIA Triton Inference Server architecture
   - [ ] Analyze purpose-built inference server with multi-framework and concurrent model support
   - [ ] Focus on: TensorRT auto-optimization, DeepStream video pipeline integration, production monitoring
   - [ ] Evaluate: GPU utilization efficiency, dynamic batching, model ensemble capabilities, configuration complexity
   - [ ] **Expected result**: Clear understanding of performance-optimized platform with NVIDIA ecosystem advantages

3. **Research** Azure Machine Learning Edge Deployment architecture
   - [ ] Analyze managed MLOps pipeline with Azure ML model registry and automated deployment
   - [ ] Focus on: integrated model versioning, simplified deployment automation, Azure monitoring integration
   - [ ] Evaluate: managed endpoint capabilities, framework support limitations, Azure Stack Edge appliance options
   - [ ] **Expected result**: Clear understanding of MLOps-first approach with managed infrastructure trade-offs

4. **Analyze** inference performance and optimization strategies
   - [ ] Compare model optimization techniques: TensorRT, ONNX quantization, pruning, knowledge distillation
   - [ ] Evaluate hardware acceleration: NVIDIA GPU (CUDA, TensorRT), Intel OpenVINO, ARM Mali
   - [ ] Consider throughput and latency: batch processing vs real-time streaming, multi-model concurrency
   - [ ] **Success check**: Can articulate platform architectures with quantified performance, optimization, and deployment trade-offs for real-time computer vision

### Task 2: Performance, MLOps, and Operational Analysis (20 minutes)

**What You'll Do**: Analyze competing requirements across inference performance, MLOps automation, connectivity resilience, and operational complexity dimensions.

**Steps**:

1. **Evaluate** inference performance and latency requirements
   - [ ] Latency budget analysis: <2 seconds from image capture to defect alert (capture → transfer → inference → alert)
   - [ ] Throughput requirements: 1 fps per drone × multiple concurrent drones per ground station
   - [ ] GPU utilization and power consumption: NVIDIA Jetson AGX Orin capabilities and constraints
   - [ ] Model optimization impact: TensorRT FP16 vs INT8 quantization, accuracy-performance trade-offs
   - [ ] **Expected result**: Quantified performance requirements matrix with latency budgets and throughput targets

2. **Assess** MLOps capabilities and model deployment automation
   - [ ] Model versioning and registry: centralized model management, version tracking, rollback capabilities
   - [ ] Deployment pipeline automation: push updates to 5 ground stations (→ 15 stations), weekly model improvements
   - [ ] A/B testing and canary deployments: validate model accuracy improvements before full rollout
   - [ ] Monitoring and observability: inference latency, accuracy metrics, model drift detection, GPU utilization
   - [ ] **Expected result**: Comprehensive MLOps evaluation framework addressing deployment automation and operational visibility

3. **Analyze** connectivity resilience and offline operation patterns
   - [ ] Offline autonomy requirements: 30% of sites have zero connectivity, 4-hour missions without cloud dependency
   - [ ] Model caching and version synchronization: local model storage, cloud sync strategies, version mismatch handling
   - [ ] Telemetry and metrics collection: queue metrics during offline operation, cloud catch-up when connectivity restored
   - [ ] Fallback behaviors: degraded mode operation, automatic retry logic, human alert escalation
   - [ ] **Expected result**: Offline operation architecture with specific patterns for connectivity loss scenarios

4. **Apply** Edge AI Decision Framework for structured platform evaluation
   - [ ] **Performance Dimension**: Score latency (<2 sec budget), throughput (fps per drone), GPU utilization efficiency, model optimization capabilities (TensorRT FP16 vs INT8)
   - [ ] **MLOps Dimension**: Score deployment automation (push to 5→15 stations), model versioning (registry, rollback), A/B testing support, monitoring integration (latency, accuracy, drift)
   - [ ] **Resilience Dimension**: Score offline autonomy (4-hour missions, 30% zero-connectivity sites), model caching strategies, telemetry queuing, degraded mode behavior
   - [ ] **Operational Dimension**: Score deployment complexity (2-person field crews), troubleshooting workflows, multi-vendor hardware support, team capability match (ML background, limited edge experience)
   - [ ] **Cost Dimension**: Score hardware requirements (Jetson compatibility, Azure Stack Edge option), software licensing, operational overhead, Azure ecosystem alignment
   - [ ] **Expected result**: Weighted scoring matrix ready for three-platform comparative analysis with quantified evidence for each dimension

5. **Consider** operational complexity and team capabilities
   - [ ] Edge deployment automation: 2-person field crews need simple deployment and troubleshooting workflows
   - [ ] Multi-vendor hardware support: NVIDIA Jetson today, potential Azure Stack Edge migration path
   - [ ] Integration complexity: existing Azure IoT Operations infrastructure, telemetry pipelines, client reporting systems
   - [ ] Team capability assessment: 5-person team with ML background but limited edge deployment experience
   - [ ] **Success check**: Multi-dimensional evaluation framework with weighted criteria ready for three-way platform comparison across all decision framework dimensions

### Task 3: Strategic ADR Creation with Deployment Roadmap (25 minutes)

**What You'll Do**: Create executive-level ADR with comprehensive platform comparison, strategic recommendation with performance and MLOps justification, and actionable 6-month deployment roadmap.

**Steps**:

1. **Perform** comprehensive three-way inference platform comparison
   - [ ] Create Context section using scenario from Quick Context (20 drones, 5 ground stations, 250K images/day, $15M contracts)
   - [ ] Score all platforms against weighted evaluation criteria with specific quantified evidence
   - [ ] Include: inference performance analysis (latency, throughput, GPU utilization, optimization capabilities)
   - [ ] Document: MLOps pipeline maturity (deployment automation, versioning, monitoring, A/B testing)
   - [ ] Analyze: offline operation support (model caching, sync strategies, degraded mode behavior)
   - [ ] Evaluate: operational complexity (deployment automation, troubleshooting, team capability match)
   - [ ] Consider: total cost (edge hardware, software licenses, operational overhead), Azure ecosystem alignment
   - [ ] **Expected result**: Comprehensive comparative analysis supporting strategic platform decision across all evaluation dimensions

2. **Document** strategic platform recommendation with multi-stakeholder justification
   - [ ] Present selected inference platform with clear rationale addressing performance, MLOps, operational, and business concerns
   - [ ] Include detailed justification: why this platform best meets <2 sec latency, offline autonomy, weekly model updates
   - [ ] Address risk assessment: vendor lock-in, migration complexity, performance bottlenecks, operational challenges
   - [ ] Document mitigation strategies: performance validation plan, deployment automation, team training, fallback options
   - [ ] Consider long-term implications: scalability to 15+ ground stations, multi-vendor hardware support, emerging AI frameworks
   - [ ] **Expected result**: Executive-level recommendation with comprehensive strategic justification ready for engineering and procurement approval

3. **Develop** 6-month phased deployment roadmap with success metrics
   - [ ] Phase 1 (Months 1-2): Pilot deployment - single ground station, performance validation, model optimization
   - [ ] Phase 2 (Months 3-4): Production rollout - 5 ground stations, MLOps pipeline automation, operational playbook
   - [ ] Phase 3 (Months 5-6): Scale preparation - expansion to 15 stations, multi-region deployment, advanced features
   - [ ] Include specific milestones: performance benchmarks (<2 sec validated), accuracy targets (95%+ defect detection)
   - [ ] Document deployment automation strategy: model registry setup, CI/CD pipeline, edge device provisioning
   - [ ] Define operational readiness criteria: monitoring dashboards, troubleshooting runbooks, team training completion
   - [ ] Establish success metrics: latency reduction (2 hours → 2 seconds), re-flight cost savings ($250K/year), SLA compliance (48-hour reporting)
   - [ ] **Success criteria**: Complete strategic ADR ready for executive approval with detailed platform recommendation, risk analysis, and actionable 6-month deployment plan

## Completion Check

**You've Succeeded When**:

- [ ] Created comprehensive ADR comparing Azure IoT Edge + ONNX, NVIDIA Triton, and Azure ML Edge platforms
- [ ] Addressed inference performance requirements with quantified latency and throughput analysis
- [ ] Evaluated MLOps capabilities including deployment automation, versioning, and monitoring
- [ ] Documented offline operation architecture and connectivity resilience strategies
- [ ] Developed 6-month phased deployment roadmap: pilot → production → scale
- [ ] ADR meets executive-level quality standards with sophisticated multi-factor analysis
- [ ] Included specific considerations for real-time computer vision and edge fleet management

---

## Reference Appendix

### Help Resources

- [Task Researcher Agent][task-researcher] — For systematic platform research and performance analysis
- [ADR Creation Agent][adr-create] — For professional documentation and strategic writing
- [ADR Solution Library][adr-library] — Templates and examples for reference
- [Azure IoT Edge][ms-azure-iot-edge] — Edge runtime and module deployment for Azure IoT solutions
- [NVIDIA Triton Inference Server][nvidia-triton] — Production-ready AI inference server with multi-framework support
- [Azure Machine Learning][ms-azure-ml] — End-to-end ML platform with edge deployment capabilities
- [ONNX Runtime][onnx-runtime] — Cross-platform, high-performance ML inference engine
- [TensorRT][nvidia-tensorrt] — NVIDIA's SDK for high-performance deep learning inference optimization
- [Azure IoT Operations][ms-azure-iot-operations] — Unified data plane for industrial IoT edge scenarios
- [Edge AI Best Practices][ms-edge-ai-best-practices] — Microsoft guidance for edge AI architecture patterns
- [MLOps for Edge Devices][ms-mlops-edge] — Model deployment and lifecycle management for edge environments
- [Real-time Computer Vision][opencv-docs] — OpenCV documentation for image processing and computer vision algorithms
- [Model Optimization Techniques][model-optimization] — Quantization, pruning, and knowledge distillation strategies
- [FAA Part 107][faa-part-107] — Commercial drone operation regulations
- [Industrial Inspection Use Cases][inspection-use-cases] — Real-world drone inspection scenarios and requirements
- [Previous ADRs](01-basic-messaging-architecture.md) — Reference methodology consistency across related decisions

### Professional Tips

- **Use the Edge AI Decision Framework from Task 2**: Apply the 5-dimensional scoring matrix (Performance, MLOps, Resilience, Operational, Cost) to systematically compare Azure IoT Edge + ONNX, NVIDIA Triton, and Azure ML Edge platforms with quantified evidence for each criterion - avoid subjective platform preferences without structured evaluation
- **Quantify latency budgets across pipeline stages**: Break down the <2 second requirement into component stages (image capture 200ms, transfer 300ms, inference 1000ms, alert routing 500ms) to identify optimization opportunities and validate platform capabilities with concrete measurements rather than generic "fast inference" claims
- **Design offline operation patterns explicitly**: Document specific behaviors for connectivity loss scenarios (model version mismatch during 4-hour offline mission, telemetry queue overflow, degraded mode with cached models, cloud catch-up on reconnection) with measurable recovery time objectives rather than assuming "it works offline"
- **Balance MLOps automation with edge deployment complexity**: Recognize the trade-off between sophisticated CI/CD pipelines (weekly model updates to 15 ground stations) and operational burden on 2-person field crews - prioritize deployment automation that reduces field troubleshooting over feature-rich platforms requiring ML expertise at every site

### Troubleshooting

- If latency targets are missed, profile each pipeline stage (capture, transfer, inference, alert) to isolate bottlenecks.
- For model deployment failures, check version mismatches and registry sync status.
- In offline scenarios, ensure telemetry is queued and retried on connectivity restoration.
- Use canary deployments and A/B testing to validate model improvements before full rollout.
- For hardware issues, validate GPU utilization and power constraints on Jetson devices.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction, then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[task-researcher]: /.github/agents/task-researcher.agent.md
[adr-create]: /.github/agents/adr-creation.agent.md
[adr-library]: /docs/solution-adr-library/
[ms-azure-iot-edge]: https://docs.microsoft.com/azure/iot-edge/
[nvidia-triton]: https://developer.nvidia.com/triton-inference-server
[ms-azure-ml]: https://docs.microsoft.com/azure/machine-learning/
[onnx-runtime]: https://onnxruntime.ai/
[nvidia-tensorrt]: https://developer.nvidia.com/tensorrt
[ms-azure-iot-operations]: https://docs.microsoft.com/azure/iot-operations/
[ms-edge-ai-best-practices]: https://docs.microsoft.com/azure/architecture/guide/iot-edge-ai/
[ms-mlops-edge]: https://docs.microsoft.com/azure/machine-learning/how-to-deploy-model-iot-edge
[opencv-docs]: https://docs.opencv.org/
[model-optimization]: https://pytorch.org/docs/stable/quantization.html
[faa-part-107]: https://www.faa.gov/uas/commercial_operators/
[inspection-use-cases]: https://www.droneindustryinsights.com/infrastructure-inspection/
