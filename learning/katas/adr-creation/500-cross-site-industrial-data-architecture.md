---
title: 'Kata: 500 - Cross-Site Industrial Data Architecture'
description: Design site-to-site VPN architecture for manufacturing data flow with Azure IoT Operations, MQTT bridging, and real-time operational requirements
author: Edge AI Team
ms.date: 2025-01-20
kata_id: adr-creation-500-cross-site-industrial-data-architecture
kata_category:
  - adr-creation
kata_difficulty: 5
estimated_time_minutes: 180
learning_objectives:
  - Design site-to-site VPN architectures for cross-site manufacturing data flow
  - Evaluate VPN topology patterns and MQTT bridging strategies
  - Balance real-time operational requirements with network security and site autonomy
  - Create Board-level ADRs with network architecture and implementation roadmaps
prerequisite_katas:
  - adr-creation-100-basic-messaging-architecture
  - adr-creation-200-advanced-observability-stack
  - adr-creation-400-service-mesh-selection
technologies:
  - Azure VPN Gateway
  - Azure IoT Operations
  - MQTT Broker
  - Site-to-Site VPN
  - Azure Arc
  - Network Architecture
  - Industrial IoT
  - JIT Manufacturing
success_criteria:
  - Design and document complete site-to-site VPN architecture for cross-site data flow
  - Evaluate VPN topology patterns and MQTT bridging strategies comprehensively
  - Create Board-level ADR with network topology and 6-month implementation roadmap
ai_coaching_level: minimal
scaffolding_level: light
hint_strategy: progressive
common_pitfalls: []
requires_azure_subscription: false
requires_local_environment: true
tags:
  - adr-creation
search_keywords:
  - site-to-site-vpn-architecture
  - cross-site-manufacturing
  - mqtt-broker-bridging
  - vpn-topology-patterns
  - industrial-network-architecture
---

## Quick Context

**You'll Learn**: Design complete site-to-site VPN architectures for cross-site manufacturing data flow, balancing real-time operational requirements, network security, MQTT bridging strategies, and compliance constraints.

**Prerequisites**: Completion of all previous ADR katas, understanding of Azure IoT Operations MQTT broker and data pipelines, knowledge of site-to-site VPN and network architecture, familiarity with manufacturing supply chain and JIT production concepts

**Real Challenge**: You're the Solutions Architect for a Tier 1 automotive supplier with two critical manufacturing sites that must share data in real-time via site-to-site VPN:

**Component Factory (Detroit, MI)**: 500+ edge devices running Azure IoT Operations producing electronic control modules. Quality inspection AI models detect defects in real-time. Must push component serial numbers, quality test results, production metrics, and predictive maintenance alerts to assembly plant over VPN.

**Assembly Plant (Chattanooga, TN)**: 800+ edge devices running Azure IoT Operations for final vehicle assembly using Detroit components. JIT inventory requires real-time component availability data over VPN. Assembly plant frequently assembles vehicles with defective components because quality data doesn't flow in real-time, causing warranty claims and recalls.

**The Stakes**: Design the complete site-to-site VPN architecture with MQTT broker bridging enabling real-time bidirectional data flow while maintaining site autonomy, security compliance (ITAR, automotive cybersecurity standards), and operational resilience. Wrong choice impacts 15,000 vehicles/month production capacity ($450M/month revenue at risk).

**Your Task**: Create a Board-level ADR evaluating VPN topology patterns (hub-and-spoke, mesh, hybrid) and MQTT bridging strategies against all competing constraints, documenting strategic recommendation with network topology, security architecture, and 6-month phased implementation roadmap.

## Essential Setup

**Required** (check these first):

- [ ] Completion of all previous ADR katas (Kata 01: Messaging, Kata 02: Observability, Kata 04: Service Mesh) with ADR research and documentation expertise
- [ ] Site-to-site VPN concepts: Azure VPN Gateway SKUs (VpnGw1-5, 650 Mbps to 10 Gbps throughput, 30-100 tunnel limits), policy-based vs route-based connections, IPsec tunnel configuration
- [ ] VPN topology patterns: hub-and-spoke (centralized management, potential bottleneck), mesh (direct site-to-site, N² complexity), hybrid (hub for management + mesh for high-volume)
- [ ] VPN redundancy strategies: active-active (dual tunnels with BGP load balancing, <30s failover), active-passive (single active tunnel, 60-90s failover), multi-path (redundant ISPs/regions)
- [ ] MQTT broker-to-broker bridging: topic mapping with site prefixes (`detroit/quality/#`, `chattanooga/assembly/#`), wildcard subscriptions, topic rewrite rules for canonical naming
- [ ] MQTT QoS and session handling: QoS 0 (at most once) for high-volume telemetry, QoS 1 (at least once) for critical production data, persistent sessions (clean_session=false) for guaranteed delivery during disconnections
- [ ] Azure IoT Operations dataflow pipelines: source connectors (MQTT topics, HTTP endpoints), transformation stages (filtering, schema validation, enrichment), destination connectors (Event Hubs, MQTT, databases), bidirectional routing configuration
- [ ] Network segmentation: security zones (Production OT, DMZ, Corporate IT, Cloud), firewall rules allowing only required inter-zone traffic (OT → DMZ MQTT 8883, DMZ → Cloud VPN 500/4500), separate VLANs per zone
- [ ] DMZ design: dual-firewall architecture (external firewall between cloud/WAN and DMZ, internal firewall between DMZ and OT), VPN gateway termination in DMZ, MQTT broker bridge instances in DMZ
- [ ] OT network isolation: dedicated infrastructure for OT (separate switches/routers/cabling), VLANs for traffic segregation, unidirectional gateways (data diodes) for critical OT data export, MFA for OT zone access
- [ ] IPsec encryption: IKE Phase 1 authentication (pre-shared keys or certificates), AES-256-GCM encryption, SHA-256 integrity, DH Group 14+ for key exchange, PKI certificate rotation policies
- [ ] JIT manufacturing impact: components arrive exactly when needed (no buffer inventory), Detroit produces on real-time Chattanooga demand signals, VPN downtime causes production stoppage ($15M/hour), latency >5s creates assembly line buffering issues
- [ ] Compliance requirements: ITAR (FIPS 140-2 encryption for cross-border transfers, dedicated tunnels for controlled technical data, 5-year audit retention, U.S. persons access only), ISO/SAE 21434 (threat modeling with CVSS scores, approved protocols only, IDS/IPS at gateways, SIEM integration)
- [ ] Time allocated: 180 minutes for VPN architecture design (hub-and-spoke vs mesh vs hybrid evaluation), MQTT bridging strategy (broker-to-broker vs dataflow pipelines), and Board-level ADR creation with network topology diagrams and 6-month implementation roadmap

**Quick Validation**: Verify previous ADR kata completion and access to Azure networking and IoT Operations documentation.

**💡 Pro Tip**: This is a Board-level architecture decision - use appropriate chatmodes for research, analysis, and executive documentation phases.

**📁 Pro Tip**: Task Researcher automatically saves research documents to `.copilot-tracking/research/` - organize VPN topology research, MQTT bridging analysis, and security compliance documentation there.

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** chat mode for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** mode and say:
>
> ```text
> I'm working on 04 - Cross-Site Industrial Data Architecture kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: VPN Topology and MQTT Bridging Research (25 minutes)

**What You'll Do**: Research VPN topology patterns and MQTT bridging strategies for cross-site industrial data flow with bidirectional communication.

**Steps**:

1. **Research** hub-and-spoke VPN topology with central Azure hub
   - [ ] Azure VPN Gateway as central hub, spoke connections to each manufacturing site
   - [ ] Focus on: centralized management, Azure integration, single point of failure risks
   - [ ] Analyze: MQTT broker placement (central vs distributed), data routing patterns
   - [ ] **Expected result**: Understanding of hub-and-spoke benefits and limitations for manufacturing

2. **Research** full mesh VPN topology with direct site-to-site connections
   - [ ] Direct VPN tunnels between all site pairs, no central dependency
   - [ ] Focus on: low latency, site autonomy, configuration complexity at scale
   - [ ] Analyze: MQTT broker-to-broker bridging, topic routing, QoS handling
   - [ ] **Expected result**: Understanding of mesh topology trade-offs and operational overhead

3. **Research** hybrid VPN topology patterns
   - [ ] Combination of hub-and-spoke for management with selective site-to-site for critical paths
   - [ ] Focus on: balanced approach, optimized latency, selective direct connections
   - [ ] Analyze: Azure IoT Operations dataflow pipelines, conditional routing logic
   - [ ] **Expected result**: Understanding of hybrid patterns balancing simplicity and performance

4. **Research** MQTT bridging and data pipeline strategies
   - [ ] MQTT bridge configuration (topics, QoS, retained messages, session persistence)
   - [ ] Azure IoT Operations dataflow pipelines for transformation and routing
   - [ ] Focus on: message transformation, schema evolution, error handling
   - [ ] Analyze: bidirectional data flow patterns, conflict resolution, message ordering
   - [ ] **Expected result**: Understanding of MQTT bridging complexity and configuration requirements

**Success check**: Can articulate VPN topology patterns with clear trade-offs for cross-site manufacturing, including latency, complexity, autonomy, and MQTT bridging strategies.

### Task 2: Multi-Dimensional Requirements Analysis (20 minutes)

**What You'll Do**: Analyze competing constraints and define weighted evaluation criteria across technical, network, security, operational, and business dimensions with VPN focus.

**Steps**:

1. **Map** technical and performance requirements for VPN-based data flow
   - [ ] Latency requirements: assembly plant needs quality data <5 seconds via VPN
   - [ ] Throughput capacity: 10,000+ messages/minute over VPN tunnels
   - [ ] Data volume modeling: component telemetry (1KB), quality images (500KB), production metrics (5KB)
   - [ ] VPN bandwidth planning: peak traffic patterns, compression strategies
   - [ ] Bidirectional flow patterns: both sites produce and consume data
   - [ ] **Expected result**: Quantified VPN performance requirements with bandwidth planning

2. **Evaluate** VPN network architecture and security requirements
   - [ ] VPN topology: hub-and-spoke vs mesh vs hybrid for 2 sites (scaling to 5 sites)
   - [ ] VPN tunnel redundancy: active-active, active-passive, multi-path
   - [ ] Network segmentation: OT network isolation, DMZ requirements, security zones
   - [ ] ITAR compliance: controlled technical data handling over VPN
   - [ ] Automotive cybersecurity: ISO/SAE 21434, encrypted VPN tunnels, certificate management
   - [ ] Authentication: site identity, device identity, VPN tunnel authentication
   - [ ] **Expected result**: VPN topology requirements and security architecture framework

3. **Evaluate** MQTT bridging strategy options with technical specificity
   - [ ] **Option A - MQTT Broker-to-Broker Bridge**: Direct bridge configuration between site MQTT brokers
     - Configuration: bridge topics, QoS mapping (QoS 0 vs 1 vs 2), retained message handling
     - Session persistence: how bridge handles VPN tunnel failures and reconnection
     - Bidirectional flow: bridge configuration for both Detroit→Chattanooga and Chattanooga→Detroit
   - [ ] **Option B - Azure IoT Operations Dataflow Pipelines**: Cloud-routed data transformation
     - Transformation: schema evolution, message enrichment, filtering, aggregation
     - Routing logic: conditional routing, multi-destination fanout, error handling
     - Cloud dependency: dataflow requires cloud connectivity, implications for site autonomy
   - [ ] Evaluate against requirements: latency (<5 seconds), message ordering, exactly-once delivery
   - [ ] **Expected result**: Structured comparison of MQTT bridging approaches with technical trade-offs

4. **Assess** operational resilience and VPN/MQTT fault tolerance
   - [ ] Site autonomy: each site must operate independently if VPN tunnel fails
   - [ ] VPN failover: automatic tunnel failover <30 seconds, backup paths
   - [ ] MQTT bridge resilience: session persistence, message queuing during VPN outage
   - [ ] Monitoring: VPN tunnel health, MQTT bridge status, message flow tracing
   - [ ] Maintenance windows: VPN upgrade procedures, MQTT broker maintenance
   - [ ] Team capability: 2-person edge team per site, VPN configuration expertise
   - [ ] **Expected result**: Operational complexity assessment with VPN and MQTT resilience

5. **Analyze** business and scalability factors
   - [ ] VPN scalability: adding 3 additional component factories over 18 months
   - [ ] Topology evolution: how hub-and-spoke vs mesh scales from 2 to 5 sites
   - [ ] Implementation timeline: 6-month phased deployment, no production disruption
   - [ ] Financial impact: 15,000 vehicles/month, warranty claim reduction, recall avoidance
   - [ ] Cost considerations: VPN gateway sizing, bandwidth costs, operational overhead
   - [ ] **Expected result**: Scalability analysis and strategic business requirements

**Success check**: Have comprehensive evaluation framework with weighted criteria focused on VPN topology selection, MQTT bridging strategy comparison, and operational resilience planning.

### Task 3: Strategic ADR with VPN Architecture and Implementation Roadmap (25 minutes)

**What You'll Do**: Create Board-level ADR with VPN topology recommendation, MQTT bridging strategy, network architecture diagrams, security design, and 6-month phased implementation roadmap.

**Steps**:

1. **Execute** comprehensive VPN topology and MQTT bridging evaluation
   - [ ] Create Context section using scenario from Quick Context (Component Factory → Assembly Plant via VPN)
   - [ ] Score VPN topology patterns (hub-and-spoke, mesh, hybrid) against weighted criteria
   - [ ] Evaluate MQTT bridging strategies: broker-to-broker bridge vs dataflow pipelines
   - [ ] Include: latency modeling over VPN, throughput calculations, bandwidth planning
   - [ ] Document: VPN network topology diagrams, MQTT topic routing diagrams, security architecture
   - [ ] Analyze: VPN gateway sizing, tunnel redundancy, failover scenarios
   - [ ] **Expected result**: Comprehensive VPN topology comparison with quantified analysis and visual diagrams

2. **Present** strategic VPN architecture recommendation with risk analysis
   - [ ] Clear recommendation: VPN topology choice with technical and operational justification
   - [ ] MQTT bridging strategy: bridge configuration, topic routing, QoS levels, retained messages
   - [ ] Risk assessment: VPN tunnel failure modes, MQTT bridge failures, network partitioning
   - [ ] Mitigation strategies: redundant VPN tunnels, MQTT session persistence, monitoring
   - [ ] Address compliance: ITAR data handling over VPN, automotive cybersecurity certification
   - [ ] Financial impact: warranty claim reduction, recall avoidance, production efficiency
   - [ ] **Expected result**: Board-level VPN architecture recommendation with comprehensive risk mitigation

3. **Develop** 6-month phased VPN deployment roadmap with expansion strategy
   - [ ] Phase 1 (Weeks 1-8): VPN infrastructure deployment, tunnel establishment, connectivity testing
   - [ ] Phase 2 (Weeks 9-14): Azure IoT Operations MQTT broker configuration, bridge setup, security hardening
   - [ ] Phase 3 (Weeks 15-20): MQTT bridging implementation, topic routing, data pipeline testing
   - [ ] Phase 4 (Weeks 21-26): Production cutover, performance validation, operational handoff
   - [ ] Include: success metrics for each phase, decision gates, rollback procedures
   - [ ] Document: expansion strategy for 3 additional factories, VPN topology scaling approach
   - [ ] Network design: IP addressing, routing tables, firewall rules, security zones
   - [ ] **Expected result**: Detailed VPN implementation roadmap with expansion plan for 5-site topology

**Success criteria**: Complete Board-level ADR ready for manufacturing operations and IT approval with detailed VPN topology, MQTT bridging architecture, security compliance, financial impact ($450M revenue protection), and actionable 6-month VPN deployment plan.

## Completion Check

**You've Succeeded When**:

- [ ] Created comprehensive ADR evaluating VPN topology patterns (hub-and-spoke, mesh, hybrid)
- [ ] Evaluated MQTT bridging strategies and data pipeline configuration approaches
- [ ] Addressed all competing constraints: VPN performance, network security, operational resilience
- [ ] Documented strategic VPN architecture with network topology and MQTT bridging diagrams
- [ ] Developed 6-month phased VPN deployment roadmap with expansion to 5 sites
- [ ] ADR meets Board-level quality standards for major VPN infrastructure investment
- [ ] Addressed ITAR compliance and automotive cybersecurity certification (ISO/SAE 21434)

Ready for more? This capstone kata demonstrates proficiency in complex cross-site architecture decisions - apply these techniques to real-world multi-site manufacturing integration and supply chain optimization.

---

## Reference Appendix

### Help Resources

**Optional AI Assistance Tools**:

- [Task Researcher Chatmode][task-researcher] - For systematic research and analysis ([`.github/chatmodes/task-researcher.chatmode.md`](.github/chatmodes/task-researcher.chatmode.md))
- [ADR Creation Chatmode][adr-create] - For professional documentation and strategic writing ([`.github/chatmodes/adr-creation.chatmode.md`](.github/chatmodes/adr-creation.chatmode.md))
- [ADR Solution Library][adr-library] - Templates and examples for reference ([`docs/solution-adr-library`](docs/solution-adr-library))

**Azure IoT Operations Documentation**:

- [Azure IoT Operations][ms-azure-iot-operations] - Unified data plane for industrial IoT scenarios
- [Azure IoT Operations MQTT Broker][ms-aio-mqtt-broker] - MQTT broker configuration and bridging patterns
- [Azure IoT Operations Data Pipelines][ms-aio-dataflows] - Data transformation and routing capabilities
- [Azure Arc-enabled Kubernetes][ms-azure-arc-kubernetes] - Hybrid and multi-cloud Kubernetes management

**Network and VPN Documentation**:

- [Azure VPN Gateway][ms-azure-vpn-gateway] - Site-to-site VPN configuration and topologies
- [Site-to-Site VPN Topologies][ms-vpn-topologies] - Hub-and-spoke, mesh, and hybrid patterns
- [Azure Network Security][ms-azure-network-security] - Network segmentation, DMZ design, security zones
- [VPN High Availability][ms-vpn-ha] - Active-active, active-passive, and multi-path redundancy

**Compliance and Standards**:

- [ITAR Compliance][itar-compliance] - International Traffic in Arms Regulations for controlled technical data
- [ISO/SAE 21434][iso-sae-21434] - Road vehicles cybersecurity engineering standard

**Manufacturing and Supply Chain**:

- [JIT Manufacturing][jit-manufacturing] - Just-in-time production and supply chain coordination patterns
- [Component Traceability][component-traceability] - Automotive industry component tracking and quality management
- Previous ADRs - Reference methodology consistency across related decisions

### Professional Tips

- **Separate VPN topology from MQTT bridging analysis**: Evaluate network architecture (hub-and-spoke vs mesh vs hybrid) independently from data routing strategy (MQTT bridge vs dataflow pipelines) to avoid conflating distinct architectural layers with different trade-off dimensions
- **Model VPN performance with concrete bandwidth calculations**: Board-level decisions require quantified analysis - calculate peak message throughput (10,000 msgs/min), message sizes (1KB-500KB), VPN bandwidth requirements (Mbps), and latency budgets (<5 seconds) rather than qualitative assessments
- **Design for VPN tunnel failure modes explicitly**: Document specific failure scenarios (primary tunnel down, complete site isolation, VPN gateway failure) with measured recovery time objectives (30 seconds failover), MQTT session persistence behavior, and message queuing strategies during network partitioning
- **Address compliance requirements with technical specificity**: ITAR and ISO/SAE 21434 require concrete technical controls - document VPN encryption protocols (IPsec), certificate management procedures, network segmentation architecture (DMZ, security zones), and audit logging capabilities rather than generic compliance statements

### Troubleshooting

- **Issue**: VPN topology evaluation becomes overwhelming with too many architecture patterns and configuration options
  **Quick Fix**: Start with 2-site scenario requirements (latency, throughput, autonomy) and evaluate only hub-and-spoke vs mesh patterns first - add hybrid patterns only if neither pure approach satisfies all constraints. Focus on differentiating factors: centralized management vs site autonomy, single point of failure vs configuration complexity

- **Issue**: Uncertain whether to recommend MQTT broker-to-broker bridging or Azure IoT Operations dataflow pipelines for cross-site data routing
  **Quick Fix**: Evaluate based on transformation requirements - if sites need identical message formats (simple topic forwarding), MQTT bridge is simpler; if sites require schema transformation, filtering, or cloud integration, dataflow pipelines provide necessary flexibility. Document which approach satisfies bidirectional flow, QoS handling, and session persistence requirements

- **Issue**: 6-month implementation roadmap feels generic without specific VPN deployment phases and MQTT configuration milestones
  **Quick Fix**: Structure roadmap around concrete deliverables: Phase 1 (VPN tunnel establishment, connectivity testing), Phase 2 (MQTT broker configuration, bridge setup), Phase 3 (data pipeline testing, topic routing validation), Phase 4 (production cutover, performance validation). Include decision gates (latency <5s, throughput >10K msgs/min) and rollback procedures for each phase

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[task-researcher]: /.github/chatmodes/task-researcher.chatmode.md
[adr-create]: /.github/chatmodes/adr-creation.chatmode.md
[adr-library]: /docs/solution-adr-library/
[ms-azure-iot-operations]: https://docs.microsoft.com/azure/iot-operations/
[ms-aio-mqtt-broker]: https://docs.microsoft.com/azure/iot-operations/manage-mqtt-broker/
[ms-aio-dataflows]: https://docs.microsoft.com/azure/iot-operations/connect-to-cloud/overview-dataflow
[ms-azure-arc-kubernetes]: https://docs.microsoft.com/azure/azure-arc/kubernetes/
[ms-azure-vpn-gateway]: https://docs.microsoft.com/azure/vpn-gateway/
[ms-vpn-topologies]: https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-topology-design
[ms-azure-network-security]: https://docs.microsoft.com/azure/security/fundamentals/network-overview
[ms-vpn-ha]: https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-highlyavailable
[itar-compliance]: https://www.pmddtc.state.gov/ddtc_public/ddtc_public?id=ddtc_public_portal_itar_landing
[iso-sae-21434]: https://www.iso.org/standard/70918.html
[jit-manufacturing]: https://www.investopedia.com/terms/j/jit.asp
[component-traceability]: https://www.automotive-iq.com/quality/articles/component-traceability-automotive-industry
