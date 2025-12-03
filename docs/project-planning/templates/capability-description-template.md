---
title: Capability Description Template
description: Template for documenting individual platform capabilities with detailed technical specifications, implementation guidance, and integration patterns
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: template
estimated_reading_time: 3
keywords:
  - template
  - capability
  - documentation
  - technical specification
  - implementation
  - edge ai
---

<!--
CAPABILITY DESCRIPTION TEMPLATE

This template is part of the Edge AI Platform Project Planning ecosystem. Use this template to contribute new capability documentation that helps users plan and implement edge AI projects.

IMPORTANT INSTRUCTIONS FOR USING THIS TEMPLATE:

## Project Planning Context
This template helps create capability documentation that integrates with:
- [Project Planning Overview][project-planning-overview] - Main planning guide and process
- [Implementation Scenarios][implementation-scenarios] - Real-world project scenarios
- [AI Planning Assistant][ai-planning-assistant] - AI-powered planning guidance
- [Comprehensive Scenario Mapping][comprehensive-scenario-mapping] - Industry scenarios and capabilities

## Markdown Formatting Requirements
- ALWAYS follow markdown linting rules from /.mega-linter.yml in workspace root
- Headers must have a blank line before and after
- Use only `-` for unordered lists, `1.` for ordered lists
- Lists must have blank lines before and after
- Code blocks must use triple backticks with language specified
- Tables must have proper headers and separator rows
- Line length maximum: 500 characters (headings: 80 characters)
- No trailing whitespace
- No duplicate headers at same level

## Content Quality Guidelines
- Target length: 1500-2000 words total
- Focus on technical depth and implementation details
- Use enterprise-grade terminology and concepts
- Emphasize integration with broader platform ecosystem
- Include specific technologies, frameworks, and automation capabilities
- Balance technical detail with business value
- Ensure content is actionable and comprehensive
- Reference relevant implementation scenarios where appropriate

## Template Usage Instructions
- Replace ALL placeholder text in [brackets]
- Follow word count guidelines for each section
- Maintain consistent tone and technical sophistication
- Include relevant ADRs, security plans, and technical references
- Reference applicable scenarios from the scenarios/ folder
- Consider how this capability supports project planning workflows
- Validate against quality checklist at end of template
- Remove these instructions when creating actual capability documentation

## Required Template Sections
1. Abstract Description (200-300 words)
2. Detailed Capability Overview (150-250 words)
3. Core Technical Components (4-6 major areas with sub-capabilities)
4. Business Value & Impact (200-300 words)
5. Implementation Architecture & Technology Stack (200-300 words)
6. Scenario Integration (150-200 words) - NEW
7. Project Planning Considerations (100-150 words) - NEW
8. Strategic Platform Benefits (150-200 words)
-->

## Abstract Description

**Format:** Single comprehensive paragraph (200-300 words)

**Content Guidelines:**

- Provide a sophisticated, high-level overview that aggregates the platform capability's value proposition
- Define the capability as a comprehensive system or framework rather than individual features
- Emphasize integration with broader platform ecosystem and enterprise systems
- Highlight scale, automation, and enterprise-grade characteristics
- Include key technical differentiators and business outcomes
- Use technical terminology appropriate for enterprise architects and platform engineers
- End with strategic value statement about enabling business outcomes

**Template Structure:**
[Capability Name] is a [sophisticated/comprehensive/advanced] [domain] capability that enables [core value proposition] across [scope/scale] from a [architectural approach]. This capability provides [key technical capabilities list] for [target environments/use cases] at scale. It integrates seamlessly with [integration points] to deliver [enterprise characteristics] that ensures [operational outcomes] across [deployment scope] while [operational benefits] and [strategic outcomes].

## Detailed Capability Overview

**Format:** 2-3 paragraphs (150-250 words)

**Content Guidelines:**

- Provide context and positioning within broader platform ecosystem
- Explain the problem space and unique challenges addressed
- Bridge traditional approaches with modern edge/cloud paradigms
- Highlight architectural significance and foundational nature
- Set stage for detailed technical components

**Template Structure:**
[Capability Name] represents a [critical/foundational/strategic] [capability type] that [positioning statement] enabling organizations to [organizational outcome]. This capability bridges the gap between [traditional approach] and [modern challenges/requirements], where [specific challenges].

[Additional context about scope, complexity, integration requirements, and strategic importance]

## Core Technical Components

**Format:** 4-6 major technical areas, each with 3-5 detailed sub-capabilities

**Content Guidelines:**

- Organize by major technical domains or functional areas
- Each major component should represent a significant technical capability area
- Sub-capabilities should be detailed, technical, and implementation-focused
- Use active, outcome-oriented language
- Include specific technologies, frameworks, and integration points
- Emphasize automation, scale, and enterprise characteristics

**Template Structure:**

### 1. [Major Technical Area Name]

- **[Sub-Capability Name]:** [Detailed description of what this provides, how it works, and what outcomes it enables - 1-2 sentences with specific technical details]
- **[Sub-Capability Name]:** [Detailed description with implementation approach and business value]
- **[Sub-Capability Name]:** [Detailed description with integration points and technical characteristics]
- **[Sub-Capability Name]:** [Detailed description with automation and scale aspects]

### 2. [Major Technical Area Name]

[Continue pattern for 4-6 major areas]

## Business Value & Impact

**Format:** 3-4 major business value categories with specific outcomes

**Content Guidelines:**

- Focus on quantifiable business outcomes where possible
- Include operational, financial, and strategic benefits
- Use metrics and percentages when appropriate
- Connect technical capabilities to business results
- Address different stakeholder concerns (operations, security, finance, strategy)

**Template Structure:**

### [Business Value Category 1 - e.g., Operational Excellence]

- [Specific outcome with quantification if possible]
- [Specific outcome focusing on efficiency/productivity]
- [Specific outcome emphasizing consistency/reliability]

### [Business Value Category 2 - e.g., Security & Compliance]

- [Security-focused outcome with risk reduction]
- [Compliance-focused outcome with regulatory alignment]
- [Governance-focused outcome with audit/oversight capabilities]

### [Business Value Category 3 - e.g., Cost Optimization]

- [Cost reduction outcome with areas of savings]
- [Efficiency outcome with resource optimization]
- [ROI outcome with investment protection]

## Implementation Architecture & Technology Stack

**Format:** 2-3 sections covering Azure services, open source technologies, and integration patterns

**Content Guidelines:**

- Provide specific Azure services that enable this capability with links to official documentation, and remove the 'en-us' path components form all MSLearn links.
- Include relevant open source projects and frameworks with links to their official sites
- Highlight integration patterns and architectural approaches
- Focus on production-ready, enterprise-scale technologies
- Include both cloud-native and hybrid deployment options
- Emphasize standardized, well-supported technology choices
- All technology names should link to their official documentation for easy reference

**Template Structure:**

### Azure Platform Services

- **[Primary Azure Service Category]:** [Service names like [Azure Service Bus][service-names-like-azure-service-bus], [Azure Data Factory][azure-data-factory], etc.] - [Brief description of how these services enable the capability]
- **[Secondary Azure Service Category]:** [Service names with links to Azure documentation] - [Description of supporting role]
- **[Additional Azure Services]:** [Service names with links to Azure documentation] - [Integration and enhancement capabilities]

### Open Source & Standards-Based Technologies

- **[Technology Category]:** [Technology names like [Kubernetes][technology-names-like-kubernetes], [Apache Kafka][apache-kafka], etc.] - [Description of role in capability implementation]
- **[Framework/Library Category]:** [Technology names with links to official documentation] - [Description of development and runtime support]
- **[Standards/Protocols]:** [Standards like [OpenTelemetry][standards-like-opentelemetry], [OPC-UA][opc-ua], [ISA 95][isa-95], etc.] - [Description of interoperability and compliance with links to specifications]

### Architecture Patterns & Integration Approaches

- **[Pattern Name]:** [Description of architectural pattern and when to use it]
- **[Integration Pattern]:** [Description of how systems connect and communicate]
- **[Deployment Pattern]:** [Description of cloud, edge, or hybrid deployment approaches]

## Scenario Integration

**Format:** Two paragraphs (150-200 words total)

**Content Guidelines:**

- **First Paragraph (75-100 words):** Identify which scenarios from the [scenarios folder][scenarios-folder] most benefit from this capability
- **Second Paragraph (75-100 words):** Explain how this capability enhances or enables specific scenario implementations

**Template Structure:**

[Capability Name] directly supports the [primary scenario(s)] scenarios documented in our project planning framework, particularly enhancing [specific aspects] of [scenario implementation]. The capability provides [specific value] that addresses the [technical requirements] identified in these scenarios.

Additionally, this capability serves as an enabling technology for [secondary scenarios], where it [contribution description]. Organizations implementing [related scenarios] will find this capability [benefit description] their overall implementation success and [operational outcomes].

## Project Planning Considerations

**Format:** Single paragraph (100-150 words)

**Content Guidelines:**

- **Prerequisites:** What other capabilities or infrastructure must be in place
- **Implementation Sequence:** When in the project lifecycle this capability should be deployed
- **Dependencies:** What this capability depends on and what depends on it
- **Planning Guidance:** Specific considerations for project planners

**Template Structure:**

When planning projects that require [Capability Name], teams should consider [prerequisite requirements] and plan for [implementation timing] within their project timeline. This capability has dependencies on [dependent capabilities] and serves as a foundation for [dependent scenarios/capabilities].

Project planners should allocate [resource considerations] and expect [timeline considerations] for full implementation. The [AI Planning Assistant][ai-planning-assistant] can provide additional guidance on integrating this capability into comprehensive project plans.

## Strategic Platform Benefits

**Format:** Single substantial paragraph (150-200 words)

**Content Guidelines:**

- Position capability as foundational enabler for broader platform scenarios
- Connect to strategic business objectives and digital transformation goals
- Emphasize how this capability reduces complexity while enabling advanced scenarios
- End with statement about organizational focus shift from infrastructure to business value
- Use forward-looking language about enabling future capabilities

**Template Structure:**

[Capability Name] serves as a [foundational/strategic/critical] capability that enables [advanced scenarios/use cases] by providing the [infrastructure characteristics] foundation required for [mission-critical applications/business scenarios]. This capability reduces the [operational complexity] of [domain challenges] while ensuring the [quality characteristics] necessary for [enterprise requirements].

This ultimately enables organizations to focus on [business value creation] rather than [operational overhead/technical complexity].

---

## Template Usage Guidelines

### Content Tone & Style

- **Technical Depth:** Write for enterprise architects, platform engineers, and technical decision makers
- **Business Focus:** Balance technical detail with clear business value articulation
- **Integration Emphasis:** Always position capabilities within broader platform ecosystem
- **Scale Orientation:** Emphasize enterprise-scale, production-ready characteristics
- **Outcome-Driven:** Focus on what capabilities enable rather than just what they do
- **Scenario-Aware:** Connect capabilities to real-world implementation scenarios

### Word Count Targets

Word count targets are just a suggestion. If you can achieve a concise article that covers the topic in fewer words that is preferable.

- **Abstract Description:** 200-300 words
- **Detailed Overview:** 150-250 words
- **Core Technical Components:** 800-1200 words total
- **Business Value & Impact:** 300-400 words
- **Implementation Architecture & Technology Stack:** 200-300 words
- **Scenario Integration:** 150-200 words
- **Project Planning Considerations:** 100-150 words
- **Strategic Platform Benefits:** 150-200 words
- **Total Document:** 1850-2500 words

### Quality Checklist

- [ ] Abstract description provides comprehensive value proposition
- [ ] Technical components are detailed and implementation-focused
- [ ] Business value includes quantifiable outcomes where possible
- [ ] Integration points with platform ecosystem are clear
- [ ] Enterprise-grade characteristics are emphasized
- [ ] Strategic positioning connects to broader digital transformation goals
- [ ] Scenario integration clearly identifies applicable use cases
- [ ] Project planning considerations provide actionable guidance
- [ ] Language is technically precise but accessible to business stakeholders
- [ ] Document flows logically from abstract to detailed to strategic
- [ ] All links to scenarios, planning guides, and external resources are valid

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[ai-planning-assistant]: /docs/project-planning/ai-planning-guide
[apache-kafka]: https://kafka.apache.org/
[azure-data-factory]: https://docs.microsoft.com/azure/data-factory/
[isa-95]: https://www.isa.org/standards-and-publications/isa-standards/isa-standards-committees/isa95
[opc-ua]: https://opcfoundation.org/
[scenarios-folder]: /docs/project-planning/scenarios/README
[service-names-like-azure-service-bus]: https://docs.microsoft.com/azure/service-bus/
[standards-like-opentelemetry]: https://opentelemetry.io/
[technology-names-like-kubernetes]: https://kubernetes.io/
