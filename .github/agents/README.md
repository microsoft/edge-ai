---
title: GitHub Copilot Custom Agents
description: Specialized AI assistance agents for enhanced development workflows and coaching
author: Edge AI Team
ms.date: 2025-01-11
ms.topic: reference
estimated_reading_time: 3
keywords:
  - github copilot
  - custom agents
  - ai assistance
  - coaching
  - task planning
  - prompt engineering
---

This directory contains repository-specific GitHub Copilot custom agent configurations for Edge AI development workflows.

## Overview

Custom agents are advanced AI assistant configurations that enable specialized coaching, planning, and development support. Local agents in this directory are tailored to Edge AI workflows. Shared planning, research, review, ADR, security planning, workback planning, and implementation agents are provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

## Available Custom Agents

### [Camera Onboarding](camera-onboarding.agent.md)

Specialized agent for onboarding cameras from discovery manifests into edge application configurations.

* **Purpose**: Map camera discovery manifest fields to app-specific configs for 500-level applications
* **Capabilities**: Manifest validation, Terraform device/asset generation, env var generation, credential resolution
* **Best For**: Onboarding discovered cameras to 508-media-connector, 510-onvif-connector, and Camera Dashboard
* **Philosophy**: Pluggable output generator pattern — one generator per target app

### [WASM Operator Builder](wasm-operator-builder.agent.md)

Specialized implementation assistant for Rust-based WebAssembly operators in Azure IoT Operations dataflow graphs.

* **Purpose**: Build and integrate WASM operator modules for Edge AI application workloads
* **Capabilities**: Rust operator implementation, graph schema updates, Terraform integration, validation guidance
* **Best For**: WASM map, filter, accumulate, and ONNX operator development
* **Philosophy**: Follow established operator templates and deployment conventions

## Usage Guidelines

### Selecting the Right Agent

1. **Camera Onboarding**: Use Camera Onboarding to generate app configs from discovery manifests
2. **WASM Operator Development**: Use WASM Operator Builder for Rust-based operator implementation

> **Note**: Shared agents for ADR creation, task planning, task research, PR review, security planning, workback planning, implementation support, and prompt engineering are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

### Activation

Custom agents are activated through GitHub Copilot's interface by selecting the appropriate `.agent.md` file as context for your conversation.

### Integration

All custom agents are designed to integrate with the broader project ecosystem:

* Reference project standards and conventions
* Utilize comprehensive tool access for file operations
* Connect to documentation and guidance resources
* Support transitions between local agents and shared HVE Core agents

## Related Resources

* **[Instructions](../instructions/README.md)**: Context-specific development instructions
* **[Prompts](../prompts/README.md)**: Reusable prompts for specific tasks
* **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)**: Comprehensive AI assistance documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
