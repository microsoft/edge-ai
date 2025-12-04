---
title: Workload Orchestration (600-workload-orchestration)
description: Multi-cluster workload orchestration tools and solutions for Edge AI platform
author: Edge AI Platform Team
ms.date: 2025-11-20
keywords: workload orchestration, kalypso, azure arc, multi-cluster, gitops, kubernetes
estimated_reading_time: 4 minutes
---

Welcome to the Workload Orchestration components section. This grouping contains tools and solutions for orchestrating workloads across multiple clusters in edge and cloud environments.

## Overview

The 600-workload-orchestration components (600-699 range) provide workload orchestration capabilities for managing application deployments across distributed Kubernetes clusters. These components enable GitOps-based multi-cluster deployments, centralized configuration management, and automated workload distribution for edge computing scenarios.

## Components

| Component                                                                                    | Description                                                                                                  |
|----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| **[600-kalypso](./600-kalypso/README.md)**                                                   | Kalypso workload orchestration with bootstrap tooling and end-to-end tutorials for multi-cluster deployments |
| **[601-workload-orchestration-azure-arc](./601-workload-orchestration-azure-arc/README.md)** | Azure Arc workload orchestration service for managing distributed workloads (work in progress)               |

## Getting Started

1. **Review Component Documentation**: Check individual component README files for specific capabilities
2. **Select Orchestration Approach**: Choose between Kalypso or WorkLoad Orchestration for Azure Arc based on your requirements
3. **Follow Tutorials**: Use end-to-end tutorials to learn orchestration patterns
4. **Deploy to Your Clusters**: Apply orchestration to your edge and cloud clusters

## Use Cases

- **Multi-Site Deployments**: Deploy applications consistently across multiple edge locations
- **Environment Promotion**: Manage dev → qa → prod promotion flows across clusters
- **Configuration Management**: Centralize and version configuration across distributed environments
- **Edge Fleet Management**: Orchestrate workloads across large fleets of edge devices

For more information about the overall source code structure, see the [main source documentation](../README.md).

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
