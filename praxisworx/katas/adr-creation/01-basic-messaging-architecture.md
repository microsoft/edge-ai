---
title: 01 - Basic Messaging Architecture
description: Learn ADR creation fundamentals through edge computing messaging decisions, comparing MQTT vs Apache Kafka for industrial IoT data streaming scenarios
author: Edge AI Team
ms.date: 2025-06-17
ms.topic: kata
estimated_reading_time: 8
difficulty: beginner
duration: 30-45 minutes
keywords:
  - praxisworx
  - adr creation
  - architectural decision records
  - edge computing
  - mqtt
  - apache kafka
  - messaging architecture
  - industrial iot
  - numbered progression
---

## Quick Context

**You'll Learn**: Create professional Architectural Decision Records (ADRs) using structured evaluation methodology for real-world technology choices.

**Real Challenge**: Your industrial IoT system needs to choose between MQTT and Apache Kafka for streaming sensor data from 500+ edge devices. The wrong choice could cost months of rework and impact system performance. You need to document this critical architecture decision professionally.

**Your Task**: Create a complete ADR following project standards that evaluates MQTT vs Apache Kafka for edge computing messaging, including research, trade-off analysis, and final recommendation with clear justification.

## 🤖 AI Coaching Available - Get Interactive Help

> **🚀 Supercharge Your Learning with AI Coaching**
>
> **New to AI-assisted learning? Want task check-offs, progress tracking, and personalized guidance?**
>
> Load our specialized **PraxisWorx Kata Coach** for:
>
> - ✅ **Task Check-offs**: Mark completed tasks and track your progress
> - 🎯 **Learning Evaluation**: Reflect on your progress with guided questions
> - 🆘 **Coaching & Troubleshooting**: Get progressive hints when you're stuck
> - 🔄 **Session Resumption**: Pick up exactly where you left off
> - 🧭 **Smart Guidance**: Personalized coaching based on your progress patterns

### How to Load Your AI Coach

**Step 1**: In GitHub Copilot Chat, select the **PraxisWorx Kata Coach** mode from the chat mode selector.

**Step 2**: Send this starter message to begin your coached session:

```text
I'm working on Basic Messaging Architecture kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

### Essential Setup

**Required** (check these first):

- [ ] VS Code with GitHub Copilot Chat enabled
- [ ] Access to solution ADR library and templates in `docs/solution-adr-library/` folder
- [ ] Basic understanding of IoT concepts and messaging patterns

**Quick Validation**:

- Can you navigate to `docs/solution-adr-library/` folder and see adr-template-solutions.md?
- Can you open `docs/solution-adr-library/` and see real ADR examples like mqtt-qos.md and asset-connectivity-monitoring.md?
- Can you navigate to `.github/chatmodes/` and find adr-creation.chatmode.md?
- Can you open GitHub Copilot Chat and see the chat interface?

**Understanding Check**: This kata teaches you to create professional Architectural Decision Records (ADRs) using structured evaluation methodology while leveraging AI assistance for research and documentation.

## Understanding ADR Infrastructure and AI Assistance

Before diving into the tasks, you need to understand the ADR creation infrastructure and AI assistance approaches available in this project:

### ADR Infrastructure Discovery

**Solution ADR Library** (`docs/solution-adr-library/` folder):

- **Purpose**: Provides real-world ADR examples and comprehensive templates for consistent architectural decision documentation
- **Key files to explore**:
  - `docs/solution-adr-library/adr-template-solutions.md` - Comprehensive ADR template with YAML drafting guide
  - `docs/solution-adr-library/README.md` - ADR library overview and contribution guidelines
  - `docs/solution-adr-library/mqtt-qos.md` - Real-world messaging architecture ADR example
  - `docs/solution-adr-library/asset-connectivity-monitoring.md` - IoT connectivity decision example
- **Try this**: *"Open `docs/solution-adr-library/adr-template-solutions.md` and examine the comprehensive ADR structure with YAML drafting guide and full documentation sections"*

**AI-Assisted ADR Creation** (`.github/chatmodes/adr-creation.chatmode.md`):

- **Purpose**: Interactive AI coaching for collaborative architectural decision record creation
- **When to use**: When you need guided discovery and progressive documentation for architectural decisions
- **Example exploration**: Open `.github/chatmodes/adr-creation.chatmode.md` and notice the coaching approach for ADR creation
- **Try this**: *In GitHub Copilot Chat, select the "ADR Creation Coach" mode and say "Help me create an ADR for messaging architecture decision"*

### The ADR Creation Workflow

**Understanding the Flow**: Research → Analysis → Documentation → Validation

1. **Research Phase**: Use prompts and AI assistance for technology investigation and comparison
2. **Analysis Phase**: Use structured evaluation criteria to compare options systematically
3. **Documentation Phase**: Use templates and AI assistance for professional ADR creation
4. **Validation Phase**: Use prompts for review, quality checking, and project standard compliance

## Practice Tasks

### Task 1: Research and Understand the Decision Context (10 minutes)

**What You'll Do**: Gather requirements and understand the architectural decision that needs to be made using project infrastructure.

**Steps**:

1. **Review** the business scenario and technical requirements
   - [ ] Industrial IoT system with 500+ edge devices sending sensor data
   - [ ] Requirements: real-time processing, device communication, Azure cloud integration
   - **Expected result**: Clear understanding of what needs to be decided

2. **Examine** existing ADR examples and templates in the solution library
   - [ ] Open `docs/solution-adr-library/adr-template-solutions.md` and study the comprehensive ADR structure with YAML drafting guide
   - [ ] Navigate to `docs/solution-adr-library/` and review 2-3 real-world ADR examples (mqtt-qos.md, asset-connectivity-monitoring.md, edge-data-transform-separation-ml-inferencing.md)
   - [ ] Read `docs/solution-adr-library/README.md` to understand the solution library purpose and quality standards
   - **Expected result**: Familiarity with professional ADR format, real-world examples, and solution library standards

3. **Identify** the key evaluation criteria using structured approach
   - [ ] Use GitHub Copilot to research evaluation criteria for messaging architecture decisions
   - [ ] Focus on: Performance requirements, complexity, Azure integration, cost considerations, scalability
   - **Validation checkpoint**: Can you list 5-6 specific criteria for MQTT vs Kafka evaluation?
   - **Success check**: Clear understanding of what factors will drive your architectural decision

### Task 2: Research and Compare Technologies (15 minutes)

**What You'll Do**: Research MQTT and Apache Kafka characteristics using AI assistance and structured evaluation methodology.

**Steps**:

1. **Explore** structured ADR creation assistance
   - [ ] Open `.github/chatmodes/adr-creation.chatmode.md` and examine the coaching approach for research process
   - [ ] Practice using ADR Creation Coach mode: Start a chat session and say *"Help me research MQTT characteristics for IoT scenarios"*
   - **Expected result**: Understanding of how to leverage AI coaching for systematic technology research

2. **Research** MQTT characteristics and capabilities
   - [ ] Use GitHub Copilot to understand MQTT strengths for IoT scenarios with specific focus on your evaluation criteria
   - [ ] Focus on: protocol efficiency, device support, Azure IoT Hub integration, latency, complexity
   - **Validation checkpoint**: Can you explain MQTT's advantages for edge device communication?
   - **Expected result**: Clear understanding of MQTT advantages and limitations for your use case

3. **Research** Apache Kafka characteristics and capabilities
   - [ ] Use Copilot to understand Kafka strengths for streaming data with focus on your evaluation criteria
   - [ ] Focus on: throughput, durability, Azure Event Hubs compatibility, operational complexity, cost
   - **Validation checkpoint**: Can you explain Kafka's advantages for high-volume data streaming?
   - **Expected result**: Clear understanding of Kafka advantages and limitations for your use case

4. **Create** a structured comparison matrix
   - [ ] Document how each technology performs against your evaluation criteria
   - [ ] Include specific technical details, trade-offs, and Azure integration considerations
   - **Success check**: Structured comparison ready for decision-making with clear winners and losers per criteria
   - **Expected result**: Evidence-based foundation for architectural decision documentation

### Task 3: Create Professional ADR Documentation (15 minutes)

**What You'll Do**: Write a complete ADR using project templates and AI assistance for professional documentation quality.

**Steps**:

1. **Create** your ADR file using solution library template
   - [ ] Copy `docs/solution-adr-library/adr-template-solutions.md` content as your starting point
   - [ ] Use the YAML drafting guide first to organize your thoughts before writing the full ADR
   - [ ] Name your ADR file appropriately (e.g., "messaging-architecture-mqtt-vs-kafka.md")
   - [ ] Use Copilot to fill in Context section with scenario details, requirements, and evaluation criteria
   - **Validation checkpoint**: Does your Context section clearly explain the business problem and technical requirements?
   - **Expected result**: ADR structure ready for your analysis with professional context documentation

2. **Document** your technology evaluation and decision using AI assistance
   - [ ] Use structured approach: Present MQTT vs Kafka comparison with specific trade-offs per criteria
   - [ ] Leverage Copilot for articulating technical analysis professionally
   - [ ] Make clear recommendation with strong technical justification based on your research
   - [ ] Include consideration of Azure services integration and edge computing requirements
   - **Validation checkpoint**: Is your decision clearly justified with evidence from your research?
   - **Expected result**: Complete decision documentation with professional rationale and clear recommendation

3. **Review** and validate your ADR quality against solution library standards
   - [ ] Check ADR structure against `docs/solution-adr-library/adr-template-solutions.md` requirements
   - [ ] Ensure professional tone and clear technical reasoning throughout
   - [ ] Verify all standard ADR sections are complete and coherent (Context, Decision, Consequences, etc.)
   - [ ] Compare quality against real-world examples in `docs/solution-adr-library/` for professional standard
   - **Success validation**: ADR meets solution library standards and clearly justifies technology choice with implementation guidance
   - **Expected result**: Professional-quality ADR ready for team review and potential inclusion in solution library

## Validation

**You've Succeeded When**:

- [ ] Navigated project ADR infrastructure confidently and understood template structure
- [ ] Successfully used AI assistance for technology research with structured evaluation criteria
- [ ] Created a complete ADR following project template with professional documentation quality
- [ ] Documented clear evaluation of MQTT vs Apache Kafka with specific technical criteria and trade-offs
- [ ] Made a justified recommendation with strong technical rationale based on research evidence
- [ ] ADR meets project standards and is ready for team review and potential acceptance

### ADR Creation Proficiency Validation

**Validation Exercise**: Confirm your understanding through hands-on verification:

**1. Infrastructure Discovery Validation**:

- [ ] Can navigate to `docs/solution-adr-library/adr-template-solutions.md` and explain the YAML drafting guide and full ADR structure
- [ ] Can navigate to `docs/solution-adr-library/` and identify relevant real-world ADR examples for messaging architecture decisions
- [ ] Can navigate to `.github/chatmodes/adr-creation.chatmode.md` and understand the interactive coaching approach for ADR creation
- **Validation question**: *"What are the key sections of the solution library ADR template and how does the ADR Creation Coach help guide architectural thinking?"*

**2. AI-Assisted Research Validation**:

- [ ] Can demonstrate using the ADR Creation Coach for systematic technology research with guided discovery
- [ ] Can explain how to use the interactive coaching approach for structured architectural analysis
- [ ] Can create evidence-based technology comparisons with clear winners and losers per criteria
- **Validation exercise**: Ask GitHub Copilot to help you research one additional messaging technology and compare it using your established criteria

**3. Professional ADR Creation Validation**:

- [ ] Can create ADRs using solution library templates with professional documentation quality
- [ ] Can document architectural decisions with clear technical justification and implementation guidance
- [ ] Can validate ADR quality against solution library standards and real-world examples
- **Success indicator**: Confidence in creating professional ADRs that meet solution library standards and effectively communicate architectural decisions to technical teams

## Next Steps

**Continue Learning**: Practice with `02-advanced-observability-stack.md` for more complex multi-technology ADR scenarios

**Apply Skills**: Use this systematic ADR creation methodology for documenting real architectural decisions in your projects

## Resources

- [PraxisWorx Kata Coach][kata-coach] - Step-by-step help and troubleshooting guidance
- [ADR Creation Prompt][adr-create] - Structured ADR creation guidance for systematic decision documentation
- [Project ADR Examples][project-adr-library] - Real-world ADR examples and quality standards
- [Azure IoT Hub][ms-azure-iot-hub] - IoT messaging patterns and integration details
- [Azure Event Hubs][ms-azure-event-hubs] - Event streaming architecture guidance

---

<!-- Reference Links -->
[kata-coach]: /.github/chatmodes/praxisworx-kata-coach.chatmode.md
[adr-create]: /.github/chatmodes/adr-creation.chatmode.md
[project-adr-library]: /docs/solution-adr-library/README
[ms-azure-iot-hub]: https://docs.microsoft.com/azure/iot-hub/
[ms-azure-event-hubs]: https://docs.microsoft.com/azure/event-hubs/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
