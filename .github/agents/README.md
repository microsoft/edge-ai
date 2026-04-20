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

This directory contains specialized GitHub Copilot custom agent configurations designed to provide enhanced AI assistance for specific development workflows.

## Overview

Custom agents are advanced AI assistant configurations that enable specialized coaching, planning, and development support. Each agent is tailored for specific workflows and includes comprehensive tool access for deep project integration.

## Available Custom Agents

### [Task Researcher](task-researcher.agent.md)

Specialized research-only assistant for comprehensive project analysis and documentation.

- **Purpose**: Perform deep, comprehensive analysis for task planning through evidence-based discovery
- **Capabilities**: Multi-source analysis, evidence documentation, technical investigation
- **Best For**: Research phases, information gathering, technical analysis
- **Philosophy**: Research-only operations with evidence-based findings

### [ADR Creation](adr-creation.agent.md)

Interactive architectural decision record creation with comprehensive research and analysis capabilities.

- **Purpose**: Guide users through collaborative ADR creation using solution library templates
- **Capabilities**: Real-time document building, research integration, decision analysis, template compliance
- **Best For**: Architecture decisions, technical documentation, collaborative analysis
- **Philosophy**: Interactive markdown collaboration with progressive content development

### [Security Plan Creator](security-plan-creator.agent.md)

Expert security architect for creating comprehensive cloud security plans with threat modeling and risk assessment.

- **Purpose**: Analyze blueprint architectures and create actionable security plans with specific threat mitigations
- **Capabilities**: Blueprint analysis, threat assessment, operational data flow modeling, security documentation
- **Best For**: Security planning, threat modeling, compliance documentation, risk assessment
- **Philosophy**: Component-specific analysis with actionable, implementable security measures

## Usage Guidelines

### Selecting the Right Agent

1. **Research and Analysis**: Use Task Researcher for comprehensive project investigation
2. **Architecture Documentation**: Use ADR Creation for collaborative decision records
3. **Security Planning**: Use Security Plan Creator for threat analysis and security documentation

> **Note**: Additional agents for task planning and prompt engineering are available through the [hve-core](https://github.com/microsoft/hve-core) VS Code extension.

### Activation

Custom agents are activated through GitHub Copilot's interface by selecting the appropriate `.agent.md` file as context for your conversation.

### Integration

All custom agents are designed to integrate with the broader project ecosystem:

- Reference project standards and conventions
- Utilize comprehensive tool access for file operations
- Connect to documentation and guidance resources
- Support transitions between different assistance agents

## Related Resources

- **[Instructions](../instructions/README.md)**: Context-specific development instructions
- **[Prompts](../prompts/README.md)**: Reusable prompts for specific tasks
- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)**: Comprehensive AI assistance documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
