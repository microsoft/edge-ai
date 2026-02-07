---
title: 'Kata: 300 - Comprehensive Two-Scenario Planning'
description: Learn multi-scenario project planning by analyzing multiple Edge AI scenarios and creating integrated implementation plans...
author: Edge AI Team
ms.date: 2025-06-17
kata_id: project-planning-300-comprehensive-two-scenario
kata_category:
  - project-planning
kata_difficulty: 3
estimated_time_minutes: 90
learning_objectives:
  - Learn multi-scenario project planning techniques
  - Understand comprehensive project analysis and comparison
  - Practice advanced AI-assisted decision-making processes
  - Develop skills in scenario-based project evaluation
prerequisite_katas:
  - project-planning-100-basic-prompt-usage
technologies:
  - GitHub Copilot
success_criteria:
  - ai-assisted-planning
  - scenario-analysis
  - Create comprehensive project roadmaps and timelines
  - Learn scenario-based decision making for enterprise deployments
ai_coaching_level: guided
scaffolding_level: medium
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - project-planning
search_keywords:
- multi-scenario-planning
- comparative-analysis
- scenario-evaluation
- integrated-roadmaps
- capability-cohesion

---

## Quick Context

**You'll Learn**: How to analyze and compare multiple Edge AI scenarios, create integrated implementation plans, and understand capability cohesion using the edge-ai-project-planner

**Prerequisites**: Completion of Basic Project Planning Prompt Usage kata, experience with GitHub Copilot Chat project planner mode

**Real Challenge**: Your manufacturing operation has two critical improvement opportunities: implementing quality process optimization automation and packaging line performance optimization. You need to determine the best implementation strategy, identify shared capabilities, and create a unified project roadmap.

**Your Task**: Use the edge-ai-project-planner to analyze both scenarios, compare their requirements, and develop an integrated implementation strategy that maximizes shared platform benefits.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

**Required** (check these first):

- [ ] VS Code with GitHub Copilot Chat installed and working
- [ ] Completed [01 - Basic Prompt Usage][kata-01] kata successfully
- [ ] Access to quality process and packaging line documentation
- [ ] Understanding of manufacturing optimization concepts

**Quick Validation**: Open GitHub Copilot Chat and verify you can type `@edge-ai-project-planner` to access the project planner.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 02 - Comprehensive Two Scenario kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Quality Process Optimization Analysis (15 minutes)

**What You'll Do**: Analyze the quality process optimization automation scenario and understand its capability requirements

**Steps**:

1. **Launch** the edge-ai-project-planner agent
   - [ ] Open GitHub Copilot Chat and type `@edge-ai-project-planner` to activate the project planner mode
   - [ ] **Expected result**: Project planner mode is active and ready

2. **Provide** the quality optimization scenario:

   ```text
   I need to implement quality process optimization automation for our manufacturing facility. We want to use computer vision and AI to automate defect detection, reduce quality-related downtime by 60-80%, and achieve 40-60% improvement in first-pass yield. Our focus is on real-time quality monitoring, predictive quality analytics, and automated process adjustment.
   ```

   - [ ] Send this detailed scenario description
   - [ ] **Expected result**: Planner asks clarifying questions about implementation scope

3. **Select** the Quality Process Optimization Automation scenario
   - [ ] When presented with scenario options, choose "Quality Process Optimization Automation"
   - [ ] Answer follow-up questions about manufacturing type and quality requirements
   - [ ] **Success check**: Planner generates comprehensive quality optimization documentation

4. **Review** the generated capability requirements
   - [ ] Examine the capability mapping and implementation phases
   - [ ] Note the critical capabilities: Edge Camera Control, Edge Inferencing, Cloud AI/ML Training
   - [ ] **Expected result**: Clear understanding of quality scenario requirements and timelines

### Task 2: Packaging Line Performance Analysis (15 minutes)

**What You'll Do**: Analyze the packaging line performance optimization scenario in a separate planning session

**Steps**:

1. **Start** a new planning session
   - [ ] Clear the chat or start a new conversation with the project planner
   - [ ] **Expected result**: Fresh planning session ready for new scenario

2. **Provide** the packaging optimization scenario:

   ```text
   I want to implement packaging line performance optimization to maximize throughput, reduce changeover times by 30-50%, and improve overall equipment effectiveness by 15-30%. The focus is on real-time line monitoring, predictive performance management, and automated optimization of packaging line operations.
   ```

   - [ ] Send this scenario description to the planner
   - [ ] **Expected result**: Planner responds with packaging-specific questions

3. **Select** the Packaging Line Performance Optimization scenario
   - [ ] Choose the packaging scenario when options are presented
   - [ ] Provide details about line complexity and optimization goals
   - [ ] **Success check**: Planner generates packaging line optimization documentation

4. **Compare** capability requirements with quality scenario
   - [ ] Review the packaging scenario capability mapping
   - [ ] Note overlapping capabilities: Edge Data Stream Processing, Device Twin Management
   - [ ] **Expected result**: Understanding of both scenarios' technical requirements for comprehensive planning

### Task 3: Integrated Multi-Scenario Planning (20 minutes)

**What You'll Do**: Create an integrated implementation plan that combines both scenarios for maximum platform benefits

**Steps**:

1. **Initiate** integrated planning session
   - [ ] Start a new conversation with the project planner
   - [ ] Request multi-scenario analysis support
   - [ ] **Expected result**: Planner ready for comparative analysis

2. **Request** multi-scenario comparison:

   ```text
   I want to implement both Quality Process Optimization Automation and Packaging Line Performance Optimization. Can you help me create an integrated implementation plan that identifies shared capabilities, optimizes implementation sequence, and maximizes platform cohesion? I want to understand the best approach for combining these scenarios.
   ```

   - [ ] Send this integration request
   - [ ] **Expected result**: Planner asks about implementation priorities and constraints

3. **Define** implementation parameters
   - [ ] When asked about priorities, respond: "Quality optimization should be implemented first to establish foundation, then packaging optimization"
   - [ ] Specify timeline preference: "Looking for 18-month total implementation with maximum shared platform benefits"
   - [ ] **Success check**: Planner begins integrated analysis

4. **Review** the integrated implementation plan
   - [ ] Examine the recommended implementation sequence
   - [ ] Identify shared capabilities (Edge Data Processing, Device Management, Cloud Data Platform)
   - [ ] Note the projected ROI improvements from platform sharing
   - [ ] **Expected result**: Comprehensive multi-scenario implementation roadmap

### Task 4: Documentation and Roadmap Validation (10 minutes)

**What You'll Do**: Validate the comprehensive multi-scenario implementation roadmap against available capability documentation and ensure implementation feasibility

**Steps**:

1. **Locate** the generated integrated project documentation
   - [ ] Find the multi-scenario project plan folder in `./.copilot-tracking/`
   - [ ] Navigate to the comprehensive implementation roadmap and integrated planning files
   - [ ] **Expected result**: Structured documentation with unified multi-scenario implementation plan

2. **Cross-reference** capability requirements
   - [ ] Open `/docs/project-planning/scenarios/quality-process-optimization-automation/README.md`
   - [ ] Review `/docs/project-planning/scenarios/packaging-line-performance-optimization/README.md`
   - [ ] Validate the planner's integrated capability mapping against scenario documentation
   - **Pro tip**: Look for capability overlaps that reduce overall implementation complexity
   - [ ] **Expected result**: Confirmed alignment between planner recommendations and scenario requirements

3. **Assess** implementation feasibility
   - [ ] Review the accelerator support levels for integrated capabilities
   - [ ] Identify any "Planned Components" or "External Dependencies" in the unified plan
   - [ ] Note potential implementation risks or dependencies across both scenarios
   - **Validation checkpoint**: Can the shared capabilities serve both scenarios without significant customization?
   - [ ] **Expected result**: Clear understanding of comprehensive implementation readiness and coordination requirements

## Completion Check

**You've Succeeded When**:

- [ ] Successfully analyzed both quality and packaging optimization scenarios
- [ ] Created an integrated implementation plan using the edge-ai-project-planner
- [ ] Identified shared capabilities and platform cohesion between scenarios
- [ ] Validated the implementation roadmap against scenario documentation
- [ ] Understand the benefits of multi-scenario platform deployment

**Next Steps**: Continue with [03 - Advanced Strategic Planning][kata-03] to learn enterprise-scale deployment strategies.

---

## Reference Appendix

### Help Resources

- **Quality Process Optimization**: `/docs/project-planning/scenarios/quality-process-optimization-automation/` for detailed capability mapping
- **Packaging Line Performance**: `/docs/project-planning/scenarios/packaging-line-performance-optimization/` for implementation guidance
- **Capability Overview**: `/docs/project-planning/capabilities/` for accelerator support details

### Professional Tips

- Compare capability readiness levels between scenarios to prioritize implementation sequence
- Look for "Ready to Deploy" capabilities that can serve both scenarios for quick wins
- Pay attention to shared data platform requirements that can reduce overall implementation costs

### Troubleshooting

**Issue**: Planner provides generic recommendations instead of scenario-specific advice

- **Quick Fix**: Be more specific about manufacturing context and provide quantitative improvement targets

**Issue**: Integration plan seems to favor one scenario over the other

- **Quick Fix**: Explicitly request balanced integration and specify equal business priority for both scenarios

---

[kata-01]: /learning/katas/project-planning/01-basic-prompt-usage.md
[kata-03]: /learning/katas/project-planning/03-advanced-strategic-planning.md

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
