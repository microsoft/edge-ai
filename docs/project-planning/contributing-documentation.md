---
title: Contributing Documentation to the Project Planning Framework
description: This guide explains how to contribute new scenarios, capabilities, and
  capability groups to the Edge AI Project Planning...
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: hub-page
keywords:
  - overview
  - index
  - navigation
  - workspaces
  - edge
  - project
  - planning
  - contributing
estimated_reading_time: 4
---

This guide explains how to contribute new scenarios, capabilities, and capability groups to the Edge AI Project Planning framework using our standardized templates.

## Overview

The project planning framework thrives on community contributions that expand the available scenarios and capabilities. Your real-world implementations and custom capabilities help other teams plan and implement their edge AI projects more effectively.

## What You Can Contribute

### 1. Implementation Scenarios

Document real-world implementations that other teams can learn from and adapt:

- Manufacturing automation scenarios
- Quality control implementations
- Predictive maintenance solutions
- Operational optimization projects
- Industry-specific edge AI applications

### 2. Platform Capabilities

Document individual technical capabilities you've developed:

- Custom edge processing capabilities
- Specialized AI/ML inference engines
- Integration connectors
- Monitoring and observability tools
- Security and compliance features

### 3. Capability Groups

Document comprehensive capability groups that span multiple capabilities:

- Industry-specific capability groups (e.g., manufacturing automation, energy optimization)
- Technology-focused groups (e.g., computer vision platform, predictive analytics suite)
- Integration-focused groups (e.g., enterprise connectivity, cloud-edge orchestration)

## How to Contribute

### Using the Documentation Templates

We provide standardized templates to ensure consistency and quality:

#### For Individual Capabilities

Use the [Capability Description Template][capability-description-template]:

1. **Copy the template** and rename it to match your capability
2. **Replace all placeholder text** in [brackets] with your content
3. **Follow the content guidelines** for each section
4. **Include the new project planning sections**:
   - Scenario Integration: How your capability supports existing scenarios
   - Project Planning Considerations: Prerequisites, dependencies, and timing

#### For Capability Groups

Use the [Capability Group Description Template][capability-group-description-template]:

1. **Copy the template** and rename it to match your capability group
2. **Document 4-7 individual capabilities** that comprise the group
3. **Emphasize synergies and integration** between capabilities
4. **Include the new project planning sections**:
   - Scenario Integration & Use Cases: Primary and secondary scenario support
   - Project Planning Considerations: Implementation sequencing and resource planning

### Template Features for Project Planning

Both templates include project planning-specific enhancements:

#### Integration with Existing Framework

- **Scenario References**: Link to existing scenarios that benefit from your contribution
- **Capability Mapping**: Show how your contribution fits with existing capability groups
- **AI Planning Support**: Provide information that enhances the AI planning assistant

#### Project Planning Guidance

- **Prerequisites**: What must be in place before implementing your capability/group
- **Dependencies**: What your contribution depends on and what depends on it
- **Timing**: When in the project lifecycle your contribution should be implemented
- **Resource Planning**: Skills, infrastructure, and timeline considerations

## Contribution Process

### 1. Planning Your Contribution

Before writing documentation:

- **Review existing content** in [scenarios][scenarios] and [capabilities][capabilities] to avoid duplication
- **Identify gaps** that your contribution addresses
- **Consider integration points** with existing scenarios and capabilities
- **Plan for community benefit** - how will others use your contribution?

### 2. Writing Your Documentation

Follow the template guidelines:

- **Use the appropriate template** (capability vs. capability group)
- **Follow markdown formatting requirements** from `.mega-linter.yml`
- **Meet content quality guidelines** for technical depth and business value
- **Include project planning considerations** to help future implementers

### 3. Integration Considerations

Ensure your contribution integrates well:

#### Scenario Integration

- **Identify relevant scenarios** from the [scenarios folder][scenarios-folder]
- **Document specific value** your contribution provides to each scenario
- **Consider cross-scenario benefits** and synergies

#### Capability Mapping

- **Reference existing capabilities** from the [capabilities folder][capabilities-folder]
- **Identify dependencies** on other capabilities or infrastructure
- **Document integration patterns** and data flows

#### AI Planning Enhancement

- **Provide clear metadata** about when and how to use your contribution
- **Include decision criteria** for selecting your contribution over alternatives
- **Document common implementation patterns** and best practices

### 4. Quality Assurance

Before submitting:

- **Use the quality checklist** included in each template
- **Validate markdown formatting** using the linter
- **Test scenario integration** by walking through relevant use cases
- **Review project planning sections** for completeness and accuracy

## Contribution Examples

### Example: Custom Computer Vision Capability

```markdown
# Smart Quality Inspection Capability

## Abstract Description

The Smart Quality Inspection Capability provides real-time computer vision-based
quality control for manufacturing environments...

## Scenario Integration

This capability directly supports the Digital Inspection & Survey scenario by
providing automated visual inspection of products and components...

## Project Planning Considerations

Teams implementing Smart Quality Inspection should have basic edge infrastructure
in place and plan for 4-6 weeks of model training and calibration...
```

### Example: Manufacturing Automation Capability Group

```markdown
# Manufacturing Automation Platform

## Abstract Description

The Manufacturing Automation Platform represents a comprehensive suite of
capabilities that enable end-to-end factory automation...

## Scenario Integration & Use Cases

This capability group serves as the foundation for multiple manufacturing
scenarios including Packaging Line Optimization, Quality Process Automation...

## Project Planning Considerations

Manufacturing Automation Platform implementation requires significant
infrastructure preparation and should be planned as a 12-18 month initiative...
```

## Community Benefits

Your contributions provide value to the entire community:

### For Project Teams

- **Accelerated Planning**: Teams can leverage your experience for faster project planning
- **Risk Reduction**: Learning from your implementation reduces project risks
- **Best Practices**: Your documentation shares proven approaches and patterns

### For the Platform

- **Expanded Capability Catalog**: More options for teams to choose from
- **Enhanced AI Planning**: Better guidance from the AI planning assistant
- **Community Knowledge**: Collective wisdom that benefits everyone

### For You

- **Knowledge Sharing**: Establish expertise and thought leadership
- **Community Recognition**: Recognition for contributing to the platform
- **Continuous Improvement**: Feedback from the community improves your approaches

## Getting Started

Ready to contribute? Here's how to begin:

1. **Identify your contribution**: What scenario, capability, or capability group do you want to document?
2. **Choose your template**: [Capability Description][capability-description] or [Capability Group Description][capability-group-description]
3. **Study existing examples**: Review similar contributions in [scenarios][scenarios] and [capabilities][capabilities]
4. **Start writing**: Follow the template guidelines and content requirements
5. **Get feedback**: Share drafts with the community for review and improvement

## Support and Questions

- **Documentation Questions**: Review existing examples and template guidelines
- **Technical Questions**: Engage with the community through discussions
- **Contribution Process**: Follow the contributing guidelines in the main repository

---

*Your contributions make the Edge AI Project Planning framework more valuable for everyone. Thank you for sharing your expertise and helping the community succeed!*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[capabilities]: ./capabilities/
[capabilities-folder]: ./capabilities/
[capability-description]: ./templates/capability-description-template.md
[capability-description-template]: ./templates/capability-description-template.md
[capability-group-description]: ./templates/capability-group-description-template.md
[capability-group-description-template]: ./templates/capability-group-description-template.md
[scenarios]: ./scenarios/
[scenarios-folder]: ./scenarios/
