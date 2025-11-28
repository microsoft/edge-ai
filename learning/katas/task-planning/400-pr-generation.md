---
title: 'Kata: 400 - PR Generation'
description: Learn AI-assisted PR generation workflow through systematic analysis of git changes, creating accurate PR descriptions...
author: Edge AI Team
ms.date: 2025-06-16
kata_id: task-planning-400-pr-generation
kata_category:
  - task-planning
kata_difficulty: 4
estimated_time_minutes: 90
learning_objectives:
  - Learn automated pull request generation and management
  - Develop systematic code review and collaboration workflows
  - Create effective PR documentation and communication strategies
prerequisite_katas:
  - task-planning-100-edge-documentation-planning
  - 'task-planning-300-repository-analysis-planning'
  - 'task-planning-400-ai-asset-extraction'
  - 'task-planning-400-learning-platform-extraction'
  - task-planning-400-advanced-capability-integration
technologies:
  - GitHub Copilot
  - Azure DevOps
success_criteria:
  - Task planning and PR generation workflows understood
  - Comprehensive PR generation workflow proficiency achieved
  - Ready to generate production-quality PRs independently
  - High-quality PR documentation created
  - Effective collaboration workflow implemented
  - Security validation processes integrated
ai_coaching_level: guided
scaffolding_level: light
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - task-planning
search_keywords:
  - pull-request-generation
  - pr-documentation
  - git-workflow
  - code-review
  - ai-assisted-development
---

## Quick Context

**You'll Learn**: Learn AI-assisted PR generation through systematic git analysis and structured documentation workflows.

**Real-World Context**: Development teams need efficient workflows for creating comprehensive PR descriptions that accurately document changes, security implications, and business value. This kata teaches systematic approaches using AI assistance for thorough git analysis and professional documentation.

## Essential Setup

- [ ] VS Code with GitHub Copilot extension and active subscription; GitHub Copilot Chat access
- [ ] Completed task-planning katas: 100-edge-documentation-planning, 300-repository-analysis-planning, 400-ai-asset-extraction, 400-learning-platform-extraction, 400-advanced-capability-integration
- [ ] Git workflow experience (branch management, commit history analysis, merge strategies)
- [ ] GitHub Copilot Chat prompt engineering and context management skills
- [ ] PR documentation standards and security documentation understanding
- [ ] Repository with active branch and commits
- [ ] Time allocated: ⏱️ **90 minutes** (git analysis, PR generation, review workflow)

**Quick Validation**: Verify Git and Copilot with `git status && code --list-extensions | grep -i copilot`.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 06 - PR Generation kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Git Change Analysis and Documentation Planning (15 minutes)

**What You'll Do**: Systematically analyze git changes and plan comprehensive documentation approach

**Steps**:

1. **Analyze** git changes and commit history
   - [ ] Review file modifications, additions, and deletions systematically
   - [ ] Identify business logic changes, configuration updates, and dependency modifications
   - [ ] Map changes to affected components and integration points
   - [ ] **Expected result**: Complete inventory of all changes with impact classification

2. **Plan** documentation structure and approach
   - [ ] Organize changes by category (features, fixes, refactoring, configuration)
   - [ ] Identify security implications and compliance requirements
   - [ ] Plan technical details and business value documentation
   - [ ] **Expected result**: Structured approach for comprehensive PR documentation

3. **Prepare** AI assistance strategy
   - [ ] Use GitHub Copilot Chat for change analysis and documentation generation
   - [ ] Plan validation checkpoints for accuracy and completeness
   - [ ] **Success check**: Documentation plan covering all changes with AI-assisted approach

### Task 2: AI-Assisted PR Description Generation (20 minutes)

**What You'll Do**: Generate comprehensive PR description using AI assistance and systematic validation

**Steps**:

1. **Generate** initial PR description with AI assistance
   - [ ] Use GitHub Copilot Chat to analyze git changes and create base documentation
   - [ ] Apply project PR template and formatting standards
   - [ ] Include technical details, business value, and testing information
   - [ ] **Expected result**: Complete PR description draft with all required sections

2. **Validate** and enhance documentation quality
   - [ ] Review AI-generated content for accuracy and completeness
   - [ ] Add missing technical details and business context
   - [ ] Ensure security validation and compliance documentation
   - [ ] **Expected result**: Professional PR description meeting project standards

### Task 3: Security Validation and Final Review (10 minutes)

**What You'll Do**: Complete security validation and final documentation review

**Steps**:

1. **Conduct** security and compliance validation
   - [ ] Review changes for security implications and potential vulnerabilities
   - [ ] Validate compliance with project security standards
   - [ ] Document security considerations and mitigation measures
   - [ ] **Expected result**: Complete security validation with documented findings

2. **Finalize** PR documentation and submission
   - [ ] Review final PR description for completeness and accuracy
   - [ ] Ensure all project template requirements are met
   - [ ] Prepare for code review submission
   - [ ] **Success criteria**: Professional PR ready for submission with comprehensive documentation and security validation

## Completion Check

**Have you achieved systematic PR generation excellence?**

1. **Complete Git Change Analysis**: Did you systematically review all modifications with comprehensive file analysis and impact assessment?
2. **Comprehensive PR Documentation**: Did you use AI assistance to create accurate technical documentation with business value explanation?
3. **Security Validation Coverage**: Did you analyze security implications, compliance requirements, and potential vulnerabilities?
4. **Professional Quality Standards**: Did you meet all project template requirements with documentation ready for efficient code review?

---

## Reference Appendix

### Help Resources

- **GitHub Copilot Chat** - AI assistance for code analysis, documentation generation, and security validation
- **Project PR Template** (`.github/pull_request_template.md`) - Standard template structure and documentation requirements
- **Git Analysis Best Practices** - Systematic change review approaches and professional workflow patterns

### Professional Tips

- **Systematic Analysis First**: Review all git changes comprehensively before writing documentation - understand full impact
- **AI-Assisted Documentation**: Use Copilot Chat to generate initial PR descriptions, then refine for accuracy and completeness
- **Security-First Mindset**: Always consider security implications and compliance requirements during PR analysis

### Troubleshooting

- **Documentation Incomplete**: If AI-generated descriptions miss details, provide more context about changes and business value
- **Security Analysis Unclear**: Review project security guidelines and use specific prompts asking about vulnerability patterns

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
