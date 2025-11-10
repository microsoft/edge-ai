---
title: AI-Assisted Engineering Katas
description: Streamlined practice exercises for developing proficiency in AI-powered development workflows and patterns
author: Edge AI Team
ms.date: 2025-06-16
ms.topic: kata-category
estimated_reading_time: 5
difficulty: foundation to advanced
duration: 45-90 minutes
# Learning Platform Integration
category: ai-assisted-engineering
prerequisite_katas: []
role_relevance:
  - developer
  - solution-architect
  - edge-engineer
target_audience:
  - Software Developers
  - Solution Architects
  - Edge Engineers
  - DevOps Engineers
learning_objectives:
  - Learn AI-powered development workflows and patterns
  - Configure and optimize AI assistance tools effectively
  - Apply AI assistance to complex engineering challenges
  - Build proficiency in prompt engineering for development
# Content Classification
content_type: hands-on
real_world_application: Real-world AI-assisted development scenarios for edge computing projects
complexity_factors:
  - Understanding AI assistance patterns and workflows
  - Configuring development environments for optimal AI support
  - Applying AI assistance to complex engineering problems
# Repository Integration
uses_prompts: []
uses_instructions:
  - .github/copilot-instructions.md
uses_chatmodes: []
repository_paths:
  - .github/copilot-instructions.md
  - copilot/
repository_integration:
  - ".github/copilot-instructions.md"
  - "copilot/"
# Success Criteria & Assessment
success_criteria:
  - Demonstrate effective AI-assisted development workflows
  - Configure AI tools for optimal development productivity
  - Apply AI assistance to solve complex engineering challenges
  - Create high-quality code with AI assistance
common_pitfalls:
  - "Poor prompt engineering": Use specific, detailed prompts for better AI assistance
  - "Over-reliance on AI": Balance AI assistance with critical thinking and code review
  - "Inadequate context": Provide sufficient context for AI tools to generate relevant suggestions
# SEO & Discoverability
keywords:
  - learning
  - ai-assisted engineering
  - katas
  - practice exercises
  - ai workflows
tags:
  - ai-assistance
  - development
  - engineering
  - workflows
# AI Coaching Integration
ai_coaching_enabled: true
validation_checkpoints:
  - "AI workflow demonstration: Verify effective use of AI assistance in development tasks"
  - "Tool configuration validation: Confirm optimal setup of AI development tools"
  - "Code quality assessment: Ensure high-quality output with AI assistance"
extension_challenges:
  - challenge_name: Advanced AI-Assisted Refactoring
    description: Use AI assistance to refactor complex legacy code with modern patterns
    difficulty: advanced
    estimated_time: 60 minutes
  - challenge_name: AI-Guided Architecture Design
    description: Leverage AI assistance for designing scalable edge computing architectures
    difficulty: expert
    estimated_time: 90 minutes
troubleshooting_guide: |
  **Common Issues:**
  - AI suggestions not relevant: Provide more specific context and requirements
  - Poor code quality: Review and refine AI-generated code before implementation
  - Tool configuration issues: Follow setup guides and verify environment configuration
---

## Quick Context

AI-Assisted Engineering katas provide hands-on practice with AI-powered development tools and workflows. These exercises help you learn GitHub Copilot, prompt engineering, and AI-assisted code generation for edge computing projects.

📊 **[Track Your Progress](../../catalog.md)** - Monitor your progress on your learning journey

## 🤖 AI Coaching Available

This kata category includes AI coaching support to help guide you through:

- AI-powered development workflows and patterns
- Tool configuration and optimization techniques
- Best practices for prompt engineering and code generation
- Real-world AI assistance scenarios

## Learning Objectives

By completing these AI-assisted engineering katas, you will:

- **Learn AI Workflows**: Develop proficiency with AI-powered development patterns and tools
- **Optimize Tool Configuration**: Configure AI assistance tools for maximum productivity
- **Apply Advanced Techniques**: Use AI assistance for complex engineering challenges
- **Build Quality Code**: Create high-quality, maintainable code with AI assistance

## AI-Assisted Engineering Katas

Streamlined practice exercises for building proficiency in AI-powered development workflows using tools like [GitHub Copilot][ms-github-copilot] and [VS Code][ms-vscode]. These optimized katas help you develop muscle memory for effective AI assistance patterns with minimal reading overhead, following [Microsoft's AI development best practices][ms-development-best-practices].

### What You'll Practice

- **AI Development Fundamentals**: Core AI assistance principles with action-oriented learning
- **Environment Setup**: Getting started with AI-assisted development tools with embedded guidance
- **Advanced Configuration**: Complex environment and tooling setup using streamlined approach

### Project Integration Resources

These katas leverage real project AI assistance tools:

- **Copilot Instructions**: Practice with [getting started instructions][getting-started-instructions] for context-aware assistance
- **AI Chat Modes**: Learn specialized modes from [GitHub chat configurations][github-chat-modes]
- **Getting Started Prompts**: Use [onboarding guidance][getting-started-guidance] for practical workflows

### Getting Started

**🚀 Quick Start with Training Mode:**

```bash
npm run docs
```

> ⏱️ **Build Time**:
>
> - **First run**: 2-4 minutes (installs dependencies + builds config)   > - **Subsequent runs**: Use `npm run docs` for ~30 seconds startup

This automatically opens the documentation and navigates directly to the Learning Platform, providing immediate access to all AI-assisted engineering katas and learning resources.

**Prerequisites**: Ensure your development environment is set up according to the [general user setup guide][general-user-setup].

<!-- AUTO-GENERATED:START -->
<!-- This section is automatically generated. Manual edits will be overwritten. -->

## Streamlined Kata Progression

| #   | Kata Title                                                                                 | Difficulty   | Duration | Prerequisites        | Technology Focus                                              | Scaffolding  |
|-----|--------------------------------------------------------------------------------------------|--------------|----------|----------------------|---------------------------------------------------------------|--------------|
| 100 | [100 - AI Development Fundamentals](./100-ai-development-fundamentals.md)                  | ⭐ Foundation | 30 min   | —                    | GitHub Copilot, GitHub Copilot Chat, VS Code                  | Heavy        |
| 100 | [100 - Conversation Checkpoint Restore](./100-conversation-checkpoint-restore.md)          | ⭐ Foundation | 25 min   | —                    | GitHub Copilot Chat, VS Code                                  | Heavy        |
| 100 | [100 - Conversation Clearing Strategy](./100-conversation-clearing-strategy.md)            | ⭐ Foundation | 25 min   | → 100                | manage VS Code conversation history limits                    | Heavy        |
| 100 | [100 - GitHub Copilot Modes](./100-copilot-modes.md)                                       | ⭐ Foundation | 30 min   | → 100                | GitHub Copilot, GitHub Copilot Chat, GitHub Copilot Edit Mode | Heavy        |
| 100 | [100 - Getting Started Basics](./100-getting-started-basics.md)                            | ⭐ Foundation | 45 min   | → 100                | GitHub Copilot, Azure, Terraform                              | Heavy        |
| 100 | [100 - Inline Chat Quick Edits](./100-inline-chat-quick-edits.md)                          | ⭐ Foundation | 30 min   | → 100                | GitHub Copilot, Terraform, Bicep                              | Heavy        |
| 100 | [100 - Inline Suggestions Basics](./100-inline-suggestions-basics.md)                      | ⭐ Foundation | 30 min   | —                    | GitHub Copilot, Terraform, Bicep                              | Heavy        |
| 200 | [200 - Copilot Edit Mode Basics](./200-copilot-edit-mode-basics.md)                        | ⭐⭐ Skill     | 60 min   | → 100                | GitHub Copilot, GitHub Copilot Edit Mode, VS Code             | Medium-Heavy |
| 200 | [200 - GitHub Copilot Edit Mode for IaC Patterns](./200-copilot-edit-mode-iac-patterns.md) | ⭐⭐ Skill     | 60 min   | → 200                | GitHub Copilot, GitHub Copilot Edit Mode, Terraform           | Medium-Heavy |
| 200 | [200 - Token-Efficient Context Strategies](./200-token-efficient-context.md)               | ⭐⭐ Skill     | 30 min   | → 100, 100           | GitHub Copilot Chat, VS Code                                  | Medium-Heavy |
| 300 | [300 - Getting Started Advanced](./300-getting-started-advanced.md)                        | ⭐⭐⭐ Advanced | 120 min  | → 100, 100, 200, 200 | GitHub Copilot, GitHub Copilot Edit Mode, Azure               | Medium       |

<!-- AUTO-GENERATED:END -->

### Learning Progression

<!-- AUTO-GENERATED: Learning Progression START -->

### 100 - Foundation Level

- **Focus**: Learn AI-assisted, hyper-velocity engineering through hands-on practice with prompts, instructions, and chat modes and Learn when and how to restore conversation checkpoints for efficient workflow recovery and context management
- **Skills**: GitHub Copilot, GitHub Copilot Chat, VS Code, AI-assisted development, GitHub Copilot Edit Mode
- **Time-to-Practice**: 4 hours

### 200 - Skill Level

- **Focus**: Learn GitHub Copilot Edit Mode fundamentals including activation methods, file selection strategies, and coordinated multi-file editing for consistent codebase changes and Apply GitHub Copilot Edit Mode to Infrastructure as Code workflows including Terraform consistency, Bicep type coordination, and Kubernetes manifest patterns
- **Skills**: GitHub Copilot, GitHub Copilot Edit Mode, VS Code, Terraform, Bicep
- **Time-to-Practice**: 3 hours

### 300 - Advanced Level

- **Focus**: Learn advanced AI-assisted onboarding with complex environment setups, multi-component deployment, and sophisticated project initialization workflows
- **Skills**: GitHub Copilot, GitHub Copilot Edit Mode, Azure, Terraform, Bicep
- **Time-to-Practice**: 2 hours

<!-- AUTO-GENERATED: Learning Progression END -->

## Real-World Application

These streamlined katas prepare you for:

- **Development Acceleration**: AI-assisted coding and debugging workflows
- **Environment Proficiency**: Rapid setup and configuration of development environments
- **Workflow Integration**: Seamless AI assistance in team development practices
- **Quality Enhancement**: AI-powered code review and improvement processes

## Prerequisites

- Basic VS Code familiarity
- Understanding of development workflows (helpful but not required)
- Ready to engage with hands-on AI assistance practice

**Ready to start AI-assisted engineering practice?**

🤖 **[Begin with 100 - AI Development Fundamentals][kata-100-fundamentals]**

*Experience accelerated AI-assisted development through streamlined, action-oriented practice.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
<!-- Internal Project Links -->
[getting-started-instructions]: /.github/instructions/
[github-chat-modes]: /.github/chatmodes/
[getting-started-guidance]: /docs/getting-started/
[kata-100-fundamentals]: /learning/katas/ai-assisted-engineering/100-ai-development-fundamentals

<!-- Microsoft Documentation -->
[ms-github-copilot]: https://docs.github.com/copilot
[ms-vscode]: https://learn.microsoft.com/visualstudio/vscode/
[ms-development-best-practices]: https://learn.microsoft.com/azure/architecture/guide/
[general-user-setup]: /docs/getting-started/
