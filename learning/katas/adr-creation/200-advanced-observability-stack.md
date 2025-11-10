---
title: 'Kata: 200 - Advanced Observability Stack'
description: Learn complex ADR creation through multi-component evaluation, comparing TIG vs TICK stack for edge observability and monitoring...
author: Edge AI Team
ms.date: 2025-01-20
kata_id: adr-creation-200-advanced-observability-stack
kata_difficulty: 2
kata_category:
  - adr-creation
estimated_time_minutes: 50
learning_objectives:
  - Learn complex ADR creation through multi-component technology evaluation
  - Compare TIG vs TICK stack for comprehensive edge computing observability
  - Evaluate stakeholder requirements and implementation roadmaps
  - Apply advanced ADR methodology for enterprise observability decisions
prerequisite_katas:
  - adr-creation-100-basic-messaging-architecture
technologies:
  - Telegraf
  - InfluxDB
  - Grafana
  - Chronograf
  - Kapacitor
  - Azure Monitor
  - observability-stacks
  - time-series-databases
success_criteria:
  - Create comprehensive ADR for observability stack selection
  - Demonstrate multi-component technology evaluation
  - Document stakeholder requirements and implementation roadmap
  - Apply advanced ADR methodology for enterprise decisions
ai_coaching_level: adaptive
scaffolding_level: medium-heavy
hint_strategy: progressive
common_pitfalls:
  - 'Incomplete stack evaluation: Analyze all components comprehensively'
  - 'Missing stakeholder perspective: Include operational and business considerations'
  - 'Complex technology comparison becomes overwhelming: Focus on key differentiators and prioritize evaluation criteria'
  - 'Uncertain which observability metrics matter most: Prioritize metrics based on specific use case requirements'
  - 'Implementation roadmap unclear: Document decision with actionable deployment strategy'
requires_azure_subscription: false
requires_local_environment: true
tags:
  - adr-creation
search_keywords:
  - adr-creation-advanced
  - tig-stack-comparison
  - tick-stack-evaluation
  - observability-architecture
  - monitoring-stack-selection
  - enterprise-observability
  - time-series-databases
---

## Quick Context

**You'll Learn**: Create complex multi-component ADRs for sophisticated technology decisions involving multiple integrated systems and stakeholder requirements.

**Prerequisites**: Completion of Basic Messaging Architecture ADR kata, experience with observability concepts, understanding of monitoring stack components

**Real Challenge**: Your predictive maintenance system across 12 manufacturing facilities needs comprehensive observability. You must choose between TIG (Telegraf, InfluxDB, Grafana) vs TICK (Telegraf, InfluxDB, Chronograf, Kapacitor) stack to monitor 500+ edge nodes, 10,000+ sensors, and 100+ AI models with real-time analytics and automated alerting.

**Your Task**: Create an executive-level ADR that evaluates both observability stacks against technical, operational, and business criteria, documenting a clear recommendation with implementation roadmap.

**💡 Pro Tip**: Your AI coach can see your checkbox progress when you're using the local docs (`npm run docs`) and help you manage it! Navigate to the Learning section to access all learning resources.

## Essential Setup

Complete these prerequisite checks to ensure a successful learning experience:

**Required** (check these first):

- [ ] Completion of previous ADR kata (01-basic-messaging-architecture)
- [ ] Understanding of observability concepts (metrics, logs, traces)
- [ ] Access to solution ADR library templates and examples in /docs

**💡 Pro Tip**: Consider using specialized chatmodes for different phases of your work - one approach for systematic research, another for professional documentation. Separating these cognitive tasks can improve quality and efficiency.

**📁 Pro Tip**: Task Researcher automatically saves research documents to `.copilot-tracking/research/` - check there for your research files.

**Before starting the tasks**:

- [ ] Load the **Task Researcher** chatmode (`.github/chatmodes/task-researcher.chatmode.md`) for research phases
- [ ] Load the **ADR Creation Chatmode** (`.github/chatmodes/adr-creation.chatmode.md`) — specialized mode for transforming research into professional ADR documentation with template structure, stakeholder perspective analysis, and executive-level writing guidance

**Quick Validation**: Verify you have completed the Basic Messaging Architecture kata and can access observability component documentation.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 02 - Advanced Observability Stack kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Multi-Component Architecture Research (15 minutes)

**What You'll Do**: Research and analyze both observability stacks' architectures, components, and integration patterns.

**Steps**:

1. **Create research document** using Task Researcher chatmode
   - [ ] Switch to or confirm Task Researcher chatmode is active
   - [ ] Copy and paste this exact prompt:

   ```text
   Help me research TIG (Telegraf, InfluxDB, Grafana) and TICK (Telegraf, InfluxDB, Chronograf, Kapacitor) observability stacks for edge computing with 500+ nodes.

   Focus on:
   - Scalability (handling 1M+ data points/minute)
   - Resource efficiency (edge deployment constraints)
   - Real-time alerting capabilities
   - Component integration patterns

   Create a comparison table with architecture analysis.
   ```

   - [ ] **Expected result**: Initial research document saved to `.copilot-tracking/research/`

2. **Update research document** with architecture analysis
   - [ ] Continue working with Task Researcher chatmode
   - [ ] Request analysis of: TIG stack component relationships, data flow patterns, edge deployment patterns
   - [ ] Request analysis of: TICK stack complete platform integration, stream processing, alerting capabilities
   - [ ] Request analysis of: Performance characteristics at scale, resource footprint comparison
   - [ ] **Expected result**: Comprehensive understanding of both architectures with scalability focus

3. **Continue updating research document** with edge computing analysis
   - [ ] Still working with Task Researcher chatmode
   - [ ] Request analysis of: Data collection strategies, resource utilization patterns
   - [ ] Request analysis of: Storage optimization, query performance, distributed deployment considerations
   - [ ] **Success check**: Can articulate key architectural differences and trade-offs between stacks with specific evidence
   - [ ] **Reflection checkpoint**: Did you build a structured research document that captures technical comparisons and trade-offs?

### Task 2: Multi-Stakeholder Requirements Evaluation (15 minutes)

**What You'll Do**: Define evaluation criteria addressing technical, operational, and business stakeholder needs.

**Understanding Stakeholder Perspectives** (read this first):

Different stakeholders care about different aspects of the observability stack decision:

- **Technical teams** (DevOps, SRE): Performance, scalability, integration complexity, troubleshooting capabilities
- **Operations teams**: Deployment complexity, maintenance overhead, training requirements, support availability
- **Executive/Business**: Total cost of ownership, implementation timeline, business continuity risk, vendor lock-in
- **Security/Compliance**: Data retention, access control, audit capabilities, regulatory requirements

Your ADR must address ALL these perspectives, not just technical merits.

**Steps**:

1. **Identify** technical requirements for the scenario
   - [ ] Document performance requirements: 1M+ data points/minute across all sites, sub-second alerting, 2-year data retention
   - [ ] Document integration needs: Multi-tenant monitoring, enterprise integration, distributed operations
   - [ ] Copy and paste this prompt to Task Researcher:

   ```text
   What are the technical requirements for an observability stack supporting 500+ edge nodes with real-time monitoring and 1M+ data points per minute?
   ```

   - [ ] **Expected result**: Comprehensive technical requirements matrix

2. **Define** operational requirements and constraints
   - [ ] Identify operational factors: Deployment complexity across edge locations, maintenance overhead
   - [ ] Consider team factors: Configuration management, troubleshooting capabilities, team training needs
   - [ ] Copy and paste this prompt:

   ```text
   What are the operational considerations for deploying and maintaining an observability stack across 12 distributed manufacturing facilities?
   ```

   - [ ] **Expected result**: Clear operational complexity assessment criteria

3. **Establish** business evaluation criteria
   - [ ] Consider financial factors: Total cost of ownership, compliance requirements
   - [ ] Consider strategic factors: Risk factors, implementation timeline, scalability considerations
   - [ ] Copy and paste this prompt:

   ```text
   What business and financial criteria should guide the selection of an observability stack for enterprise manufacturing operations?
   ```

   - [ ] **Success check**: Multi-dimensional evaluation framework ready for analysis addressing technical, operational, and business perspectives

### Task 3: Executive-Level ADR Creation (20 minutes)

**What You'll Do**: Create a comprehensive ADR with detailed analysis, clear recommendation, and implementation roadmap.

**Understanding "Executive-Level" ADR**:

An executive-level ADR is more than just a technical comparison - it must:

- **Lead with business impact**: Start with why this decision matters to the organization
- **Use clear, jargon-free language**: Explain technical concepts in business terms
- **Quantify where possible**: Include specific metrics (cost, time, resource requirements)
- **Address risk**: Explicitly call out implementation risks and mitigation strategies
- **Provide clear recommendation**: No ambiguity - make a definitive choice with strong justification
- **Include actionable roadmap**: Executives want to know "what happens next" with specific timelines

**Before starting documentation**:

- [ ] **Switch to ADR Creation chatmode** (see Essential Setup above)
- [ ] Find your research document in `.copilot-tracking/research/` and add it to the chat context (attach file)
- [ ] Copy and paste this exact prompt:

```text
I have completed research comparing TIG (Telegraf, InfluxDB, Grafana) and TICK (Telegraf, InfluxDB, Chronograf, Kapacitor) observability stacks.

Help me create an executive-level ADR for selecting an observability stack for edge computing infrastructure with:
- 500+ distributed edge nodes across 12 manufacturing facilities
- 1M+ data points/minute real-time monitoring
- Multi-stakeholder requirements (technical, operational, business)

Structure the ADR to address all stakeholder perspectives with clear business impact and implementation roadmap.
```

**Steps**:

1. **Create** structured technology comparison using your research analysis
   - [ ] Work with ADR Creation chatmode to structure the document
   - [ ] Context section using scenario from Quick Context (500+ nodes, edge constraints, 1M+ data points/minute)
   - [ ] Apply evaluation criteria to both stacks with specific evidence from your research
   - [ ] Include quantified analysis where possible (performance, cost, complexity)
   - [ ] Document integration considerations with existing enterprise systems (e.g. identity and PKI)
   - [ ] **Expected result**: Detailed comparative analysis supporting decision-making

2. **Review** your comparative analysis using Ask mode for differential perspectives
   - [ ] **Switch to Ask mode** in GitHub Copilot Chat
   - [ ] **Attach your draft ADR** to the chat context
   - [ ] **Ask for technical review**: "Review this observability stack comparison for technical gaps, missing considerations, and alternative perspectives. What edge computing challenges might I have overlooked? Are there scalability concerns I should address?"
   - [ ] **Ask for stakeholder analysis**: "What concerns might different stakeholders (operations team, security team, finance) raise about this analysis? What questions should I anticipate?"
   - [ ] **Refine your analysis** based on the feedback and identified gaps
   - [ ] **Expected result**: Strengthened analysis with addressed gaps and consideration of multiple perspectives

3. **Document** clear recommendation with multi-stakeholder justification
   - [ ] Present selected stack with rationale addressing technical, operational, and business concerns
   - [ ] Include risk assessment and mitigation strategies
   - [ ] Address implementation complexity and timeline considerations
   - [ ] **Expected result**: Executive-level recommendation with comprehensive justification

4. **Include** implementation roadmap and success metrics
   - [ ] Phase-based deployment strategy minimizing operational risk
   - [ ] Integration approach with existing monitoring systems
   - [ ] Training plan and knowledge transfer requirements
   - [ ] **Success criteria**: Complete ADR ready for stakeholder review and implementation approval

## Completion Check

**You've Succeeded When**:

- [ ] Created comprehensive ADR comparing TIG vs TICK stacks with detailed analysis
- [ ] Used Task Researcher chatmode to create structured research before ADR creation
- [ ] Used Ask mode to review and strengthen analysis with differential perspectives
- [ ] Separated research phase from documentation phase for better quality outcomes
- [ ] Addressed technical, operational, and business stakeholder requirements
- [ ] Documented clear recommendation with implementation roadmap
- [ ] ADR meets executive-level quality standards for complex technology decisions

**Ready for more?** Try creating an ADR for a related technology decision (e.g., commercial vs open-source monitoring, hybrid cloud/edge observability) using this same process.

---

## Reference Appendix

### Help Resources

**Core Learning Tools**:

- [Task Researcher Chatmode][task-researcher] - `.github/chatmodes/task-researcher.chatmode.md` for structured research
- [ADR Creation Chatmode][adr-create] - See Essential Setup section for full path and description
- [ADR Solution Library][adr-library] - `docs/solution-adr-library/` for templates and examples

**Azure Observability Documentation**:

- [Azure Monitor][ms-azure-monitor] - Comprehensive monitoring and observability platform guidance
- [Application Insights][ms-application-insights] - Application performance monitoring integration
- [Previous ADR](01-basic-messaging-architecture.md) - Reference methodology and format for consistency

### Professional Tips

- Break down complex multi-component stack evaluations into focused research phases (architecture, requirements, comparison) before synthesizing into ADR
- Use multiple AI chatmodes strategically: Task Researcher for gathering evidence, Ask mode for challenging your assumptions, ADR Creation for professional documentation
- Address multi-stakeholder perspectives early - technical, operational, and business criteria often conflict and require explicit trade-off analysis
- Include quantified metrics wherever possible (performance numbers, cost estimates, resource requirements) to strengthen technical arguments

### Troubleshooting

**Issue**: Complex technology comparison becomes overwhelming with too many factors

- **Quick Fix**: Focus on key differentiators and prioritize evaluation criteria based on specific use case requirements. Use comparison tables to structure analysis.

**Issue**: Uncertain which observability metrics matter most for edge scenarios

- **Quick Fix**: Prioritize metrics based on business impact (uptime, performance, cost). Start with must-have requirements before nice-to-have features.

**Issue**: Implementation roadmap unclear or too vague for stakeholder approval

- **Quick Fix**: Document phased deployment with specific milestones, integration points, and success criteria. Include risk mitigation strategies.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[task-researcher]: /.github/chatmodes/task-researcher.chatmode.md
[adr-create]: /.github/chatmodes/adr-creation.chatmode.md
[adr-library]: /docs/solution-adr-library/
[ms-azure-monitor]: https://docs.microsoft.com/en-us/azure/azure-monitor/
[ms-application-insights]: https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview
