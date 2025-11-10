---
title: Track 3 - Azure DevOps End-to-End Automation
description: Build complete Azure DevOps automation workflows from requirement analysis to pull request creation and build validation
author: Edge AI Team
ms.date: 2025-10-14
ms.topic: hub-page
estimated_reading_time: 8
difficulty: intermediate to advanced
keywords:
  - learning
  - azure devops
  - automation
  - chatmodes
  - work items
  - ci cd
  - mcp tools
---

## 🚧 Coming Soon - Track 3 Development

Track 3 is currently under development and will focus on building complete Azure DevOps automation workflows using the edge-ai repository's chatmode, prompt, and instruction file ecosystem. This comprehensive track will take you from requirement analysis through work item planning, creation, pull request management, and build validation.

> **📅 Development Status**: All lab modules are currently in development. The detailed curriculum below represents our planned content to demonstrate the comprehensive learning experience we're creating.

### What You'll Learn (Planned)

- **End-to-End Automation**: From PRD documents to deployed changes with build validation
- **Chatmode Orchestration**: Coordinate multiple specialized AI assistants across complex scenarios
- **MCP Tool Integration**: Azure DevOps work items, repositories, pipelines, and wikis
- **Instruction File Workflows**: Ensure consistent, repeatable automation across teams

### Planned Track Structure

**Planned Total Duration**: 8-12 hours
**Prerequisites**: Azure DevOps access and familiarity with the edge-ai repository
**Approach**: Hands-on lab modules integrating all Azure DevOps automation capabilities
**Learning Resources**: Integrated with [Azure DevOps documentation][azure-devops-docs] and [MCP documentation][mcp-docs]

## Overview (Planned)

This comprehensive training lab will guide you through building complete Azure DevOps automation workflows using the edge-ai repository's chatmode, prompt, and instruction file ecosystem. You'll develop expertise in end-to-end automation from requirement analysis through work item planning, creation, pull request management, and build validation.

Unlike individual katas that focus on specific skills, this lab integrates all Azure DevOps automation capabilities into realistic workflows that mirror actual enterprise development scenarios.

## Planned Learning Objectives (Coming Soon)

By completing this training lab, you will:

- Develop expertise in end-to-end automation workflows from Product Requirements Documents (PRDs) to deployed changes with build validation
- Apply chatmode orchestration patterns to coordinate multiple specialized AI assistants across complex automation scenarios
- Build proficiency with MCP tool integration for Azure DevOps work items, repositories, pipelines, and wikis
- Implement systematic instruction file workflows that ensure consistent, repeatable automation across teams
- Create production-ready automation patterns that scale from individual contributors to enterprise teams

## Prerequisites (Planned)

### Technical Requirements

- **Azure DevOps Access**: Organization and project with work item and repository permissions
- **Repository Knowledge**: Familiarity with the edge-ai repository structure and Azure DevOps integration
- **Git Proficiency**: Solid understanding of branching, pull requests, and merge workflows
- **AI Assistant**: VS Code with GitHub Copilot or equivalent with MCP support

### Knowledge Prerequisites

- **Completed Katas** (recommended): [Azure DevOps Automation Katas][ado-katas]
- **Development Workflows**: Understanding of basic development processes
- **Version Control**: Experience with Git and pull request workflows

## Planned Architecture Overview (Coming Soon)

This lab will implement a complete automation workflow that:

1. **Analyzes requirements** from PRD documents using semantic understanding
2. **Plans work item hierarchies** with Epic → Features → User Stories → Tasks structure
3. **Creates work items** using batch MCP operations with proper linking and validation
4. **Generates feature branches** and implements changes following project conventions
5. **Automates pull request creation** with reviewer discovery, work item linking, and description generation
6. **Monitors build pipelines** and updates work item status based on build results
7. **Validates deployments** and provides rollback procedures for failed builds

### Planned Industry Scenario & Capability Mapping (Coming Soon)

**Real-World Context**: This training lab will simulate the workflow used by platform engineering teams managing complex Infrastructure as Code (IaC) repositories with Azure DevOps.

#### Platform Capabilities to be Demonstrated (Planned)

| Lab Module                            | Azure DevOps Capability | Implementation Focus                                      |
|---------------------------------------|-------------------------|-----------------------------------------------------------|
| Requirement Analysis (Coming Soon)    | Work Item Tracking      | PRD parsing, requirement decomposition                    |
| Work Item Planning (Coming Soon)      | Boards & Backlogs       | Epic/Feature/Story hierarchy design                       |
| Automated Work Item Creation          | Work Item APIs          | Batch MCP operations, field validation                    |
| Pull Request Automation (Coming Soon) | Repos & Pull Requests   | Branch automation, reviewer assignment, work item linking |
| Build Integration (Coming Soon)       | Pipelines & CI/CD       | Build monitoring, status updates, deployment triggers     |
| Validation & Rollback (Coming Soon)   | Release Management      | Deployment validation, rollback procedures                |

#### Business Value Connection (Planned)

- **Scenario Alignment**: Reduces work item creation time from hours to minutes, enabling rapid requirement breakdown and team planning
- **Capability Integration**: Integrates Azure DevOps Boards, Repos, and Pipelines with AI-assisted automation for complete workflow coverage
- **Scaling Considerations**: Patterns scale from individual repositories to multi-repo coordination across enterprise portfolios

## Planned Lab Modules (Coming Soon)

### Module 1: Requirement Analysis & Work Item Discovery (Coming Soon)

**Planned Duration**: 2-3 hours

**Objectives**:

- Activate appropriate chatmodes for requirement analysis
- Use MCP tools to discover related work items and avoid duplication
- Parse PRD documents to identify Epic/Feature/Story structure
- Validate requirement completeness and clarity

[**Module 1 Details →**][module-1-details] *(Coming Soon)*

### Module 2: Work Item Hierarchy Planning (Coming Soon)

**Planned Duration**: 2-3 hours

**Objectives**:

- Follow instruction file phases for systematic planning
- Design complete work item hierarchy with proper relationships
- Define acceptance criteria, success metrics, and validation steps
- Create planning document following project conventions

[**Module 2 Details →**][module-2-details] *(Coming Soon)*

### Module 3: Automated Work Item Creation (Coming Soon)

**Planned Duration**: 2-3 hours

**Objectives**:

- Execute batch MCP operations for work item creation
- Implement proper work item linking (parent-child, related, dependencies)
- Validate field population and work item state
- Handle errors and retry failed operations

[**Module 3 Details →**][module-3-details] *(Coming Soon)*

### Module 4: Pull Request Automation with Work Item Linking (Coming Soon)

**Planned Duration**: 2-3 hours

**Objectives**:

- Generate feature branches following naming conventions
- Implement changes for first User Story or Task
- Automate pull request creation with work item linking
- Discover and assign appropriate reviewers
- Generate comprehensive PR descriptions

[**Module 4 Details →**][module-4-details] *(Coming Soon)*

### Module 5: Build Monitoring & Deployment Validation (Coming Soon)

**Planned Duration**: 2-3 hours

**Objectives**:

- Monitor build pipeline execution in real-time
- Retrieve and analyze build logs for errors
- Update work item status based on build results
- Implement rollback procedures for failed builds
- Validate successful deployments

[**Module 5 Details →**][module-5-details] *(Coming Soon)*

## Planned Lab Completion Summary (Coming Soon)

### Final Validation Checklist (Planned)

- [ ] Complete end-to-end workflow executed (PRD → Deployment)
- [ ] All work items created with proper hierarchy and linking
- [ ] Pull request created with reviewer assignment and work item links
- [ ] Build pipeline monitored and validated
- [ ] Work items updated with build results and deployment status
- [ ] All chatmodes and instruction files used appropriately
- [ ] Automation patterns documented for team reuse

### Key Learning Takeaways (Planned)

- **Chatmode Orchestration (Coming Soon)**: Different chatmodes specialize in different tasks - use `ado-prd-to-wit` for planning, default/generic for PR creation and build monitoring
- **Instruction Files as Playbooks (Planned)**: Instruction files ensure consistent workflows across team members and prevent missed steps
- **MCP Tool Proficiency (Coming Soon)**: Batch operations, proper error handling, and tool parameter understanding are critical for reliable automation
- **End-to-End Thinking (Planned)**: Automation must span the entire workflow from requirement to deployment, not just individual phases
- **Validation at Every Stage (Coming Soon)**: Each module includes validation checkpoints to catch errors early and ensure quality

### Recommended Next Steps (Planned)

- **Scale to Multiple Repositories (Coming Soon)**: Apply these patterns across repository portfolios with coordinated work items and PRs
- **Build Custom Chatmodes (Coming Soon)**: Create specialized chatmodes for your team's unique workflows and tooling
- **Automate Deployment Pipelines (Planned)**: Extend automation to include deployment approvals, monitoring, and rollback
- **Integrate Advanced Analytics (Coming Soon)**: Add work item analytics, cycle time tracking, and team velocity measurements
- **Share with Team (Planned)**: Document your automation patterns and train team members on chatmode usage

## Planned Optional Advanced Challenges (Coming Soon)

### Challenge A: Multi-Repository Coordination (Coming Soon)

**Duration**: 3-4 hours | **Difficulty**: Advanced

Coordinate work items and pull requests across multiple repositories (e.g., infrastructure changes + application updates):

- Create Epic spanning multiple repositories
- Coordinate feature branch naming across repos
- Create dependent PRs with proper ordering
- Monitor builds across repositories
- Update work items with cross-repo links

### Challenge B: Custom Chatmode Development (Coming Soon)

**Duration**: 4-5 hours | **Difficulty**: Expert

Build a custom chatmode for your team's specific automation needs:

- Design chatmode for specialized workflow (e.g., security review, compliance validation)
- Define required MCP tools and permissions
- Write comprehensive chatmode description and usage examples
- Test chatmode with real scenarios
- Document chatmode for team adoption

## Planned Troubleshooting Guide (Coming Soon)

### Common Issues (Planned)

#### Problem: MCP Tool Not Available in Chatmode (Coming Soon)

**Solution**:

1. Verify chatmode file includes tool in `tools:` array
2. Check GitHub Copilot MCP extension is enabled
3. Restart VS Code and re-activate chatmode
4. Manually specify tool in prompt: "Use mcp_azure-devops_wit_create_work_item to..."

#### Problem: Work Item Creation Fails with Field Validation Error (Coming Soon)

**Solution**:

1. Review error message for specific field name
2. Verify field value matches Azure DevOps field type (string, integer, date)
3. Check if field requires specific format (e.g., "Area Path" must match existing area)
4. Validate work item type supports the field (not all fields exist on all types)
5. Retry creation with corrected field value

#### Problem: PR Creation Fails - "Branch Already Has Open PR" (Coming Soon)

**Solution**:

1. Search for existing PR using `mcp_azure-devops_repo_list_pull_requests_by_repo`
2. If duplicate, update existing PR instead of creating new one
3. If stale, close old PR and create new one
4. Verify branch name is unique and follows conventions

#### Problem: Build Status Shows "Running" but Never Completes (Coming Soon)

**Solution**:

1. Check Azure DevOps web interface for build status
2. Verify build pipeline is not waiting for manual approval
3. Check if build agent is online and has capacity
4. Look for build logs indicating hung test or deployment step
5. Cancel and restart build if necessary

#### Problem: Work Item Links Not Appearing in PR (Coming Soon)

**Solution**:

1. Verify commit message includes work item ID (e.g., "#12345")
2. Use "AB#12345" format if required by your Azure DevOps configuration
3. Manually add work item links using `mcp_azure-devops_wit_link_work_item_to_pull_request`
4. Check Azure DevOps project settings for PR-work item integration

## Planned Resources (Coming Soon)

### Official Documentation (Coming Soon)

- [Azure DevOps REST API][ado-rest-api] - Complete API reference for all operations
- [Azure DevOps Work Items][ado-work-items] - Work item types, fields, and best practices
- [Azure DevOps Pull Requests][ado-pull-requests] - PR creation, review, and merge workflows
- [Azure DevOps Pipelines][ado-pipelines] - Build and deployment pipeline configuration

### edge-ai Repository Resources (Coming Soon)

- [Azure DevOps Automation Katas][ado-katas] - Individual skill-building exercises
- [Chatmode Documentation][chatmode-docs] - Complete chatmode reference and examples
- [Instruction Files][instruction-files] - All available instruction file workflows
- [Prompt Templates][prompt-templates] - Reusable prompt patterns for common tasks

### Community & Support (Coming Soon)

- [Edge AI Discussions][edge-ai-discussions] - Community Q&A and knowledge sharing
- [Azure DevOps Community][ado-community] - Official Azure DevOps forums and support

---

*This training lab is part of the AI-Assisted Engineering Learning Platform.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[azure-devops-docs]: https://learn.microsoft.com/en-us/azure/devops/
[mcp-docs]: https://modelcontextprotocol.io/
[module-1-details]: #module-1-requirement-analysis--work-item-discovery-coming-soon
[module-2-details]: #module-2-work-item-hierarchy-planning-coming-soon
[module-3-details]: #module-3-automated-work-item-creation-coming-soon
[module-4-details]: #module-4-pull-request-automation-with-work-item-linking-coming-soon
[module-5-details]: #module-5-build-monitoring--deployment-validation-coming-soon
[ado-katas]: /learning/katas/ado-automation/README
[chatmode-docs]: /.github/chatmodes/README
[instruction-files]: /.github/instructions/README
[prompt-templates]: /.github/prompts/README
[ado-rest-api]: https://learn.microsoft.com/en-us/rest/api/azure/devops
[ado-work-items]: https://learn.microsoft.com/en-us/azure/devops/boards/work-items/about-work-items
[ado-pull-requests]: https://learn.microsoft.com/en-us/azure/devops/repos/git/pull-requests
[ado-pipelines]: https://learn.microsoft.com/en-us/azure/devops/pipelines/
[edge-ai-discussions]: https://github.com/microsoft/edge-ai/discussions
[ado-community]: https://developercommunity.visualstudio.com/spaces/21/index.html
