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

### [ADR Creation](adr-creation.chatmode.md)

Interactive architectural decision record creation with comprehensive research and analysis capabilities.

- **Purpose**: Guide users through collaborative ADR creation using solution library templates
- **Capabilities**: Real-time document building, research integration, decision analysis, template compliance
- **Best For**: Architecture decisions, technical documentation, collaborative analysis
- **Philosophy**: Interactive markdown collaboration with progressive content development

### [ADO PRD to Work Item](ado-prd-to-wit.chatmode.md)

Product Manager expert for analyzing PRDs and planning Azure DevOps work item hierarchies.

- **Purpose**: Transform Product Requirements Documents into structured Azure DevOps work item plans
- **Capabilities**: PRD analysis, codebase discovery, work item planning, handoff documentation
- **Best For**: Epic/Feature/User Story planning, work item creation, backlog management
- **Philosophy**: Progressive planning with phased discovery and structured handoff

### [PR Review](pr-review.chatmode.md)

Comprehensive Pull Request review assistant ensuring code quality, security, and convention compliance.

- **Purpose**: Conduct thorough PR reviews with expert-level scrutiny across all quality dimensions
- **Capabilities**: Multi-phase review workflow, instruction compliance checking, actionable feedback generation
- **Best For**: Code reviews, security validation, convention enforcement, quality assurance
- **Philosophy**: Holistic systems perspective with focus on long-term maintainability

### [PRD Builder](prd-builder.chatmode.md)

Product Requirements Document builder with guided Q&A and reference integration.

- **Purpose**: Create comprehensive, actionable PRDs through structured discovery and iterative refinement
- **Capabilities**: Progressive questioning, reference integration, state tracking, session resumption
- **Best For**: Product planning, requirements gathering, stakeholder alignment
- **Philosophy**: Build through conversation with measurable, testable requirements

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

### [Prompt Builder](prompt-builder.chatmode.md)

Expert prompt engineering and validation system for creating high-quality AI prompts.

- **Purpose**: Engineer and validate effective prompts using expert principles
- **Capabilities**: Prompt analysis, improvement iteration, validation testing
- **Best For**: Prompt optimization, AI instruction refinement, quality assurance
- **Philosophy**: Iterative engineering with built-in validation cycles

### [Security Plan Creator](security-plan-creator.chatmode.md)

Expert security architect for creating comprehensive cloud security plans with threat modeling and risk assessment.

- **Purpose**: Analyze blueprint architectures and create actionable security plans with specific threat mitigations
- **Capabilities**: Blueprint analysis, threat assessment, operational data flow modeling, security documentation
- **Best For**: Security planning, threat modeling, compliance documentation, risk assessment
- **Philosophy**: Component-specific analysis with actionable, implementable security measures

### [Task Planner](task-planner.chatmode.md)

Comprehensive task planning with research capabilities and systematic implementation planning.

- **Purpose**: Create actionable task plans through iterative research and progressive planning
- **Capabilities**: Research automation, plan documentation, requirement analysis
- **Best For**: Project planning, requirement gathering, implementation strategy
- **Philosophy**: Research-first planning with validated project context

### [Task Researcher](task-researcher.chatmode.md)

Specialized research-only assistant for comprehensive project analysis and documentation.

- **Purpose**: Perform deep, comprehensive analysis for task planning through evidence-based discovery
- **Capabilities**: Multi-source analysis, evidence documentation, technical investigation
- **Best For**: Research phases, information gathering, technical analysis
- **Philosophy**: Research-only operations with evidence-based findings

### [Workback](workback.chatmode.md)

AI-powered assistant for creating and refining workback schedules with strategic insights.

- **Purpose**: Streamline engagement planning by automating schedule calculations and surfacing actionable options
- **Capabilities**: Generate workback schedules based on inputs (scope, resources, timeline), quantify gaps between target vs. feasible deployment, suggest strategic options with risk assessment, future roadmap includes visual charts (Gantt) and holiday-aware scheduling
- **Best For**: Program managers, project leads, and teams managing complex timelines and resource constraints
- **Philosophy**: Empower decision-making through data-driven insights—reduce manual effort, increase clarity, and enable collaboration

## Usage Guidelines

### Selecting the Right Mode

1. **Architecture Documentation**: Use ADR Creation for collaborative decision records
2. **Work Item Planning**: Use ADO PRD to Work Item for transforming PRDs into Azure DevOps work items
3. **Code Review**: Use PR Review for comprehensive pull request analysis and quality assurance
4. **Product Planning**: Use PRD Builder for creating and refining product requirements documents
5. **Learning and Skill Building**: Use PraxisWorx Kata Coach for focused practice
6. **Complex System Work**: Use PraxisWorx Lab Coach for multi-component scenarios
7. **Prompt Development**: Use Prompt Builder for AI instruction optimization
8. **Security Planning**: Use Security Plan Creator for threat analysis and security documentation
9. **Project Planning**: Use Task Planner for strategic planning after research is complete
10. **Research and Analysis**: Use Task Researcher for comprehensive project investigation
11. **Schedule Planning**: Use Workback for creating workback schedules and managing complex timelines

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
