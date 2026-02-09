---
title: 'Kata: 100 - Edge Resource Management and Optimization'
description: Learn to deploy and optimizing Azure IoT Operations blueprints in resource-constrained edge environments with effective monitoring and troubleshooting strategies
author: microsoft/edge-ai
ms.date: 2025-01-20
kata_id: edge-deployment-100-resource-management
kata_category:
  - edge-deployment
kata_difficulty: 1
estimated_time_minutes: 45
learning_objectives:
  - Understand how CPU, memory, and storage limitations impact edge deployments
  - Apply resource optimization techniques to size deployments appropriately for constrained environments
  - Implement effective resource monitoring and alerting to catch constraints before production impact
  - Troubleshoot and resolve common resource-related deployment failures
  - Design resource-aware deployment strategies balancing functionality with device capabilities
prerequisite_katas:
  - edge-deployment-100-deployment-basics
technologies:
  - Terraform
  - Azure
  - Kubernetes
success_criteria:
  - Accurately analyze resource requirements and constraints for edge deployment
  - Deploy blueprint with appropriate resource sizing showing 30%+ efficiency improvement
  - Implement working resource monitoring with meaningful alerts for CPU, memory, storage
  - Successfully troubleshoot and resolve at least one resource-related deployment failure
  - Create clear documentation of optimization decisions and monitoring approach
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - Underestimating edge device resource requirements leading to deployment failures
  - Optimizing too aggressively and causing functionality issues
  - Implementing monitoring without meaningful alerts or thresholds
  - Not testing optimizations under realistic edge workloads
requires_azure_subscription: true
requires_local_environment: true
tags:
  - edge-deployment
search_keywords:
  - edge-resource-management
  - resource-optimization
  - kubernetes-monitoring
  - edge-constraints
  - deployment-optimization
---

## Quick Context

**What you'll learn**: How to deploy and optimize Azure IoT Operations blueprints in resource-constrained edge environments, implementing monitoring and troubleshooting strategies for production reliability.

**Prerequisites**:

- Completion of edge-deployment kata 01 (deployment basics)

- Understanding of blueprint structure and dependencies

- Access to Azure subscription with IoT Operations resources

- Basic knowledge of Kubernetes resource management concepts

**Real challenge**: Your team needs to deploy IoT Operations to edge devices with limited resources (8GB RAM, 4 CPU cores, 128GB storage). Standard deployments fail or perform poorly because they're sized for cloud environments. You need to optimize for edge constraints while maintaining functionality.

**Your task**: Deploy a resource-optimized IoT Operations blueprint to an edge environment, implement monitoring to track resource usage, and demonstrate your deployment runs reliably within edge constraints.

## Essential Setup

- [ ] Completed edge-deployment-100-deployment-basics kata; edge environment (K3s/AKS EE) with Arc enabled
- [ ] Edge device baseline known (CPU, RAM, storage); kubectl and metrics-server/Azure Monitor access
- [ ] Azure resources (IoT Ops prerequisites); blueprint selected (`minimum-single-node-cluster` recommended)
- [ ] Kubernetes fundamentals (pods, deployments, services, namespaces, resource management)
- [ ] kubectl commands (get, describe, logs, top for monitoring); CPU/memory requests and limits concepts
- [ ] ⚠️ **Cost Warning**: IoT Operations costs $15-30/day even when idle - complete and cleanup within one session
- [ ] Budget allocated: **$15-30 USD/day** | ⏱️ **90 minutes** (40-70 min provisioning + planning/optimization/cleanup)

**Quick Validation**: Verify cluster connectivity with `kubectl version && terraform --version`.
>
> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 02 - Edge Resource Management and Optimization kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Resource Constraint Analysis and Planning (20-25 minutes)

**What You'll Do**: Analyze your edge environment's resource constraints, assess blueprint requirements, and create an optimization plan.

**Steps**:

1. **Assess edge device resources**
   - [ ] Run: `kubectl top nodes` to see current node resource usage
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I need to assess the resource capacity of my Kubernetes cluster for deploying Azure IoT Operations. Can you help me:
     1. Get detailed resource information (total CPU, memory, storage) for my cluster nodes
     2. Calculate currently used vs available resources
     3. Understand what capacity I have available for new IoT Operations deployments
     Provide specific kubectl commands I should run.
     ```

   - [ ] Run the suggested commands and document the results
   - [ ] Document baseline resources: Total CPU, memory, storage, and current utilization
   - [ ] Identify available capacity: Calculate resources available for new deployments
   - [ ] **Expected result**: Clear baseline showing total resources and available capacity (e.g., "8GB RAM total, 3GB currently used, 5GB available")

2. **Analyze blueprint resource requirements**
   - [ ] Open your chosen blueprint (e.g., `blueprints/minimum-single-node-cluster/terraform/`)
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I'm planning to deploy the [blueprint-name] blueprint to an edge environment. Can you help me:
     1. Understand what Azure IoT Operations components this blueprint deploys
     2. Estimate typical CPU and memory requirements for each major component
     3. Calculate total resource requirements (sum of all components)
     4. Identify which components are most resource-intensive
     Include specific numbers (e.g., "MQ Broker: 1 CPU, 2GB RAM") so I can plan capacity.
     ```

   - [ ] Review component resource requests/limits in the deployment files
   - [ ] Create an estimate: Sum CPU, memory, and storage requirements for all components
   - [ ] **Expected result**: Blueprint resource estimate (e.g., "MQ Broker: 1 CPU, 2GB RAM; Storage: 0.5 CPU, 1GB RAM; Total: ~4GB RAM")

3. **Identify optimization opportunities**
   - [ ] Compare blueprint requirements against available capacity
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I have an edge device with [X]GB RAM, [Y] CPU cores, and [Z]GB storage. My blueprint requires approximately [resources from Step 2]. Can you help me:
     1. Identify which components can be safely scaled down for edge deployment
     2. Suggest specific optimization strategies (reduce replicas, lower resource limits, disable optional features)
     3. Estimate resource savings for each optimization
     4. Prioritize optimizations by impact vs risk (high-impact, low-risk first)
     Provide specific configuration changes I can make in Terraform or Kubernetes manifests.
     ```

   - [ ] Document 3-5 concrete optimization strategies with expected resource savings
   - [ ] Prioritize optimizations: High-impact changes with low risk
   - [ ] **Success check**: You have a specific optimization plan listing 3-5 concrete changes with expected resource savings

4. **Document resource plan**
   - [ ] Create a resource planning document including **Edge device specifications**, **Blueprint component requirements**, **Optimization strategies to apply**, **Expected resource usage after optimization**
   - [ ] **Expected result**: Clear resource plan showing how optimized deployment fits within edge constraints

### Task 2: Optimized Deployment Execution (25-30 minutes)

**What You'll Do**: Apply resource optimizations and deploy the blueprint to your edge environment with appropriate sizing.

**Steps**:

1. **Apply resource optimizations**
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I need to apply resource optimizations to the [blueprint-name] blueprint for edge deployment. My optimization plan is:
     [paste your plan from Task 1 Step 3]

     Can you help me:
     1. Identify which Terraform files control resource limits for IoT Operations components
     2. Show me exactly what configuration values to change (provide before/after examples)
     3. Explain how to reduce replica counts where appropriate for single-node edge deployment
     4. Configure storage sizes appropriately for edge device capacity
     Provide the specific file paths and configuration blocks I need to modify.
     ```

   - [ ] Navigate to the blueprint terraform directory: `cd blueprints/[blueprint-name]/terraform`
   - [ ] Apply the suggested modifications to resource configurations
   - [ ] Reduce replica counts where appropriate (e.g., single replica for non-HA edge deployment)
   - [ ] Configure storage sizes appropriately (match edge device capacity, not cloud defaults)
   - [ ] **Expected result**: Modified blueprint configuration with resource optimizations applied

2. **Deploy with resource monitoring**
   - [ ] Open a second terminal window and run: `watch -n 5 kubectl top nodes` to monitor resources during deployment
   - [ ] In the blueprint directory, initialize Terraform: `terraform init`
   - [ ] Create terraform.tfvars with your configuration (use AI assistance from Kata 01 if needed)
   - [ ] Review the deployment plan: `terraform plan -out=tfplan`
   - [ ] Execute deployment: `terraform apply tfplan`
   - [ ] Watch for resource pressure indicators in the monitoring terminal — **High memory usage** (>85% of capacity), **CPU throttling or sustained high CPU**, **Pod evictions** (check with `kubectl get events --all-namespaces | grep Evicted`)
   - [ ] Deployment will take 40-70 minutes - monitor continuously
   - [ ] **Expected result**: Deployment progresses with resource usage staying within acceptable limits (<80% memory, <80% CPU sustained)

3. **Validate deployment health**
   - [ ] Check all pods are running: `kubectl get pods --all-namespaces | grep -v Running | grep -v Completed`
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace My IoT Operations deployment just completed. Can you help me verify it's healthy and functional:
     1. What kubectl commands show the health status of key IoT Operations components (MQ Broker, Storage, Data Processor)?
     2. How do I verify each component is ready and operational?
     3. What's a simple test I can run to verify basic MQTT message publishing functionality?
     Provide specific commands I can run to validate the deployment.
     ```

   - [ ] Run the suggested validation commands
   - [ ] Verify key components are ready using these commands — **MQ Broker**: `kubectl get broker -n azure-iot-operations`, **Data Processor**: `kubectl get aio-dataprocessor -n azure-iot-operations` (if deployed), **All IoT Operations pods**: `kubectl get pods -n azure-iot-operations`, **Basic functionality**: Send a test message through MQ Broker (follow AI guidance)
   - [ ] **Expected result**: All components running, health checks passing, basic functionality verified

4. **Compare optimization results**
   - [ ] Measure actual resource usage: `kubectl top pods --all-namespaces`
   - [ ] Calculate resource efficiency improvement compared to unoptimized deployment
   - [ ] Ask: "What's the typical resource usage for a standard vs. optimized IoT Operations deployment?"
   - [ ] **Success check**: Demonstrate 30%+ resource efficiency improvement (e.g., 6GB RAM vs. 9GB unoptimized) while maintaining functionality

### Task 3: Resource Monitoring and Validation (15-20 minutes)

**What You'll Do**: Implement resource monitoring with alerts to detect constraints before they impact production.

**Steps**:

1. **Set up continuous resource monitoring**
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I need to set up continuous resource monitoring for my edge IoT Operations deployment. Can you help me:
     1. Determine if metrics-server is already installed in my cluster (kubectl command)
     2. Show me how to deploy metrics-server if needed
     3. Explain monitoring options (kubectl + scripting vs Azure Monitor vs Prometheus)
     4. Recommend the best approach for a single-node edge deployment
     Provide specific commands and configuration examples.
     ```

   - [ ] Check if metrics-server exists: `kubectl get deployment metrics-server -n kube-system`
   - [ ] Deploy metrics-server if not present: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
   - [ ] Wait for metrics-server to be ready: `kubectl wait --for=condition=available --timeout=60s deployment/metrics-server -n kube-system`
   - [ ] Verify metrics collection: `kubectl top nodes` and `kubectl top pods --all-namespaces`
   - [ ] **Expected result**: Working monitoring system that tracks CPU, memory, and storage usage

2. **Implement resource alerting**
   - [ ] Define alerting thresholds based on your edge device capacity — **Memory threshold** (alert at 80% of total capacity), **CPU threshold** (alert at 80% sustained for 5+ minutes), **Storage threshold** (alert at 85% of available disk)
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I need to set up resource alerts for my edge Kubernetes cluster. Can you help me:
     1. Create a simple shell script that monitors resource usage and sends alerts
     2. Show me how to configure alerts for memory >80%, CPU >80% sustained, storage >85%
     3. Explain how to test the alerts by simulating resource pressure
     4. Recommend alert notification methods for edge environments (email, webhook, logging)
     Provide working code examples I can adapt.
     ```

   - [ ] Create alert script or configure monitoring tool based on AI guidance
   - [ ] Test alerts by simulating resource pressure (follow AI suggestions)
   - [ ] **Expected result**: Working alert system that notifies on resource constraints

3. **Document monitoring strategy**
   - [ ] Copy and paste this prompt to your AI assistant:

     ```text
     @workspace I need to create a production resource monitoring runbook for my edge IoT Operations deployment. Can you help me create documentation that includes:
     1. Resource thresholds and alert definitions (when to alert, severity levels)
     2. Monitoring commands and tools (kubectl commands, dashboard access)
     3. Response procedures for each alert type (memory high, CPU high, storage high)
     4. Escalation paths and contact information structure
     Provide a template I can customize with my specific values.
     ```

   - [ ] Create monitoring documentation file (e.g., `monitoring-runbook.md`) based on AI template
   - [ ] Fill in your specific thresholds, commands, and contact information
   - [ ] **Success check**: Clear monitoring documentation that team members can follow

4. **Validate production readiness**
   - [ ] Run the deployment for 30+ minutes under monitoring
   - [ ] Verify resource usage remains stable
   - [ ] Check for memory leaks, CPU spikes, or storage growth issues
   - [ ] Document any resource patterns or considerations for production
   - [ ] **Expected result**: Deployment demonstrates stable resource usage over time with no constraints

5. **Cleanup deployed resources (MANDATORY)**
   - [ ] **CRITICAL**: Do not skip this step - IoT Operations costs $15-30+ per day even when idle
   - [ ] Navigate to blueprint directory: `cd blueprints/[blueprint-name]/terraform`
   - [ ] Destroy all resources: `terraform destroy`
   - [ ] Type `yes` to confirm destruction
   - [ ] Wait 15-25 minutes for complete cleanup
   - [ ] Verify cleanup with Azure CLI:

     ```bash
     az resource list --resource-group [resource-group-name] --output table
     ```

   - [ ] Should return empty result or "No resources found"
   - [ ] Verify in Azure Portal: Navigate to resource groups and confirm deletion
   - [ ] **Manual cleanup if needed**: If resources remain after terraform destroy:

     ```bash
     az group delete --name [resource-group-name] --yes --no-wait
     ```

   - [ ] **Expected result**: All deployed Azure resources deleted, no ongoing costs

## Completion Check

You have successfully completed this kata when:

- ✅ **Resource Analysis Done**: You've documented edge device resources, blueprint requirements, and optimization opportunities

- ✅ **Optimized Deployment Running**: Blueprint deployed with resource optimizations showing 30%+ efficiency improvement

- ✅ **Monitoring Active**: Resource monitoring and alerting implemented with meaningful thresholds

- ✅ **Issues Resolved**: Successfully troubleshot any resource-related deployment failures that occurred

- ✅ **Strategy Documented**: Clear documentation of resource decisions, monitoring approach, and production considerations

- ✅ **Resources Cleaned Up**: All Azure resources deleted with verification (no ongoing costs)

**Validation questions**:

1. What are the key resource constraints for your edge environment and how did you optimize for them?

2. How much resource efficiency improvement did you achieve and what techniques were most effective?

3. How does your monitoring system detect resource constraints before they impact production?

4. What resource-related issues did you encounter and how did you resolve them?

5. How did you verify complete resource cleanup and cost elimination?

---

## Reference Appendix

### Help Resources

- [Azure IoT Operations Resource Requirements](https://learn.microsoft.com/azure/iot-operations/) - Official sizing guidance

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) - Resource requests and limits

- [K3s Resource Optimization](https://docs.k3s.io/) - Lightweight Kubernetes best practices

- [Edge Computing Resource Patterns](https://learn.microsoft.com/azure/architecture/example-scenario/iot/introduction-to-solutions) - Edge architecture guidance

- Repository blueprints: `blueprints/minimum-single-node-cluster/` - Example optimized deployment

### Professional Tips

- Start with conservative resource estimates and tune based on actual usage patterns - monitor for at least 24-48 hours before declaring optimization successful
- Test optimizations under realistic workloads, not just idle conditions - idle resource usage doesn't reflect production patterns
- For edge deployments, typical resource allocations: IoT Operations core (1-2 CPU, 2-4GB RAM), Message Broker (250-500m CPU, 256-512MB RAM), Data Processing (500m-1 CPU, 512MB-2GB RAM)
- Set resource requests for guaranteed capacity and limits at 2x requests for predictable workloads to allow bursting
- Use `kubectl top pods` continuously during deployment for rightsizing resources based on observed patterns
- Balance optimization with operational complexity - simpler configurations are often better for edge environments
- Document resource decisions for future team members and consider using resource quotas to prevent exhaustion

### Troubleshooting

**Deployment fails with "Insufficient resources" errors**:

- Check node capacity: `kubectl describe nodes` for allocatable resources

- Review pod resource requests: Some components may request more than available

- Solution: Reduce resource requests or upgrade edge device capacity

**Pods show OOMKilled status**:

- Memory limit set too low for actual component needs

- Check: `kubectl describe pod <pod-name>` for memory limit and usage

- Solution: Increase memory limits incrementally and test under load

**CPU throttling impacts performance**:

- Component using more CPU than limit allows

- Monitor: `kubectl top pods` for CPU usage patterns

- Solution: Increase CPU limits or optimize workload (reduce polling frequency, batch processing)

---

Kata 02 - Edge Resource Management and Optimization | Edge AI Accelerator Learning Platform | Crafted with precision by the Edge AI Team using GitHub Copilot

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
