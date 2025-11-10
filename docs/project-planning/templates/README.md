---
title: Project Planning Templates
description: Comprehensive templates for creating new documentation that integrates seamlessly with the Edge AI Project Planning framework including scenario and capability templates
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: hub-page
estimated_reading_time: 5
keywords:
  - templates
  - documentation
  - scenarios
  - capabilities
  - planning
  - framework
  - edge ai
  - project planning
---

## Project Planning Templates

This folder contains comprehensive templates for creating new documentation that integrates seamlessly with the Edge AI Project Planning framework.

## Template Overview

These templates provide a complete framework for documenting edge AI implementation scenarios, platform capabilities, and integration patterns.

### Scenario Templates

- **[Scenario Documentation Template][scenario-documentation-template]:** Complete scenario README template with comprehensive structure, implementation phases, and business planning
- **[Scenario README Template][scenario-readme-template]:** Navigation and implementation guide for scenario folders
- **[Prerequisites Template][prerequisites-template]:** Technical and organizational requirements documentation
- **[Capability Mapping Template][capability-mapping-template]:** Detailed capability analysis and integration patterns

### Capability Templates

- **[Capability Description Template][capability-description-template]:** Individual platform capability documentation
- **[Capability Group Description Template][capability-group-description-template]:** Strategic capability group documentation

## Template Structure & Purpose

### Scenario Documentation Template

**Purpose:** Complete scenario README template with comprehensive structure and implementation planning

**Key Sections:**

- YAML frontmatter with scenario metadata
- Scenario overview with technical description
- Critical capabilities mapping with implementation phases
- 4-phase implementation roadmap (PoC, PoV, Production, Scale)
- Business planning and ROI analysis with risk assessment
- Implementation success checklist and advancement criteria
- Related scenarios and cross-platform synergies

**Target Audience:** Technical architects, project managers, business stakeholders, implementers

### Scenario README Template

**Purpose:** Navigation and quick-start guide for scenario implementation

**Key Sections:**

- Implementation approach overview
- Resource organization and navigation
- Getting started guides by persona
- Key resources and documentation links

**Target Audience:** Developers, implementers, new team members

### Prerequisites Template

**Purpose:** Comprehensive requirements and readiness assessment

**Key Sections:**

- Technical infrastructure requirements
- Platform capability prerequisites
- Organizational readiness assessment
- Regulatory and compliance requirements

**Target Audience:** Project managers, technical architects, operations teams

### Capability Mapping Template

**Purpose:** Detailed technical capability analysis and integration planning

**Key Sections:**

- Implementation phase analysis
- Detailed capability evaluation with scoring
- Integration patterns and data flows
- Gap analysis and recommendations

**Target Audience:** Technical architects, platform engineers, capability developers

## Usage Guidelines

### Creating a New Scenario

1. **Start with the Scenario Documentation Template**
   - Use the **Scenario Documentation Template** as your complete README.md structure
   - Replace all placeholder content like `[SCENARIO_NAME]` with your specific scenario details
   - Focus on technical implementation approach and business transformation

2. **Analyze Technical Requirements**
   - Use the **Prerequisites Template** to document all technical and organizational requirements
   - Use the **Capability Mapping Template** for detailed technical capability analysis

3. **Create Implementation Guide**
   - Use the **Scenario README Template** to create navigation and quick-start documentation
   - Organize resources for different stakeholder personas

4. **Establish Folder Structure**
   - Create a dedicated folder: `/docs/project-planning/scenarios/your-scenario-name/`
   - Place the main scenario README.md (from documentation template) in the scenario folder
   - Place supporting documents in the same scenario-specific folder

### Recommended File Organization

```text
/docs/project-planning/scenarios/
└── your-scenario-name/                      # Scenario-specific folder
    ├── README.md                            # Main scenario documentation (from documentation template)
    ├── prerequisites.md                     # Requirements and readiness assessment
    ├── capability-mapping.md                # Detailed capability analysis
    └── [additional-resources]/              # Supporting documentation
```

## Template Features

### Docsify Integration

- **Metadata Support:** Templates include guidance for Docsify frontmatter when needed
- **Navigation Structure:** Consistent structure supports automated navigation generation
- **Cross-Reference Links:** Templates include proper linking patterns for documentation discoverability

### Responsible AI Footer

All templates include the standard responsible AI footer that emphasizes:

- Implementation following responsible AI principles
- Appropriate governance and human oversight
- Ethical considerations for AI-powered solutions

### Capability Framework Integration

- **Four-Dimensional Evaluation:** Technical Fit, Business Value, Implementation Practicality, Platform Cohesion
- **Phase-Based Implementation:** PoC, PoV, Production, Scale phases with specific timelines
- **Scoring Methodology:** Consistent 0-10 scoring with detailed justification requirements

### Quality Assurance

- **Markdown Linting:** Full compliance with `.mega-linter.yml` configuration
- **Content Guidelines:** Specific word count targets and content quality requirements
- **Quality Checklists:** Built-in validation checklists for content completeness

## Best Practices

### Content Development

1. **Business-First Approach:** Start with business context and value proposition
2. **Technical Depth:** Provide sufficient technical detail for implementation planning
3. **Integration Focus:** Emphasize capability integration and cross-scenario benefits
4. **Phased Implementation:** Structure content around the four implementation phases

### Documentation Quality

1. **Consistent Terminology:** Use terminology consistent with existing platform documentation
2. **Actionable Content:** Ensure all content provides actionable guidance
3. **Measurable Outcomes:** Include specific, measurable success criteria
4. **Cross-References:** Provide clear navigation to related scenarios and capabilities

### Stakeholder Alignment

1. **Multi-Persona Support:** Address needs of different stakeholder personas
2. **Executive Summary:** Provide executive-level insights and strategic positioning
3. **Technical Depth:** Include sufficient detail for technical implementation teams
4. **Implementation Guidance:** Provide practical guidance for project managers and implementers

## Contribution Guidelines

### Template Improvements

- Submit improvements through standard contribution channels
- Ensure changes maintain consistency with existing documentation standards
- Consider impact on existing scenario documentation

### New Scenario Development

1. **Review Existing Scenarios:** Understand existing patterns and avoid duplication
2. **Validate Business Case:** Ensure scenario addresses real business challenges
3. **Technical Validation:** Confirm capability requirements align with platform roadmap
4. **Community Review:** Engage community for feedback and validation

### Quality Standards

- Follow all markdown linting rules from `.mega-linter.yml`
- Maintain word count guidelines for readability and consistency
- Include all required sections and quality checklist items
- Validate all cross-references and external links

## Getting Started

1. **Choose Your Template:** Select the appropriate template based on your documentation needs
2. **Review Examples:** Study existing scenario documentation for patterns and best practices
3. **Plan Your Content:** Outline your scenario following the template structure
4. **Develop Iteratively:** Create content section by section, validating against quality guidelines
5. **Community Engagement:** Share drafts with community for feedback and improvement

---

*These scenario documentation templates are part of the Edge AI Project Planning framework. For questions about template usage or to contribute improvements, please refer to the [project planning documentation][project-planning-documentation] or engage with the community through established contribution channels.*

*All scenario documentation should follow responsible AI principles and include appropriate governance, monitoring, and human oversight considerations for AI-powered solutions.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[capability-description-template]: ./capability-description-template.md
[capability-group-description-template]: ./capability-group-description-template.md
[capability-mapping-template]: ./scenario-capability-mapping-template.md
[prerequisites-template]: ./scenario-prerequisites-template.md
[project-planning-documentation]: ./README.md
[scenario-documentation-template]: ./scenario-documentation-template.md
[scenario-readme-template]: ./scenario-readme-template.md
