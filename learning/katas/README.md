---
title: Learning Katas - Focused Practice Exercises
description: Short, focused practice exercises for building AI-assisted engineering skills through deliberate practice
author: Edge AI Team
ms.date: 2025-06-15
ms.topic: hub-page
estimated_reading_time: 10
difficulty: all levels
keywords:
   - learning
   - katas
   - practice exercises
   - ai-assisted engineering
   - skill building
---

## Overview

Learning Katas are short, focused practice exercises (15-45 minutes) designed for deliberate skill building through repetition and refinement. Inspired by martial arts training, these katas help engineers develop muscle memory for AI-assisted development patterns.

### What You'll Find Here

- **Focused Practice**: Single-skill exercises with clear objectives
- **Progressive Difficulty**: Build from beginner to expert level
- **Repetitive Learning**: Practice the same concepts to build proficiency
- **Quick Wins**: Complete exercises in 15-45 minutes

### Learning Philosophy

Katas emphasize:

- **Deliberate Practice**: Focused repetition of specific skills
- **Muscle Memory**: Build automatic responses to common scenarios
- **Incremental Improvement**: Small, consistent progress over time
- **Practical Application**: Real-world scenarios and challenges

## 🤖 AI Coaching Available - Get Interactive Help

> **🚀 Supercharge Your Learning with AI Coaching**
>
> **New to AI-assisted learning? Want task check-offs, progress tracking, and personalized guidance?**
>
> Load our specialized **Learning Kata Coach** for:
>
> - 📊 **Skill Assessment**: Get personalized kata recommendations based on your experience
> - ✅ **Task Check-offs**: Mark completed tasks and track your progress
> - 🎯 **Learning Evaluation**: Reflect on your progress with guided questions
> - 🆘 **Coaching & Troubleshooting**: Get progressive hints when you're stuck
> - 🔄 **Session Resumption**: Pick up exactly where you left off
> - 🧭 **Smart Guidance**: Personalized coaching based on your progress patterns

### How to Load Your AI Coach

**Step 1**: In GitHub Copilot Chat, select the **Learning Kata Coach** custom agent from the agent selector.

**Step 2**: Send this starter message to begin your coached session:

```text
I'm working on learning katas and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can help track your progress when you're using the local docs (`npm run docs`)! Navigate to the Learning section to access all learning resources.

## Quick Start

### First-Time Practitioners

1. **[Environment Setup][environment-setup]** - Ensure environment is ready
2. **Launch Training Mode** - Use the optimized command for immediate kata access:

   ```bash
   npm run docs
   ```

   > ⏱️ **Build Time**:
   >
   > - **First run**: 2-4 minutes (installs dependencies + builds config)
   > - **Subsequent runs**: Use `npm run docs` for ~30 seconds startup

   This automatically opens the documentation and navigates directly to Learning, giving you immediate access to all kata categories and learning paths.

   **Alternative:** Standard documentation mode:

   ```bash
   npm run docs
   ```

3. **Choose Category** - Navigate to Learning -> Katas and choose a kata based on your learning goals
4. **Start with Beginner** - Build foundation skills first
5. **Practice Regularly** - Consistent practice builds proficiency

> **💡 Tip**: The web interface provides the best kata experience with interactive progress tracking, floating progress bars, and enhanced navigation. All kata checkboxes turn green when completed!

**Recommended First Katas**:

1. `ai-assisted-engineering/01-ai-development-fundamentals.md` - Learn basic AI assistance
2. `adr-creation/01-basic-messaging-architecture.md` - Practice decision making
3. `task-planning/01-edge-documentation-planning.md` - Learn systematic planning

### Experienced Practitioners

1. **Quick Start Documentation** - For immediate access:

   ```bash
   npm run docs
   ```

2. **[Assessment](#skill-assessment)** - Identify skill gaps
3. **Target Practice** - Focus on specific areas for improvement
4. **Advanced Challenges** - Push boundaries with expert-level katas

> **⚡ Quick Commands**:
>
> - `npm run docs` - Full setup with browser auto-open
> - `npm run docs:no-open` - Server only (manual navigation to `http://localhost:8080`)
> - `npm run docs:verbose` - Debug mode with detailed logging

### Web Experience Features

When using `npm run docs`, you get access to enhanced features:

- ✅ **Interactive Progress Tracking** - Checkboxes turn green when completed
- 📊 **Floating Progress Bar** - Real-time completion percentage at the bottom
- 🧭 **Enhanced Navigation** - Smooth scrolling and table of contents
- �️ **Desktop-Optimized Design** - Professional interface designed for desktop productivity
- 🔍 **Search Functionality** - Quickly find specific katas and content
- 🎨 **Modern UI** - Clean, professional interface optimized for learning

> **Note**: While katas can be read directly in VS Code or GitHub, the web interface provides the optimal learning experience with all interactive features enabled.

## Understanding Our Organization

### Numbering System

Each kata category uses a consistent numbering system:

- **01-02**: Beginner level (15-30 minutes)
- **03-04**: Intermediate level (30-45 minutes)
- **05+**: Advanced level (45-60 minutes)

Numbers indicate progression within each category - start with 01 and work your way up!

### Category Overview

| Category                     | Focus                                  | Best For                              |
|------------------------------|----------------------------------------|---------------------------------------|
| **ai-assisted-engineering/** | General AI-assisted development skills | All Developers                        |
| **project-planning/**        | Edge AI project planning and scenarios | Project Managers, Solution Architects |
| **task-planning/**           | Real-world project planning scenarios  | Project Managers, Team Leads          |
| **adr-creation/**            | OSS edge computing ADR methodology     | Architects, Technical Leads           |
| **prompt-engineering/**      | Advanced prompt optimization           | AI/ML Engineers                       |
| **edge-deployment/**         | Edge-specific deployment patterns      | Platform Engineers, DevOps Engineers  |
| **troubleshooting/**         | Diagnostic and debugging skills        | Operations, Support Engineers         |

## Kata Categories

### AI-Assisted Engineering Katas

Develop AI-powered development workflows and foundations.

| Kata                                                     | Difficulty | Duration  | Focus                            |
|----------------------------------------------------------|------------|-----------|----------------------------------|
| [01 - AI Development Fundamentals][kata-ai-fundamentals] | Beginner   | 25-35 min | AI-assisted development basics   |
| [02 - Getting Started Basics][kata-ai-basics]            | Beginner   | 30-40 min | Environment setup and onboarding |

[**Explore AI-Assisted Engineering Katas →**][ai-engineering-overview]

### Project Planning Katas

Learn Edge AI project planning with interactive scenario development and capability orchestration.

| Kata                                                                 | Difficulty   | Duration  | Focus                                |
|----------------------------------------------------------------------|--------------|-----------|--------------------------------------|
| [01 - Basic Prompt Usage][kata-project-planning-01]                  | Beginner     | 25-35 min | Interactive project planner basics   |
| [02 - Comprehensive Two-Scenario Planning][kata-project-planning-02] | Intermediate | 45-60 min | Multi-scenario analysis and planning |
| [03 - Advanced Strategic Planning][kata-project-planning-03]         | Advanced     | 60-75 min | Enterprise-scale deployment strategy |

[**Explore Project Planning Katas →**][project-planning-overview]

### Task Planning Katas

Practice systematic project planning with real edge computing scenarios.

| Kata                                                          | Difficulty   | Duration  | Focus                         |
|---------------------------------------------------------------|--------------|-----------|-------------------------------|
| [01 - Edge Documentation Planning][kata-task-planning-01]     | Beginner     | 25-35 min | Documentation update planning |
| [02 - Repository Analysis Planning][kata-task-planning-02]    | Intermediate | 35-40 min | Repository analysis scripting |
| [03 - Advanced Capability Integration][kata-task-planning-03] | Advanced     | 50-55 min | Complex system integration    |

[**Explore Task Planning Katas →**][task-planning-overview]

### ADR Creation Katas

Practice OSS edge computing architecture decision records.

| Kata                                             | Difficulty   | Duration  | Focus                         |
|--------------------------------------------------|--------------|-----------|-------------------------------|
| [01 - Basic Messaging Architecture][kata-adr-01] | Beginner     | 30-45 min | MQTT vs Apache Kafka for edge |
| [02 - Advanced Observability Stack][kata-adr-02] | Intermediate | 45-60 min | TIG vs TICK stack decisions   |
| [03 - Service Mesh Selection][kata-adr-03]       | Advanced     | 45-50 min | Istio vs Linkerd for edge     |

[**Explore ADR Creation Katas →**][adr-creation-overview]

### Prompt Engineering Katas

Develop prompt creation, optimization, and systematic engineering workflows.

| Kata                                                            | Difficulty | Duration | Focus                                 |
|-----------------------------------------------------------------|------------|----------|---------------------------------------|
| [01 - Prompt Creation and Refactoring Workflow][kata-prompt-01] | Beginner   | 30 min   | Complete prompt engineering lifecycle |

[**Explore Prompt Engineering Katas →**][prompt-engineering-overview]

### Edge Deployment Katas

Develop AI-assisted deployment workflows for edge computing platforms.

| Kata                                   | Difficulty | Duration  | Focus                        |
|----------------------------------------|------------|-----------|------------------------------|
| [01 - Deployment Basics][kata-edge-01] | Beginner   | 35-50 min | Basic deployment workflows   |
| [05 - Deployment Expert][kata-edge-05] | Expert     | 240 min   | Complex deployment scenarios |

[**Explore Edge Deployment Katas →**][edge-deployment-overview]

### Troubleshooting Katas *(Coming Soon)*

Develop systematic diagnostic and debugging skills through focused practice.

*Troubleshooting katas are currently in development. These will focus on AI-assisted diagnostic and debugging workflows for edge computing environments.*

**Planned Content**:

- **Log Analysis**: AI-assisted log pattern recognition
- **Performance Debugging**: Systematic performance optimization
- **Network Diagnostics**: Edge network troubleshooting
- **System Integration Issues**: Complex system debugging

*Check back soon or [contribute][learning-contributing] to help develop these essential troubleshooting skills.*

## Role-Based Learning Paths

### Software Engineers

- **Foundation**: ai-assisted-engineering/01-03 + prompt-engineering/01
- **Specialization**: edge-deployment/01-05 + task-planning/01-02
- **Advanced**: adr-creation/01-03 + project-planning/01-02 for architecture decisions

### Architects & Technical Leads

- **Foundation**: ai-assisted-engineering/01-02 + adr-creation/01-03
- **Specialization**: project-planning/01-03 + task-planning/01-03 + edge-deployment/01-05
- **Advanced**: All categories for comprehensive leadership

### Platform & DevOps Engineers

- **Foundation**: ai-assisted-engineering/01-02 + edge-deployment/01-05
- **Specialization**: task-planning/01-03 + project-planning/01-02 + adr-creation/02-03
- **Advanced**: Cross-category integration for complex automation

### Project Managers & Team Leads

- **Foundation**: project-planning/01-03 + task-planning/01-03 + adr-creation/01-02
- **Specialization**: ai-assisted-engineering/01-02 for technical understanding
- **Advanced**: Cross-category integration for leadership scenarios

### AI/ML Engineers

- **Foundation**: prompt-engineering/01 + ai-assisted-engineering/01-02
- **Specialization**: project-planning/01-03 + adr-creation/01-03 for ML architecture decisions + edge-deployment/01-03
- **Advanced**: Cross-category integration for AI-powered edge solutions

## Skill Assessment

### Find Your Starting Point

**Not sure which kata to start with?** Take our comprehensive skill assessment to get personalized kata recommendations based on your current experience level.

**🎯 [Complete Skill Assessment][skill-assessment]** - Get personalized kata recommendations

This detailed assessment evaluates your skills across four key areas and provides specific kata suggestions tailored to your experience level and professional role.

**Quick Start Options:**

- **Interactive Assessment**: Use the Learning Kata Coach in GitHub Copilot Chat for guided assessment
- **Self-Assessment**: Complete the comprehensive 26-question evaluation independently
- **Browse by Category**: Explore kata categories below if you prefer to start exploring immediately

## Practice Guidelines

### How to Practice Katas

#### Round 1: Initial Attempt

- Read the kata description carefully
- Complete the exercise using your current knowledge
- Note areas of difficulty or uncertainty
- Time yourself and track completion

#### Round 2: Refinement

- Review your initial approach
- Apply feedback and improve techniques
- Focus on areas identified in Round 1
- Compare time and quality improvements

#### Round 3: Proficiency

- Optimize your approach for efficiency
- Focus on best practices and patterns
- Aim for consistent, repeatable results
- Document learnings and insights

## Integration with Training Labs

### Lab Preparation

Use katas to prepare for training labs:

- **[AI-Assisted Engineering Labs][training-labs-ai]**: Practice with AI-Assisted and Prompt Engineering katas *(Coming Soon)*
- **[Edge-to-Cloud Systems Labs][training-labs-edge]**: Prepare with Edge Deployment and Task Planning katas *(Coming Soon)*

### Skill Reinforcement

Use katas to reinforce lab learnings:

- **Post-Lab Practice**: Apply lab concepts through focused practice
- **Skill Maintenance**: Regular practice to maintain proficiency
- **Advanced Application**: Challenge yourself with advanced variations

*Consistent practice builds proficiency. Start your kata journey today and develop the muscle memory for AI-assisted engineering excellence.*

<!-- Reference Links -->

<!-- Environment and Getting Started -->
[environment-setup]: /docs/getting-started/index
[skill-assessment]: /learning/skill-assessment

<!-- AI-Assisted Engineering Katas -->
[ai-engineering-overview]: /learning/katas/ai-assisted-engineering/README
[kata-ai-fundamentals]: /learning/katas/ai-assisted-engineering/01-ai-development-fundamentals
[kata-ai-basics]: /learning/katas/ai-assisted-engineering/02-getting-started-basics

<!-- Project Planning Katas -->
[project-planning-overview]: /learning/katas/project-planning/README
[kata-project-planning-01]: /learning/katas/project-planning/01-basic-prompt-usage
[kata-project-planning-02]: /learning/katas/project-planning/02-comprehensive-two-scenario
[kata-project-planning-03]: /learning/katas/project-planning/03-advanced-strategic-planning

<!-- Task Planning Katas -->
[task-planning-overview]: /learning/katas/task-planning/README
[kata-task-planning-01]: /learning/katas/task-planning/01-edge-documentation-planning
[kata-task-planning-02]: /learning/katas/task-planning/02-repository-analysis-planning
[kata-task-planning-03]: /learning/katas/task-planning/03-advanced-capability-integration

<!-- ADR Creation Katas -->
[adr-creation-overview]: /learning/katas/adr-creation/README
[kata-adr-01]: /learning/katas/adr-creation/01-basic-messaging-architecture
[kata-adr-02]: /learning/katas/adr-creation/02-advanced-observability-stack
[kata-adr-03]: /learning/katas/adr-creation/03-service-mesh-selection

<!-- Prompt Engineering Katas -->
[prompt-engineering-overview]: /learning/katas/prompt-engineering/README
[kata-prompt-01]: /learning/katas/prompt-engineering/01-prompt-creation-and-refactoring-workflow

<!-- Edge Deployment Katas -->
[edge-deployment-overview]: /learning/katas/edge-deployment/README
[kata-edge-01]: /learning/katas/edge-deployment/01-deployment-basics
[kata-edge-05]: /learning/katas/edge-deployment/05-deployment-expert

<!-- Training Labs -->
[training-labs-ai]: /learning/training-labs/01-ai-assisted-engineering/README
[training-labs-edge]: /learning/training-labs/02-edge-to-cloud-systems/README

<!-- Learning Platform Navigation -->
[learning-contributing]: /learning/contributing

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
