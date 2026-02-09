---
title: 'Kata: 100 - Basic Product Requirements Document Creation'
description: Learn to create structured product requirements documents using AI assistance and the PRD agent for edge AI solutions
author: Edge AI Team
ms.date: 2025-01-25
kata_id: product-requirements-100-basic-prd-creation
kata_category:
  - product-requirements
kata_difficulty: 1
estimated_time_minutes: 60
learning_objectives:
  - Create structured PRDs using AI-assisted requirements gathering techniques
  - Identify and document stakeholder personas with clear goals and pain points
  - Generate comprehensive user stories with acceptance criteria
  - Define technical requirements, constraints, and system assumptions
  - Establish quantifiable success metrics with measurable targets
prerequisite_katas: []
technologies:
  - GitHub Copilot
success_criteria:
  - PRD includes complete problem statement and stakeholder analysis
  - All user stories include clear acceptance criteria and MoSCoW prioritization
  - Technical requirements cover integration, UI/UX, performance, and security
  - Success metrics are quantifiable with baseline and target values
  - Document structure follows professional PRD standards
  - All agent prompts are effective and yield quality outputs
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls:
  - Stakeholder analysis too shallow—missing goals and pain points
  - User stories lack specific acceptance criteria
  - Technical requirements are vague or unmeasurable
  - Success metrics are qualitative rather than quantitative
  - Not using PRD agent iteratively to refine outputs
requires_azure_subscription: false
requires_local_environment: true
tags:
  - product-requirements
search_keywords:
  - product-requirements-document
  - prd-creation
  - requirements-gathering
  - stakeholder-analysis
  - user-stories
---

**Duration**: 45-60 minutes • **Difficulty**: Beginner • **Category**: Product Requirements

## Quick Context

You're a product manager at a manufacturing company with 50+ edge devices deployed across 3 facilities. The Operations Team is frustrated—they manually check individual device dashboards throughout the day, causing delayed responses to critical alerts.

**Your mission**: Create a structured Product Requirements Document (PRD) for an "Edge Device Alert Dashboard" that centralizes device health monitoring and alert management.

**Real-world challenge**: The Operations Team Lead reports that critical device failures go unnoticed for 15-30 minutes because alerts are scattered. PlatformOps Engineers struggle with alert escalation, and Plant Managers lack visibility into operational metrics. Your PRD will guide the development team in building a solution.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

- [ ] **VS Code** with **GitHub Copilot Chat** extension installed and activated
- [ ] **PRD Agent** available at `.github/copilot-instructions-agent-prd.md`
- [ ] **Learning Coach Agent** available at `.github/agents/learning-kata-coach.agent.md`
- [ ] **45-60 minutes** of uninterrupted time to complete all tasks

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 01 - Basic Product Requirements Document Creation kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

Work through these tasks sequentially to build your complete PRD:

### Task 1: Initialize PRD with Problem Statement

**Time**: 12 minutes

Create the foundation of your PRD by defining the problem and stakeholders.

**Steps**:

1. **Activate PRD Agent**
   - [ ] Open GitHub Copilot Chat in VS Code
   - [ ] Type `@agent` and select the prd-builder agent
   - [ ] Confirm agent is active

2. **Generate Executive Summary and Problem Statement**
   - [ ] Prompt: *"I need to create a PRD for an Edge Device Alert Dashboard. The Operations Team at a manufacturing company with 50+ edge devices across 3 facilities is manually checking individual dashboards, causing 15-30 minute delays in responding to critical alerts. Generate an executive summary and detailed problem statement."*
   - [ ] Review the generated content
   - [ ] Pass a copy the executive summary to your PRD chat
   - [ ] Pass a copy the problem statement to your PRD chat

3. **Generate Stakeholder Analysis**
   - [ ] Prompt: *"Generate a stakeholder analysis for this dashboard. Include these personas: Operations Team Lead (primary user needing centralized alert visibility), PlatformOps Engineers (need alert routing and escalation), and Plant Managers (need operational metrics and downtime reports). For each persona, include their goals, pain points, and success criteria."*
   - [ ] Review the 3 stakeholder personas
   - [ ] Verify each persona has: role description, goals (2-3), pain points (2-3), success criteria (2-3)
   - [ ] Ensure Copilot updates stakeholder analysis in your PRD document

**Success Check**: ✅

- Your PRD has a clear executive summary (2-3 paragraphs)
- Problem statement explains the current situation, impact, and need for solution
- 3 stakeholder personas are documented with goals, pain points, and success criteria

### Task 2: Define User Stories and Requirements

**Time**: 15 minutes

Transform stakeholder needs into actionable user stories and functional requirements.

**Steps**:

1. **Generate User Stories for Operations Team Lead**
   - [ ] Prompt: *"Generate 3-4 user stories for the Operations Team Lead persona. Each user story should follow the format 'As a [role], I want [goal], so that [benefit]' and include 2-3 acceptance criteria. Focus on centralized alert visibility, real-time device health monitoring, and quick alert acknowledgment."*
   - [ ] Review generated user stories
   - [ ] Verify each story has clear acceptance criteria
   - [ ] Copy to your PRD document under "User Stories" section

2. **Generate User Stories for DevOps Engineers**
   - [ ] Prompt: *"Generate 2-3 user stories for DevOps Engineers who need alert routing, escalation rules, and integration with existing incident management systems. Include acceptance criteria for each story."*
   - [ ] Review generated user stories
   - [ ] Verify each story addresses DevOps workflow needs
   - [ ] Copy to your PRD document

3. **Generate Prioritized Functional Requirements**
   - [ ] Prompt: *"Based on all the user stories, generate a prioritized list of functional requirements for the dashboard. Use MoSCoW prioritization (Must Have, Should Have, Could Have, Won't Have this phase). Focus on Phase 1 features: real-time device health display, active alerts list, basic filtering (by facility, device type, alert severity), and alert acknowledgment."*
   - [ ] Review the prioritized requirements list
   - [ ] Verify Must Have features align with critical user needs
   - [ ] Copy the prioritized requirements to your PRD document

**Success Check**: ✅

- 5-7 total user stories covering Operations Team Lead and DevOps Engineers
- Each user story has 2-3 specific acceptance criteria
- Functional requirements are prioritized using MoSCoW method
- Must Have features are clearly identified for Phase 1

### Task 3: Define Technical Requirements and Constraints

**Time**: 10 minutes

Document the technical foundation and constraints for implementation.

**Steps**:

1. **Generate Technical Requirements**
   - [ ] Prompt: *"Generate technical requirements for this edge device alert dashboard. Include: integration with Azure IoT Operations MQ broker for alert ingestion, UI/UX requirements (responsive web interface, 3-second page load time, accessible WCAG 2.1 AA), performance requirements (support 50+ devices, handle 100+ alerts concurrently, <2 second alert display latency), and security requirements (Azure AD authentication, role-based access control, encrypted data transmission)."*
   - [ ] Review the generated technical requirements
   - [ ] Verify requirements cover integration, UI/UX, performance, and security
   - [ ] Copy to your PRD document under "Technical Requirements" section

2. **Document Constraints and Assumptions**
   - [ ] Prompt: *"Generate a list of constraints and assumptions for this project. Constraints: must integrate with existing Azure IoT Operations deployment, no budget for new infrastructure, must use existing authentication (Azure AD). Assumptions: edge devices are already sending telemetry to IoT Operations MQ broker, network connectivity is reliable, Operations Team has web browser access."*
   - [ ] Review the constraints and assumptions
   - [ ] Verify they reflect realistic project boundaries
   - [ ] Copy to your PRD document under "Constraints and Assumptions" section

**Success Check**: ✅

- Technical requirements cover integration, UI/UX, performance, and security
- Each requirement is specific and measurable (e.g., "3-second page load time")
- Constraints identify real limitations (budget, infrastructure, authentication)
- Assumptions document what you're relying on to be true

### Task 4: Define Success Metrics and Acceptance Criteria

**Time**: 8 minutes

Establish how you'll measure the dashboard's success and project completion.

**Steps**:

1. **Generate Success Metrics**
   - [ ] Prompt: *"Generate 5-7 quantifiable success metrics for this dashboard. For each metric, include: metric name, description, baseline (current state), target (desired state after implementation), and measurement method. Focus on: alert response time, dashboard adoption, alert acknowledgment rate, user satisfaction, system uptime, and operational efficiency."*
   - [ ] Review the generated metrics
   - [ ] Verify each metric has baseline and target values with specific numbers
   - [ ] Ensure measurement methods are clear and practical
   - [ ] Copy to your PRD document under "Success Metrics" section

2. **Define Project Acceptance Criteria**
   - [ ] Prompt: *"Generate project acceptance criteria for Phase 1 completion. Include both technical acceptance criteria (all Must Have features implemented, integration tests pass, performance benchmarks met, security audit complete) and business acceptance criteria (Operations Team can view all 50+ devices, alerts display within 2 seconds, 90% user satisfaction in pilot testing)."*
   - [ ] Review acceptance criteria
   - [ ] Verify criteria are measurable and achievable
   - [ ] Copy to your PRD document under "Acceptance Criteria" section

**Success Check**: ✅

- 5-7 success metrics are documented
- Each metric has baseline (current) and target (desired) values
- Measurement methods are practical and clear
- Project acceptance criteria cover both technical and business requirements
- All criteria are quantifiable and measurable

## Completion Check

Your PRD is complete when:

- [ ] **Problem Statement**: Clear explanation of the current situation and impact
- [ ] **Stakeholder Analysis**: 3 personas with goals, pain points, and success criteria
- [ ] **User Stories**: 5-7 stories with acceptance criteria covering key personas
- [ ] **Functional Requirements**: Prioritized using MoSCoW method with Must Have features identified
- [ ] **Technical Requirements**: Integration, UI/UX, performance, and security specifications
- [ ] **Constraints and Assumptions**: Documented project boundaries and dependencies
- [ ] **Success Metrics**: 5-7 quantifiable metrics with baseline and target values
- [ ] **Acceptance Criteria**: Technical and business criteria for project completion

**Final validation**: Share your PRD with the Learning Coach agent and ask: *"Review my PRD for completeness and clarity. Does it provide enough detail for a development team to begin implementation?"*

---

## Reference Appendix

### Help Resources

- **PRD Agent**: Use prd.agent.md for systematic PRD creation with structured prompts
- **Learning Coach**: Reference learning-coach.agent.md for interactive coaching and progress tracking
- **Product Planning**: Study project-planning katas for comprehensive planning methodologies
- **Requirements Documentation**: Reference CONTRIBUTING.md for documentation standards and best practices

### Professional Tips

**Tip 1: Iterate with the PRD agent**: Don't accept the first output. Ask follow-up questions like *"Make the acceptance criteria more specific"* or *"Add more detail to the performance requirements."*

**Tip 2: Keep stakeholders front and center**: Every requirement should trace back to a stakeholder need. If you can't explain which persona benefits, reconsider the requirement.

**Tip 3: Make everything measurable**: Avoid words like "fast," "easy," "reliable" without numbers. Use "3-second load time," "90% user satisfaction," "99.9% uptime."

**Tip 4: Start with Must Have features only**: Phase 1 should be the absolute minimum viable product. Save Should Have and Could Have features for Phase 2. This keeps scope manageable.

**Tip 5: Review with diverse perspectives**: Before finalizing, ask yourself: "Would a developer know what to build? Would a designer know what to create? Would a tester know what to validate?" If not, add more detail.

### Troubleshooting

**PRD agent generates generic content**:

- Provide more specific context about edge device types (e.g., "temperature sensors, vibration monitors, PLCs"), facility layout (e.g., "3 buildings across 50-acre campus"), and operational workflows (e.g., "2-shift operation, 16 hours/day")

**User stories are too technical**:

- Focus on user goals and outcomes, not implementation details
- Use the strict format: "As a [role], I want [goal], so that [benefit]"
- Example: "As an Operations Team Lead, I want to see all active alerts in one view, so that I can prioritize critical issues quickly" (not "I want a REST API that returns JSON alert data")

**Success metrics are vague**:

- Always include a baseline (current state) and target (desired state) with specific numbers
- Example: "Alert Response Time: Baseline 15-30 minutes, Target <5 minutes" (not "Improve alert response time")

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
