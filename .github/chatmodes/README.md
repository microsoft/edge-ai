---
title: GitHub Copilot Chat Modes
description: Specialized AI assistance modes for enhanced development workflows and coaching
author: Edge AI Team
ms.date: 06/18/2025
ms.topic: reference
estimated_reading_time: 3
keywords:
  - github copilot
  - chat modes
  - ai assistance
  - coaching
  - task planning
  - prompt engineering
---

This directory contains specialized GitHub Copilot chat mode configurations designed to provide enhanced AI assistance for specific development workflows and learning scenarios.

## Overview

Chat modes are advanced AI assistant configurations that enable specialized coaching, planning, and development support. Each mode is tailored for specific workflows and includes comprehensive tool access for deep project integration.

## Available Chat Modes

### [PraxisWorx Kata Coach](praxisworx-kata-coach.chatmode.md)

Interactive AI coaching for focused practice exercises with progress tracking and resumption capabilities.

- **Purpose**: Guide learners through hands-on discovery using OpenHack-style methodology
- **Capabilities**: Socratic questioning, progress tracking, mode transition guidance
- **Best For**: Skill-building exercises, practice scenarios, iterative learning
- **Philosophy**: Teach a person to fish - discovery over direct answers

### [PraxisWorx Lab Coach](praxisworx-lab-coach.chatmode.md)

Complex training lab coaching for multi-component systems and comprehensive scenarios.

- **Purpose**: Support learners through complex, multi-step laboratory exercises
- **Capabilities**: Multi-component guidance, system integration coaching, troubleshooting
- **Best For**: Advanced labs, system deployments, complex integrations
- **Philosophy**: Structured guidance for comprehensive real-world scenarios

### [Task Planner](task-planner.chatmode.md)

Comprehensive task planning with research capabilities and systematic implementation planning.

- **Purpose**: Create actionable task plans through iterative research and progressive planning
- **Capabilities**: Research automation, plan documentation, requirement analysis
- **Best For**: Project planning, requirement gathering, implementation strategy
- **Philosophy**: Research-first planning with validated project context

### [ADR Creation](adr-creation.chatmode.md)

Interactive architectural decision record creation with comprehensive research and analysis capabilities.

- **Purpose**: Guide users through collaborative ADR creation using solution library templates
- **Capabilities**: Real-time document building, research integration, decision analysis, template compliance
- **Best For**: Architecture decisions, technical documentation, collaborative analysis
- **Philosophy**: Interactive markdown collaboration with progressive content development

### [Prompt Builder](prompt-builder.chatmode.md)

Expert prompt engineering and validation system for creating high-quality AI prompts.

- **Purpose**: Engineer and validate effective prompts using expert principles
- **Capabilities**: Prompt analysis, improvement iteration, validation testing
- **Best For**: Prompt optimization, AI instruction refinement, quality assurance
- **Philosophy**: Iterative engineering with built-in validation cycles

## Usage Guidelines

### Selecting the Right Mode

1. **Learning and Skill Building**: Use PraxisWorx Kata Coach for focused practice
2. **Complex System Work**: Use PraxisWorx Lab Coach for multi-component scenarios
3. **Project Planning**: Use Task Planner for strategic planning and research
4. **Architecture Documentation**: Use ADR Creation for collaborative decision records
5. **Prompt Development**: Use Prompt Builder for AI instruction optimization

### Activation

Chat modes are activated through GitHub Copilot's interface by selecting the appropriate `.chatmode.md` file as context for your conversation.

### Integration

All chat modes are designed to integrate with the broader project ecosystem:

- Reference project standards and conventions
- Utilize comprehensive tool access for file operations
- Connect to documentation and guidance resources
- Support transitions between different assistance modes

## Related Resources

- **[Instructions](../instructions/README.md)**: Context-specific development instructions
- **[Prompts](../prompts/README.md)**: Reusable prompts for specific tasks
- **[AI-Assisted Engineering Guide](../../docs/contributing/ai-assisted-engineering.md)**: Comprehensive AI assistance documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
