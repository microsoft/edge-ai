# Capability Mapping Content Guidelines

This document provides comprehensive guidelines for creating capability mapping documentation that aligns with the established patterns in existing scenario files.

## Document Structure Requirements

### Required Sections (in order)

1. **YAML Frontmatter** - Document metadata and keywords
2. **Capability Mapping Overview** - Introduction and evaluation framework
3. **Implementation Phase Analysis** - Detailed phase-by-phase breakdown
4. **Business Outcomes and ROI** - OKRs and ROI projections
5. **Detailed Capability Evaluation** - Technical scoring justifications

## Section 1: YAML Frontmatter Standards

```yaml
---
title: [Scenario Name] - Capability Mapping & Analysis
description: 'Comprehensive capability analysis and implementation planning for [scenario description]'
author: Edge AI Team
ms.date: MM/DD/YYYY
ms.topic: hub-page
estimated_reading_time: 8
keywords:
  - [scenario-specific-keyword]
  - capability-mapping
  - implementation-planning
  - edge-ai
  - overview
  - index
  - navigation
  - workspaces
  - edge
  - project
  - planning
  - scenarios
---
```

## Section 2: Capability Mapping Overview

### Required Content Elements

**Opening paragraph structure:**

- Document purpose statement
- Reference to four-dimensional evaluation framework
- Strategic focus description (2-3 sentences)

**Evaluation Framework definition:**

```markdown
**Evaluation Framework:** Each capability is evaluated across four dimensions using a 0-10 scale:

- **Technical Fit (TF):** How well the capability matches scenario requirements
- **Business Value (BV):** Business impact and value creation potential
- **Implementation Practicality (IP):** Ease of implementation and resource requirements
- **Platform Cohesion (PC):** Integration benefits and cross-capability synergies
```

**Implementation Phases definition:**

```markdown
**Implementation Phases:** Capabilities are organized into four implementation phases:

- **PoC Phase (2-4 weeks):** Foundation capabilities for proof of concept
- **PoV Phase (6-12 weeks):** Value demonstration and business validation
- **Production Phase (3-6 months):** Operational deployment and integration
- **Scale Phase (6-18 months):** Enterprise transformation and optimization
```

## Section 3: Implementation Phase Analysis

### Phase Structure Requirements

Each phase must include:

1. **Objective statement** - Clear phase goals
2. **Capability Selection Criteria** - 3-4 bullet points explaining selection rationale
3. **Key Capabilities** - Numbered list with scoring and detailed descriptions

### Capability Description Format

```markdown
1. **[Capability Name]** (TF: X, BV: X, IP: X, PC: X)
   - **Role:** [Specific role in the scenario implementation]
   - **Implementation Focus:** [Key technical implementation considerations]
   - **Success Criteria:** [Measurable success metrics with specific targets]
```

### Phase Timeline Standards

- **PoC Phase:** 2-4 weeks duration
- **PoV Phase:** 6-12 weeks duration
- **Production Phase:** 3-6 months duration
- **Scale Phase:** 6-18 months duration

## Section 4: Business Outcomes and ROI

### OKR Structure Requirements

#### Primary Business Outcomes Format

```markdown
### Primary Business Outcomes (OKRs)

#### Objective 1: [Primary Business Objective Title]

- **Key Result 1:** [Metric description] - Target: _____% [improvement type] (Current baseline: _____)
- **Key Result 2:** [Related metric] - Target: _____% [improvement type] (Current baseline: _____)
- **Key Result 3:** [Supporting metric] - Target: _____ [units] (Current baseline: _____ [units])
- **Key Result 4:** [Additional metric] - Target: $_____[unit type] (Current baseline: $_____)
```

#### Required Elements

- **3-4 Objectives** with hierarchical importance (primary to advanced/optional)
- **3-4 Key Results** per objective with fill-in-the-blank format
- **Example ranges for reference** section with industry benchmarks
- **Baseline placeholders** for all metrics

#### Impact Level Consistency Rules

- **Optional Objectives**: Key Results should use 🔵 Strategic or 🟢 Medium impact levels only
- **Primary Objectives**: Key Results can use any impact level (🔴 Critical, 🟡 High, 🟢 Medium, 🔵 Strategic)
- **Critical Impact (🔴)**: Reserved for essential business outcomes in primary objectives only

#### Example Ranges Section

```markdown
**Example ranges for reference:**

- [Metric type]: XX-XX% typically achieved with [technology approach]
- [Metric type]: XX-XX% commonly observed in [implementation context]
- [Additional ranges with contextual information]
```

### ROI Projections Structure

#### Required Framework for Each Phase

```markdown
#### [Phase Name]: X-X months

**Investment Planning Framework:**

- **Typical Investment Range:** $XX,000 - $XX,000 (customize based on [specific factors])
- **ROI Calculation Approach:** [Primary value calculation method]
- **Key Value Drivers:** [3-4 primary value sources]
- **Measurement Framework:** [Specific success metrics]

**Your Investment:** $_______ (fill in your planned investment)
**Your Expected ROI:** _____% within _____ months
**Your Key Value Drivers:** ________________
```

## Section 5: Detailed Capability Evaluation

### Scoring Justification Format

```markdown
#### [Capability Name] (TF: X, BV: X, IP: X, PC: X)

**Technical Fit Rationale (X/10):** [Detailed explanation including technical alignment factors and implementation requirements]

**Business Value Rationale (X/10):** [Detailed explanation including specific business impact mechanisms and value creation]

**Implementation Practicality Rationale (X/10):** [Detailed explanation including complexity factors, resource requirements, and potential barriers]

**Platform Cohesion Rationale (X/10):** [Detailed explanation including integration benefits and cross-capability synergies]
```

## Content Quality Standards

### Business Value Guidelines

**Use resource intensity metrics instead of monetary values:**

- ✅ "40% reduction in manual inspection time"
- ✅ "50% faster defect detection"
- ✅ "99.5% detection accuracy"
- ❌ "$100K cost savings annually"
- ❌ "25% revenue increase"

**Focus on operational efficiency measurements:**

- Processing speed improvements
- Quality metric improvements
- Risk reduction percentages
- Throughput optimization
- Resource utilization gains

### Link Validation Requirements

**Critical Link Standards:**

- **DO NOT create links to non-existent capabilities**
- **Remove placeholder links** rather than linking to missing content
- **Validate all internal links** point to existing workspace files
- **Use relative paths** for documentation links
- **Test all links** before publishing

### Scoring Consistency

**Technical Fit (TF) Guidelines:**

- 9-10: Perfect alignment with scenario requirements
- 7-8: Strong alignment with minor gaps
- 5-6: Moderate alignment with some adaptation needed
- 3-4: Limited alignment requiring significant customization
- 1-2: Poor alignment with major implementation challenges

**Business Value (BV) Guidelines:**

- 9-10: Direct, high-impact business value
- 7-8: Strong business value with clear ROI
- 5-6: Moderate business value with measurable benefits
- 3-4: Limited business value requiring justification
- 1-2: Minimal business value or unclear benefits

**Implementation Practicality (IP) Guidelines:**

- 9-10: Straightforward implementation with existing tools
- 7-8: Manageable implementation with standard complexity
- 5-6: Moderate implementation requiring specialized skills
- 3-4: Complex implementation with significant barriers
- 1-2: Very difficult implementation with major obstacles

**Platform Cohesion (PC) Guidelines:**

- 9-10: Strong integration with multiple platform capabilities
- 7-8: Good integration with related capabilities
- 5-6: Moderate integration with some synergies
- 3-4: Limited integration with few synergies
- 1-2: Minimal integration with platform capabilities

## Validation Checklist

### Content Structure Validation

- [ ] YAML frontmatter includes all required fields
- [ ] Capability Mapping Overview includes evaluation framework definition
- [ ] Implementation Phase Analysis includes all four phases with proper structure
- [ ] Business Outcomes section includes comprehensive OKRs with fill-in-blanks
- [ ] ROI Projections included for all phases with investment planning frameworks
- [ ] Detailed Capability Evaluation includes scoring rationale for key capabilities

### Content Quality Validation

- [ ] All capability scores include four dimensions (TF, BV, IP, PC)
- [ ] Business value metrics avoid monetary values
- [ ] Phase timelines match standard durations
- [ ] OKRs include example ranges for reference
- [ ] All links validated and point to existing content
- [ ] Scoring justifications are detailed and specific
- [ ] Strategic focus aligns with scenario requirements

### Consistency Validation

- [ ] Terminology consistent with other scenario documents
- [ ] Capability names match established conventions
- [ ] Phase structure consistent across all sections
- [ ] Scoring methodology applied consistently
- [ ] Business outcome categories align with scenario focus

## Reference Implementation Examples

### Model Documents for Structure Reference

1. **Digital Inspection & Survey** (`/docs/project-planning/scenarios/digital-inspection-survey/capability-mapping.md`)
   - Excellent OKR structure with fill-in-the-blank format
   - Comprehensive ROI projections across all phases
   - Detailed capability evaluation with technical justifications

2. **Predictive Maintenance** (`/docs/project-planning/scenarios/predictive-maintenance/capability-mapping.md`)
   - Strong phase-based capability organization
   - Good example ranges for reference section
   - Clear investment planning frameworks

3. **Packaging Line Performance Optimization** (`/docs/project-planning/scenarios/packaging-line-performance-optimization/capability-mapping.md`)
   - Comprehensive implementation phase analysis
   - Detailed capability scoring with technical focus
   - Strong business outcome alignment

### Content Patterns to Follow

- **Capability scoring patterns** from digital inspection scenario
- **OKR structure and fill-in-the-blank format** from all reference scenarios
- **ROI projection frameworks** across all phases
- **Technical implementation details** in capability descriptions
- **Business value quantification** without monetary values

---

**Note**: These guidelines ensure capability mapping documents are consistent, comprehensive, and aligned with established patterns while maintaining scenario-specific relevance and technical accuracy.

## Core Capability Overview Requirements

### Table Structure Standards

**Required Table Format:**

```markdown
| Capability Group | Critical Capabilities | Implementation Requirements | Status |
| --- | --- | --- | --- |
```

**Column Requirements:**

- **Capability Group**: Bold text with capability group link
- **Critical Capabilities**: List individual capabilities with links, use `<br>` for multiple capabilities
- **Implementation Requirements**: Specific technical requirements (not generic descriptions)
- **Status**: Use standardized status indicators with consistent formatting

### Capability Group Standards

**Core Groups (REQUIRED in all scenarios):**

1. **[Protocol Translation & Device Management][protocol-translation-device-management]**
2. **[Edge Cluster Platform][edge-cluster-platform]**
3. **[Edge Industrial Application Platform][edge-industrial-application-platform]**
4. **[Cloud Data Platform][cloud-data-platform]**
5. **[Cloud AI Platform][cloud-ai-platform]**

**Additional Groups (scenario-specific):**

- **[Cloud Insights Platform][cloud-insights-platform]** - For quality and monitoring scenarios
- **[Advanced Simulation & Digital Twin Platform][advanced-simulation-digital-twin-platform]** - For advanced modeling scenarios
- **[Physical Infrastructure][physical-infrastructure]** - For bare-metal infrastructure requirements
- **[Business Enablement Integration Platform][business-enablement-integration-platform]** - For enterprise integration scenarios

### Individual Capability Standards

**Common Core Capabilities:**

- [OPC UA Data Ingestion][opc-ua-data-ingestion] - Industrial data collection
- [Edge Data Stream Processing][edge-data-stream-processing] - Real-time data processing
- [Edge Dashboard Visualization][edge-dashboard-visualization] - Operational dashboards
- [Edge Compute Orchestration][edge-compute-orchestration] - Container orchestration
- [Cloud Data Platform Services][cloud-data-platform-services] - Cloud data management
- [Device Twin Management][device-twin-management] - Digital twin capabilities

**Scenario-Specific Capabilities:**

- [Edge Camera Control][edge-camera-control] - Vision-based scenarios
- [Computer Vision Platform][computer-vision-platform] - Image analysis scenarios
- [Edge Inferencing Application Framework][edge-inferencing-application-framework] - AI/ML scenarios

## Implementation Roadmap Requirements

### Phase Structure Standards

**Required Phases (exact names and durations):**

1. **🧪 PoC Phase (3 weeks)** - Initial proof of concept
2. **🚀 PoV Phase (10 weeks)** - Production validation
3. **🏭 Production Phase (6 months)** - Full production deployment
4. **📈 Scale Phase (15 months)** - Enterprise-wide scaling

### Phase Table Format

**Required Table Structure:**

```markdown
| Capability | Technical Focus | Business Impact |
| --- | --- | --- |
```

**Column Standards:**

- **Capability**: Link to specific capability with descriptive text
- **Technical Focus**: Specific technical implementation details
- **Business Impact**: Quantified business outcomes (no monetary values)

### Phase Content Guidelines

**PoC Phase (3 weeks):**

- Focus on core functionality validation
- Include 2-3 foundational capabilities
- Emphasize technical feasibility and integration testing
- Business impact: proof of technical viability

**PoV Phase (10 weeks):**

- Expand capability scope for production readiness
- Include 3-4 capabilities building on PoC
- Focus on performance and scalability validation
- Business impact: operational efficiency metrics

**Production Phase (6 months):**

- Full production deployment capabilities
- Include 4-5 capabilities for complete solution
- Focus on monitoring, security, and operational procedures
- Business impact: measured operational outcomes

**Scale Phase (15 months):**

- Enterprise-wide deployment capabilities
- Include 3-4 capabilities for multi-site operations
- Focus on automation and optimization
- Business impact: enterprise transformation metrics

## Advanced Capability Extensions Requirements

### Advanced Extensions Table Format

**Required Table Format:**

```markdown
| Capability | Technical Complexity | Business Value | Implementation Effort | Integration Points |
| --- | --- | --- | --- | --- |
```

**Column Requirements:**

- **Capability**: Capability name with link
- **Technical Complexity**: High/Medium/Low with specific factors
- **Business Value**: Quantified benefits (avoid monetary values)
- **Implementation Effort**: Realistic time and resource estimates
- **Integration Points**: Specific system integration requirements

### Complexity Assessment Standards

**Technical Complexity Levels:**

- **High**: Requires specialized expertise, custom development, complex integration
- **Medium**: Requires configuration and moderate customization
- **Low**: Uses existing capabilities with minimal configuration

**Assessment Factors:**

- Development requirements
- Integration complexity
- Specialized skills needed
- Dependencies on external systems
- Performance requirements

## Link Management Standards

### Capability Group Links

**Format**: `[Group Name][group-link-id]`

**Link Definitions** (at end of file):

```markdown
[protocol-translation-device-management]: /docs/project-planning/capabilities/protocol-translation-device-management/
[edge-cluster-platform]: /docs/project-planning/capabilities/edge-cluster-platform/
[edge-industrial-application-platform]: /docs/project-planning/capabilities/edge-industrial-application-platform/
[cloud-data-platform]: /docs/project-planning/capabilities/cloud-data-platform/
[cloud-ai-platform]: /docs/project-planning/capabilities/cloud-ai-platform/
```

### Individual Capability Links

**Format**: `[Capability Name][capability-link-id]`

**Link Validation Requirements:**

- All capability links MUST point to existing documentation
- Use consistent link naming conventions (lowercase, hyphen-separated)
- Remove any links to non-existent capabilities
- Validate all links before publishing

### Link Testing Procedure

Before publishing capability mapping:

1. Verify all capability group links point to existing directories
2. Verify all individual capability links point to existing files
3. Test all links in a web browser or documentation preview
4. Remove any broken or placeholder links

## Business Value Expression Standards

### Prohibited Language - STRICT POLICY

**NEVER use monetary values, cost estimates, or financial projections:**

- Dollar amounts (e.g., "$50,000 savings", "$1M investment")
- Revenue projections (e.g., "increase revenue by 20%")
- Cost savings (e.g., "reduce costs by $100,000")
- Return on investment calculations in dollars
- Investment ranges with dollar amounts
- Budget requirements or estimates
- Financial ROI percentages with monetary context

**Always use resource intensity and performance metrics instead:**

- Resource intensity classifications (Low/Medium/High/Very High resource intensity)
- Operational efficiency (e.g., "50% faster defect detection")
- Quality improvements (e.g., "99.5% detection accuracy")
- Risk reduction (e.g., "80% reduction in safety incidents")
- Process optimization (e.g., "30% improvement in throughput")
- Performance multipliers (e.g., "2.5x faster processing", "3x return within 12 months")

### Investment and ROI Section Standards

**For "Typical Investment Range" sections:**

- Use: "Low to medium resource intensity (customize based on scope)"
- Use: "High resource intensity (enterprise-grade deployment)"
- Do NOT use: "$XX,000 - $XX,000" or any dollar amounts

**For "Your Investment" sections:**

- Use: "Low to medium resource intensity (fill in your planned resource allocation)"
- Use: "High resource intensity (fill in your planned Scale resource allocation)"
- Do NOT use: "$_______ (fill in your planned investment)"

**For ROI projections:**

- Use: "2.5x return within 12 months" or "180% within 9 months"
- Focus on efficiency gains, quality improvements, and performance multipliers
- Do NOT include any dollar-based ROI calculations

### Business Value Categories

**Operational Efficiency:**

- Time reduction metrics
- Process automation percentages
- Manual effort reduction
- Throughput improvements

**Quality Improvements:**

- Accuracy percentages
- Defect detection rates
- Process consistency metrics
- Compliance improvements

**Risk Mitigation:**

- Safety incident reduction
- Downtime prevention metrics
- Security improvement measures
- Compliance risk reduction

## Status Classification Standards

### Status Indicators

**Use exactly these indicators:**

- **✅ Ready to Deploy** - Capability is implemented and tested
- **🔵 Development Required** - Capability is under active development
- **🟣 Planned** - Capability is planned for future development
- **🟪 External Dependencies** - Capability requires third-party integration

### Status Assignment Guidelines

**✅ Ready to Deploy:**

- Capability is fully implemented
- Testing is complete
- Documentation is available
- Deployment procedures are defined

**🔵 Development Required:**

- Capability design is complete
- Development is in progress
- Timeline is defined
- Resources are allocated

**🟣 Planned:**

- Capability is in planning phase
- Requirements are defined
- Timeline is tentative
- Resources are identified

**🟪 External Dependencies:**

- Capability requires third-party components
- External integration is needed
- Vendor relationships are required
- External timelines impact delivery

## Quality Assurance Standards

### Pre-Publication Checklist

**Structure Validation:**

- [ ] All required sections are present
- [ ] Section headers match template exactly
- [ ] Table structures follow standards
- [ ] Phase durations are correct

**Content Validation:**

- [ ] All capability groups use standard names
- [ ] All capabilities are linked correctly
- [ ] Status indicators are standardized
- [ ] Business value avoids monetary terms

**Link Validation:**

- [ ] All capability group links are tested
- [ ] All individual capability links are tested
- [ ] No placeholder or broken links exist
- [ ] Link definitions are complete

**Business Value Validation:**

- [ ] No monetary values are used
- [ ] Metrics are specific and measurable
- [ ] Benefits are realistic and achievable
- [ ] Business outcomes are clearly defined

### Cross-Scenario Consistency

**Verification Requirements:**

- Capability group usage is consistent across scenarios
- Status indicators mean the same thing across scenarios
- Phase structures are identical across scenarios
- Link naming conventions are consistent

**Documentation Standards:**

- Use reference-style links consistently
- Maintain consistent formatting and style
- Follow markdown linting requirements
- Include proper YAML frontmatter

## Validation and Testing

### Automated Link Testing Procedure

1. **Automated Link Testing**: Use markdown link validation tools
2. **Manual Link Testing**: Click all links in documentation preview
3. **Capability Verification**: Verify all referenced capabilities exist
4. **Cross-Reference Testing**: Verify capability mappings are accurate

### Content Review Process

1. **Technical Review**: Verify technical accuracy of capability descriptions
2. **Business Review**: Verify business value statements are appropriate
3. **Consistency Review**: Verify consistency with other scenario documentation
4. **Quality Review**: Verify adherence to documentation standards

---

**Note**: These guidelines must be followed consistently across all scenario README files to ensure standardized capability mapping documentation that supports effective decision-making and implementation planning.

<!-- Reference Links -->
[protocol-translation-device-management]: /docs/project-planning/capabilities/protocol-translation-device-management/
[edge-cluster-platform]: /docs/project-planning/capabilities/edge-cluster-platform/
[edge-industrial-application-platform]: /docs/project-planning/capabilities/edge-industrial-application-platform/
[cloud-data-platform]: /docs/project-planning/capabilities/cloud-data-platform/
[cloud-ai-platform]: /docs/project-planning/capabilities/cloud-ai-platform/
[cloud-insights-platform]: /docs/project-planning/capabilities/cloud-insights-platform/
[advanced-simulation-digital-twin-platform]: /docs/project-planning/capabilities/advanced-simulation-digital-twin-platform/
[physical-infrastructure]: /docs/project-planning/capabilities/physical-infrastructure/
[business-enablement-integration-platform]: /docs/project-planning/capabilities/business-enablement-integration-platform/
[opc-ua-data-ingestion]: /docs/project-planning/capabilities/protocol-translation-device-management/opc-ua-data-ingestion.md
[edge-data-stream-processing]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-data-stream-processing.md
[edge-dashboard-visualization]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-dashboard-visualization.md
[edge-compute-orchestration]: /docs/project-planning/capabilities/edge-cluster-platform/edge-compute-orchestration.md
[cloud-data-platform-services]: /docs/project-planning/capabilities/cloud-data-platform/cloud-data-platform-services.md
[device-twin-management]: /docs/project-planning/capabilities/protocol-translation-device-management/device-twin-management.md
[edge-camera-control]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-camera-control.md
[computer-vision-platform]: /docs/project-planning/capabilities/edge-industrial-application-platform/computer-vision-platform.md
[edge-inferencing-application-framework]: /docs/project-planning/capabilities/edge-industrial-application-platform/edge-inferencing-application-framework.md
