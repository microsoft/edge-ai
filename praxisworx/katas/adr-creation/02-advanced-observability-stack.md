---
title: 02 - Advanced Observability Stack
description: Master complex ADR creation through multi-component technology evaluation, comparing TIG vs TICK stack for comprehensive edge computing observability and monitoring
author: Edge AI Team
ms.date: 2025-06-17
ms.topic: kata
estimated_reading_time: 8
difficulty: intermediate
duration: 45-60 minutes
keywords:
  - praxisworx
  - adr creation
  - architectural decision records
  - observability
  - monitoring
  - tig stack
  - tick stack
  - edge computing
  - industrial automation
  - numbered progression
---

## Quick Context

**You'll Learn**: Create complex multi-component ADRs for sophisticated technology decisions involving multiple integrated systems and stakeholder requirements.

**Real Challenge**: Your predictive maintenance system across 12 manufacturing facilities needs comprehensive observability. You must choose between TIG (Telegraf, InfluxDB, Grafana) vs TICK (Telegraf, InfluxDB, Chronograf, Kapacitor) stack to monitor 500+ edge nodes, 10,000+ sensors, and 100+ AI models with real-time analytics and automated alerting.

**Your Task**: Create an executive-level ADR that evaluates both observability stacks against technical, operational, and business criteria, documenting a clear recommendation with implementation roadmap.

## 🤖 AI Coaching Available - Get Interactive Help

> **🚀 Supercharge Your Learning with AI Coaching**
>
> **New to AI-assisted learning? Want task check-offs, progress tracking, and personalized guidance?**
>
> Load our specialized **PraxisWorx Kata Coach** for:
>
> - ✅ **Task Check-offs**: Mark completed tasks and track your progress
> - 🎯 **Learning Evaluation**: Reflect on your progress with guided questions
> - 🆘 **Coaching & Troubleshooting**: Get progressive hints when you're stuck
> - 🔄 **Session Resumption**: Pick up exactly where you left off
> - 🧭 **Smart Guidance**: Personalized coaching based on your progress patterns

### How to Load Your AI Coach

**Step 1**: In GitHub Copilot Chat, select the **PraxisWorx Kata Coach** mode from the chat mode selector.

**Step 2**: Send this starter message to begin your coached session:

```text
I'm working on Advanced Observability Stack kata and want interactive coaching with progress tracking and learning evaluation.
```

**💡 Pro Tip**: Your coach can see your checkbox progress when you're using the local docs (`npm run docs:training`) and help you manage it!

### Essential Setup

**Required** (check these first):

- [ ] Completion of previous ADR kata (01-basic-messaging-architecture)
- [ ] Understanding of observability concepts (metrics, logs, traces)
- [ ] Access to solution ADR library templates and examples in /docs

**Quick Validation**: Can explain the difference between TIG and TICK stacks and their use cases.

## Practice Tasks

### Task 1: Multi-Component Architecture Research (15 minutes)

**What You'll Do**: Research and analyze both observability stacks' architectures, components, and integration patterns.

**Steps**:

1. **Research** TIG stack (Telegraf, InfluxDB, Grafana) architecture
   - [ ] Use GitHub Copilot to understand component responsibilities and data flow
   - [ ] Focus on: edge deployment patterns, resource requirements, integration complexity
   - **Expected result**: Clear understanding of TIG stack architecture and edge optimization capabilities

2. **Research** TICK stack (Telegraf, InfluxDB, Chronograf, Kapacitor) architecture
   - [ ] Use Copilot to understand complete platform integration and stream processing
   - [ ] Focus on: unified platform benefits, advanced analytics, operational overhead
   - **Expected result**: Clear understanding of TICK stack advantages and platform cohesion

3. **Analyze** architectural implications for edge environments
   - [ ] Compare data collection strategies and resource utilization patterns
   - [ ] Consider storage optimization, query performance, and potentially distributed deployment
   - **Success check**: Can articulate key architectural differences and trade-offs between stacks

### Task 2: Multi-Stakeholder Requirements Evaluation (15 minutes)

**What You'll Do**: Define evaluation criteria addressing technical, operational, and business stakeholder needs.

**Steps**:

1. **Identify** technical requirements for the scenario
   - [ ] 1M+ data points/minute across all sites, sub-second alerting, 2-year data retention
   - [ ] Multi-tenant monitoring, enterprise integration, distributed operations
   - **Expected result**: Comprehensive technical requirements matrix

2. **Define** operational requirements and constraints
   - [ ] Deployment complexity across edge locations, maintenance overhead
   - [ ] Configuration management, troubleshooting capabilities, team training needs
   - **Expected result**: Clear operational complexity assessment criteria

3. **Establish** business evaluation criteria
   - [ ] Total cost of ownership, compliance requirements
   - [ ] Risk factors, implementation timeline, scalability considerations
   - **Success check**: Multi-dimensional evaluation framework ready for analysis

### Task 3: Executive-Level ADR Creation (20 minutes)

**What You'll Do**: Create a comprehensive ADR with detailed analysis, clear recommendation, and implementation roadmap.

**Steps**:

1. **Create** structured technology comparison
   - [ ] Apply evaluation criteria to both stacks with specific evidence
   - [ ] Include quantified analysis where possible (performance, cost, complexity)
   - [ ] Document integration considerations with existing enterprise systems (e.g. identity and PKI)
   - **Expected result**: Detailed comparative analysis supporting decision-making

2. **Document** clear recommendation with multi-stakeholder justification
   - [ ] Present selected stack with rationale addressing technical, operational, and business concerns
   - [ ] Include risk assessment and mitigation strategies
   - [ ] Address implementation complexity and timeline considerations
   - **Expected result**: Executive-level recommendation with comprehensive justification

3. **Include** implementation roadmap and success metrics
   - [ ] Phase-based deployment strategy minimizing operational risk
   - [ ] Integration approach with existing monitoring systems
   - [ ] Training plan and knowledge transfer requirements
   - **Success criteria**: Complete ADR ready for stakeholder review and implementation approval

## Completion Check

**You've Succeeded When**:

- [ ] Created comprehensive ADR comparing TIG vs TICK stacks with detailed analysis
- [ ] Addressed technical, operational, and business stakeholder requirements
- [ ] Documented clear recommendation with implementation roadmap
- [ ] ADR meets executive-level quality standards for complex technology decisions

## Next Steps

**Continue Learning**: Practice with `03-service-mesh-selection.md` for microservices infrastructure ADR decisions

**Apply Skills**: Use this advanced ADR methodology for complex technology stack decisions in enterprise environments

## Resources

- [Azure Monitor][ms-azure-monitor] - Comprehensive monitoring and observability platform guidance
- [Application Insights][ms-application-insights] - Application performance monitoring integration
- [Previous ADR](01-basic-messaging-architecture.md) - Reference methodology and format for consistency

---

<!-- Reference Links -->
[ms-azure-monitor]: https://docs.microsoft.com/en-us/azure/azure-monitor/
[ms-application-insights]: https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
