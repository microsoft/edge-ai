---
title: 'Kata: 100 - Basic Messaging Architecture'
description: Learn foundational ADR creation through systematic evaluation and documentation of messaging technology decisions for distributed systems
author: Edge AI Team
ms.date: 2025-01-20
kata_id: adr-creation-100-basic-messaging-architecture
kata_category:
  - adr-creation
kata_difficulty: 1
estimated_time_minutes: 60
learning_objectives:
  - Learn foundational ADR creation through structured evaluation
  - Document messaging technology decisions systematically
  - Compare MQTT and Apache Kafka for edge computing scenarios
prerequisite_katas: []
technologies:
  - Architecture Decision Records
  - MQTT
  - Apache Kafka
  - GitHub Copilot
success_criteria:
  - Create professional ADR comparing MQTT vs Apache Kafka
  - Document architecture decision with structured evaluation methodology
  - Justify technology choice with clear reasoning
ai_coaching_level: guided
scaffolding_level: heavy
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - adr-creation
search_keywords:
  - architectural-decision-records
  - adr-template
  - messaging-architecture
  - mqtt-vs-kafka
  - technology-selection
---

## Quick Context

Your industrial IoT system needs to choose between MQTT and Apache Kafka for streaming sensor data from 200+ edge devices. The wrong choice could cost months of rework and impact system performance. This kata teaches you to create professional Architectural Decision Records (ADRs) that justify technology choices with structured evaluation methodology.

## Essential Setup

- [ ] VS Code with GitHub Copilot Chat extension enabled and active subscription
- [ ] Repository cloned with access to `docs/solution-adr-library/` folder
- [ ] Basic understanding of IoT/messaging concepts (MQTT, Apache Kafka, edge computing principles)
- [ ] Familiarity with Architecture Decision Record structure and purpose
- [ ] Load Task Researcher agent (`.github/agents/task-researcher.agent.md`)
- [ ] Load ADR Creation agent (`.github/agents/adr-creation.agent.md`)
- [ ] ADR template reviewed (`docs/solution-adr-library/adr-template-solutions.md` — complete ADR structure with YAML frontmatter instructions)
- [ ] Example ADR browsed (e.g., `mqtt-qos.md` or `asset-connectivity-monitoring.md`)
- [ ] Time allocated: ⏱️ **60 minutes** (ADR research, evaluation, documentation)

**Quick Validation**: Verify Copilot with `code --list-extensions | grep -i copilot`. Agent workflow: Research with Task Researcher → Document with ADR Creation.

## Practice Tasks

### Task 1: Research and Understand the Decision Context (10 minutes)

**What You'll Do**: Gather requirements and understand the architectural decision that needs to be made using project infrastructure.

**Steps**:

1. **Review** the business scenario and technical requirements
   - [ ] Industrial IoT system with 200+ edge devices sending sensor data
   - [ ] Requirements: real-time processing, device communication, Azure cloud integration
   - [ ] **Expected result**: Clear understanding of what needs to be decided

2. **Reference** the template structure you explored earlier
   - [ ] Return to the ADR Template (see Essential Setup above) - focus on the YAML drafting guide section
   - [ ] Note the key sections you'll need: Context, Decision Drivers, Considered Options, Consequences
   - [ ] Keep the messaging-related example (mqtt-qos.md) open in a tab for quick reference
   - [ ] **Validation checkpoint**: Before proceeding, list the main ADR sections from memory to ensure understanding
   - [ ] **Expected result**: Clear mental map of the ADR structure you'll create
   - [ ] **Pro tip**: The [ADR Solution Library README][project-adr-library] has useful guidelines - mark it for reference, you don't need to read it all now

3. **Identify** the key evaluation criteria using structured approach
   - [ ] Use GitHub Copilot to research evaluation criteria for messaging architecture decisions
   - [ ] Focus on: Performance requirements, complexity, Azure integration, cost considerations, scalability
   - **Validation checkpoint**: Can you list 5-6 specific criteria for MQTT vs Kafka evaluation?
   - [ ] **Success check**: Clear understanding of what factors will drive your architectural decision

### Task 2: Research and Compare Technologies (15 minutes)

**What You'll Do**: Create a structured research document comparing MQTT vs Apache Kafka using the Task Researcher agent, then iteratively add findings.

**Steps**:

1. **Create research document using Task Researcher agent**
   - [ ] Open GitHub Copilot Chat and ensure Task Researcher agent is active
   - [ ] Copy and paste this exact prompt:

   ```text
   Help me research MQTT vs Apache Kafka for industrial IoT with 500+ edge devices.

   Create a comparison table with these rows:
   - Performance (throughput, latency)
   - Protocol Efficiency (message overhead, bandwidth)
   - Device Support (client libraries, edge compatibility)
   - Azure Integration (IoT Hub, Event Hubs compatibility)
   - Operational Complexity (setup, maintenance)
   - Scalability (horizontal scaling, partition handling)
   - Cost (infrastructure, operational)

   Output the results as a markdown table.
   ```

   - [ ] **Pro tip**: Task Researcher automatically saves your research document to `.copilot-tracking/research/` - look there to find your document
   - [ ] **Expected result**: Initial research document framework with comparison table structure

2. **Add MQTT details to research document**
   - [ ] Copy and paste this prompt:

   ```text
   Update the document with detailed MQTT characteristics focusing on protocol efficiency, device support, Azure IoT Operations integration, latency, and complexity
   ```

   - **Validation checkpoint**: Can you explain MQTT's advantages for edge device communication?
   - [ ] **Expected result**: Research document updated with comprehensive MQTT analysis

3. **Add Apache Kafka details to research document**
   - [ ] Copy and paste this prompt:

   ```text
   Update the document with detailed Apache Kafka characteristics focusing on throughput, durability, Azure Event Hubs compatibility, operational complexity, and cost
   ```

   - **Validation checkpoint**: Can you explain Kafka's advantages for high-volume data streaming?
   - [ ] **Expected result**: Research document updated with comprehensive Kafka analysis

4. **Finalize** comparison matrix with trade-off analysis
   - [ ] Review your research document and identify clear winners/losers for each evaluation criteria
   - [ ] Copy and paste this prompt:

   ```text
   Add a trade-offs analysis section highlighting where each technology excels or falls short
   ```

   - [ ] **Success check**: Complete research document with comparison table and trade-off analysis
   - [ ] **Expected result**: Evidence-based research ready to transform into professional ADR documentation

### Task 3: Create Professional ADR Documentation (15 minutes)

**What You'll Do**: Transform your research into a complete ADR using ADR Creation agent and project templates.

**Steps**:

1. **Switch to ADR Creation agent with research in context**
   - [ ] Find your research document in `.copilot-tracking/research/` (should be named with timestamp)
   - [ ] In GitHub Copilot Chat, attach your research document using the paperclip icon or drag-and-drop
   - [ ] Switch to **ADR Creation agent** from the mode selector dropdown
   - [ ] Copy and paste this exact prompt:

   ```text
   I have completed research comparing MQTT vs Apache Kafka for an industrial IoT system with 200+ edge devices.

   Help me create a professional ADR following the template structure with these sections:
   - Status: Proposed
   - Context: Industrial IoT system requirements (real-time data, 200+ devices, Azure integration)
   - Decision Drivers: Key evaluation criteria from my research
   - Considered Options: MQTT and Apache Kafka with trade-off analysis
   - Decision: Recommendation with justification
   - Consequences: Implementation implications and next steps

   Use the research document I've attached as evidence for the analysis.
   ```

   - [ ] Copy the ADR Template content as your starting point
   - [ ] Name your ADR file appropriately (e.g., "messaging-architecture-mqtt-vs-kafka.md")
   - [ ] Work with ADR Creation agent to fill in Context section using the scenario from Quick Context (200+ edge devices, sensor data streaming, real-time processing)
   - **Validation checkpoint**: Does your Context section clearly explain the business problem and technical requirements?
   - [ ] **Expected result**: ADR structure with professional context documentation based on your research

2. **Document** your technology evaluation and decision
   - [ ] Work with ADR Creation agent to present MQTT vs Kafka comparison with specific trade-offs per criteria
   - [ ] Use your research document as evidence: reference specific findings from your comparison table
   - [ ] Make clear recommendation with strong technical justification based on your research
   - [ ] Include consideration of Azure services integration and edge computing requirements
   - **Validation checkpoint**: Is your decision clearly justified with evidence from your research document?
   - [ ] **Expected result**: Complete decision documentation with professional rationale backed by research findings

3. **Review** and validate your ADR quality against solution library standards
   - [ ] Check ADR structure against ADR Template requirements
   - [ ] Ensure professional tone and clear technical reasoning throughout
   - [ ] Verify all standard ADR sections are complete and coherent (Context, Decision, Consequences, etc.)
   - [ ] Compare quality against real-world examples in `docs/solution-adr-library/` for professional standard
   - **Success validation**: ADR meets solution library standards and clearly justifies technology choice with implementation guidance
   - [ ] **Expected result**: Professional-quality ADR ready for team review and potential inclusion in solution library

## Completion Check

**You've Succeeded When**:

- [ ] Used Task Researcher agent to create structured research document before ADR creation
- [ ] Navigated project ADR library confidently and understood template structure
- [ ] Successfully used AI assistance for technology research with structured evaluation criteria
- [ ] Created a complete ADR following project template with professional documentation quality
- [ ] Documented clear evaluation of MQTT vs Apache Kafka with specific technical criteria and trade-offs
- [ ] Made a justified recommendation with strong technical rationale based on research evidence
- [ ] ADR meets project standards and is ready for team review and potential acceptance

**Test your understanding** (try each without looking at notes):

- [ ] **Memory check**: List the main ADR sections (Status, Context, Decision, Consequences...)
- [ ] **Explain your choice**: In 2-3 sentences, why is MQTT or Kafka better for this scenario?
- [ ] **Quality check**: Read your ADR's Decision section aloud — does it sound confident and well-justified?
- [ ] **Peer review**: Show your ADR to a colleague or use Copilot Ask to critique it

**Confidence check**:

- [ ] I could create another ADR for a different architectural decision using this same process
- [ ] I understand the difference between a weak ADR ("X is popular") and a strong one ("X meets criteria A, B, C as shown...")

**Ready for more?** Try creating an ADR for a different messaging technology decision (e.g., RabbitMQ vs Azure Service Bus) using this same process without agent guidance.

---

## Reference Appendix

### Help Resources

**Core Resources** (you used these during the kata):

- [Task Researcher Agent][task-researcher] - `.github/agents/task-researcher.agent.md`
- [ADR Creation Agent][adr-create] - `.github/agents/adr-creation.agent.md`
- [ADR Template][project-adr-library] - See Essential Setup section for full path and description
- [Example ADRs][project-adr-library] - `mqtt-qos.md`, `asset-connectivity-monitoring.md`

**Additional Learning**:

- [Learning Kata Coach][kata-coach] - General kata coaching and troubleshooting
- [Azure IoT Operations][ms-azure-iot-ops] - IoT messaging patterns and integration
- [Azure Event Hubs][ms-azure-event-hubs] - Event streaming architecture

**Optional Reading**: `docs/solution-adr-library/README.md` for contribution guidelines and standards

### Professional Tips

- Start with the problem context before jumping into technology comparisons - this helps frame the decision appropriately
- Use concrete metrics and requirements rather than vague statements like "better" or "faster" - quantify performance needs
- Keep ADRs concise but complete - aim for clarity over exhaustive detail
- Document the decision process, not just the final choice - future readers will benefit from understanding the trade-offs considered

### Troubleshooting

Common issues and solutions:

- **Difficulty structuring ADR with clear decision rationale**: Use ADR template and include context, options considered, and decision criteria
- **Technology comparison lacks technical depth**: Research specific features, performance characteristics, and use case fit
- **ADR documentation not meeting review standards**: Follow ADR template structure and include peer review feedback

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[kata-coach]: /.github/agents/learning-kata-coach.agent.md
[task-researcher]: /.github/agents/task-researcher.agent.md
[adr-create]: /.github/agents/adr-creation.agent.md
[project-adr-library]: /docs/solution-adr-library/README
[ms-azure-iot-ops]: https://learn.microsoft.com/azure/iot-operations/
[ms-azure-event-hubs]: https://docs.microsoft.com/azure/event-hubs/
