---
title: 'Kata: 100 - Basic Project Planning Prompt Usage'
description: Learn basic prompt engineering for project planning and develop structured planning workflows using AI assistance
author: Edge AI Team
ms.date: 2025-06-17
kata_id: project-planning-100-basic-prompt-usage
kata_category:
  - project-planning
kata_difficulty: 1
estimated_time_minutes: 30
learning_objectives:
  - Learn basic prompt engineering for project planning
  - Understand AI-assisted planning fundamentals
  - Practice effective prompt structure for project tasks
  - Develop foundation skills in AI-driven project management
prerequisite_katas: []
technologies:
  - GitHub Copilot
success_criteria:
  - Learn basic prompt engineering for project planning
  - Develop structured planning workflows using AI assistance
  - Create effective project documentation and requirements
  - Implement iterative project planning methodologies
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - project-planning
search_keywords:
  - project-planning-basics
  - prompt-engineering
  - ai-assisted-planning
  - predictive-maintenance-planning
  - business-scenario-analysis
---

## Quick Context

**You'll Learn**: How to use the edge-ai-project-planner chatmode to create comprehensive project documentation from a business scenario

**Prerequisites**: VS Code with GitHub Copilot Chat, basic understanding of project planning concepts

**Real Challenge**: Your manufacturing facility has frequent unexpected equipment breakdowns causing production delays and high maintenance costs. You need to implement an Edge AI solution that can predict equipment failures before they occur.

**Your Task**: Use the edge-ai-project-planner chatmode to create a complete predictive maintenance project plan with scenario documentation and capability mapping.

## Essential Setup

**Complete these checks before starting** - verifying your setup ensures successful kata completion:

**Required** (check these first):

- [ ] VS Code with GitHub Copilot Chat installed and working
- [ ] Access to the edge-ai workspace (this repository)
- [ ] Basic understanding of manufacturing operations

**Quick Validation**: Open GitHub Copilot Chat and verify you can type `@` to see available chat mode suggestions.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 01 - Basic Project Planning Prompt Usage kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Launch the Project Planner (8 minutes)

**What You'll Do**: Start the edge-ai-project-planner chatmode and provide your manufacturing scenario

**Steps**:

1. **Open** GitHub Copilot Chat in VS Code
   - [ ] Click the Copilot Chat icon in the Activity Bar
   - [ ] **Expected result**: Chat panel opens on the side

2. **Activate** the edge-ai-project-planner chat mode
   - [ ] In the chat input box, type `@edge-ai-project-planner`
   - [ ] **Expected result**: You see the project planner mode suggested/activated in the chat interface

3. **Provide** your manufacturing scenario using this exact description:

   ```text
   I have a manufacturing facility with packaging equipment that breaks down frequently, causing production delays and high maintenance costs. We want to implement predictive maintenance to prevent equipment failures before they occur. Our goal is to reduce unplanned downtime by at least 40% and optimize our maintenance schedules.
   ```

- [ ] Send this message to the project planner
- [ ] **Success check**: The planner responds with follow-up questions about your industry or implementation scope

### Task 2: Navigate Scenario Selection (10 minutes)

**What You'll Do**: Respond to the planner's questions and select the predictive maintenance scenario

**Steps**:

1. **Answer** follow-up questions about your context
   - [ ] When asked about industry: "Manufacturing - packaging operations"
   - [ ] When asked about scope: "Pilot project to prove value before enterprise rollout"
   - [ ] Respond naturally to any other clarifying questions
   - [ ] **Expected result**: Planner suggests scenario options including Predictive Maintenance

2. **Select** the Predictive Maintenance scenario
   - [ ] When presented with scenario options, clearly state: "I want to focus on the Predictive Maintenance scenario"
   - [ ] **Expected result**: Planner confirms scenario selection and begins capability mapping

3. **Confirm** planning scope when prompted
   - [ ] When asked about documentation location, respond: "Please save to the default location"
   - [ ] **Expected result**: Planner begins generating comprehensive project documentation

### Task 3: Review Generated Documentation (12 minutes)

**What You'll Do**: Examine the project documentation created by the planner and understand its structure

**Steps**:

1. **Locate** the generated project documentation
   - [ ] Look for a new folder in `./.copilot-tracking/project-plan-[timestamp]/`
   - [ ] Use VS Code's Explorer panel to navigate to this folder
   - [ ] **Expected result**: You find a structured project documentation folder

2. **Examine** the main project README
   - [ ] Open the README.md file in the project plan folder
   - [ ] Read through the project overview, objectives, and implementation approach
   - [ ] **Expected result**: Clear project summary with business case and technical approach

3. **Review** scenario documentation
   - [ ] Navigate to the scenarios/predictive-maintenance/ subfolder
   - [ ] Open and review the README.md, prerequisites.md, and capability-mapping.md files
   - [ ] Note the capability requirements and implementation phases
   - [ ] **Success criteria**: You understand the required platform capabilities and implementation roadmap

**Next Steps**: Continue with [02 - Comprehensive Two-Scenario][kata-02] to learn multi-scenario planning.

## Completion Check

### Self-Test Your Knowledge

**Before moving on, verify your understanding**:

- [ ] **Explain aloud** in 2-3 sentences: How does the edge-ai-project-planner chatmode help create comprehensive project documentation?
- [ ] **List from memory** at least 3 key files generated in the project plan folder structure
- [ ] **Describe without looking** the main steps in the predictive maintenance scenario selection workflow

### You've Succeeded When

- [ ] Successfully launched edge-ai-project-planner and provided manufacturing scenario
- [ ] Navigated scenario selection and chose Predictive Maintenance scenario
- [ ] Reviewed generated project documentation and understand capability requirements
- [ ] Can explain the predictive maintenance implementation approach and required capabilities
- [ ] Built proficiency in prompt engineering for project planning using GitHub Copilot chat modes
- [ ] Developed comprehensive project planning workflows that leverage AI assistance
- [ ] Created professional documentation artifacts that meet enterprise quality standards
- [ ] Can implement AI-assisted planning methodologies and apply them to real-world scenarios

**Next Steps**: Continue with [02 - Comprehensive Two-Scenario][kata-02] to learn multi-scenario planning.

---

## Reference Appendix

### Help Resources

- **Edge AI Project Planner**: Use for guided scenario selection and capability mapping
- **Project Planning Documentation**: `/docs/project-planning/` for additional scenario details
- **Predictive Maintenance Scenario**: `/docs/project-planning/scenarios/predictive-maintenance/` for reference

### Professional Tips

- Provide specific business metrics (like "40% reduction in downtime") to get more targeted recommendations
- Answer questions completely the first time to streamline the planning process

### Troubleshooting

**Issue**: `@edge-ai-project-planner` not being recognized

- **Quick Fix**: Ensure you have the latest version of GitHub Copilot extension, or try typing `@` to see available modes

**Issue**: Project planner asks too many questions

- **Quick Fix**: Provide specific, detailed responses to minimize follow-up questions

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[kata-02]: /learning/katas/project-planning/02-comprehensive-two-scenario.md
