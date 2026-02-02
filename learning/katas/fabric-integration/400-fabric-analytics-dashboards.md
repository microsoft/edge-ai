---
title: 'Kata: 400 - Fabric Analytics Dashboards'
description: Build advanced analytics dashboards in Microsoft Fabric using real-time edge-to-cloud data
author: Edge AI Team
ms.date: 2025-10-20
ms.topic: how-to-guide
kata_id: 'fabric-integration-400-fabric-analytics-dashboards'
kata_category:
  - fabric-integration
kata_difficulty: 4
estimated_time_minutes: 150
learning_objectives:
  - Design and implement real-time analytics dashboards in Fabric
  - Integrate edge-to-cloud data sources for live visualization
  - Apply advanced KQL and DAX for insights and anomaly detection
  - Automate dashboard deployment and sharing
prerequisite_katas:
  - fabric-integration-200-prerequisite-full-deployment
  - fabric-integration-200-fabric-workspace-configuration
  - fabric-integration-100-fabric-rti-blueprint-deployment
  - fabric-integration-300-edge-to-cloud-data-pipeline
technologies:
  - Microsoft Fabric
  - KQL
  - DAX
  - Power BI
  - Azure IoT Operations
success_criteria:
  - Create and publish a real-time dashboard in Fabric
  - Integrate multiple data sources (edge, cloud, RTI)
  - Implement advanced queries for actionable insights
  - Automate dashboard refresh and sharing
ai_coaching_level: minimal
scaffolding_level: light
hint_strategy: minimal
common_pitfalls:
  - Data latency - Dashboards not updating in real time due to inefficient refresh schedules or query design
  - Query complexity - Inefficient KQL or DAX queries causing slow performance and timeouts in dashboard loading
  - Integration gaps - Missing data sources or incomplete joins between edge and cloud data preventing full visibility
  - Manual refresh - Failing to automate dashboard updates resulting in stale data and manual overhead
requires_azure_subscription: true
requires_local_environment: true
tags:
  - fabric-integration
search_keywords:
  - fabric-dashboard
  - real-time-analytics
  - KQL
  - DAX
---

## Quick Context

### You'll Learn

- Design and implement real-time analytics dashboards in Microsoft Fabric
- Integrate multiple edge-to-cloud data sources for unified visualization
- Apply advanced KQL and DAX queries for insights and anomaly detection
- Automate dashboard deployment, refresh, and sharing workflows

### Prerequisites

- Completed fabric-integration-200-prerequisite-full-deployment kata
- Completed fabric-integration-200-fabric-workspace-configuration kata
- Completed fabric-integration-100-fabric-rti-blueprint-deployment kata
- Completed fabric-integration-300-edge-to-cloud-data-pipeline kata
- Azure subscription with sufficient credits
- Sample edge-to-cloud data pipeline running with live data
- Basic Power BI and KQL/DAX knowledge

### Real Challenge

You're a data analyst at an energy company monitoring distributed wind farms in real time. Leadership needs executive dashboards showing production metrics, anomaly detection, and predictive maintenance indicators. Your team has edge telemetry flowing to Fabric, but stakeholders can't visualize trends or identify issues quickly. This kata guides you through designing dashboard architecture, integrating data sources, building advanced queries, and automating refresh and sharing.

**Note**: This kata uses role-based scenarios without company names to maintain focus on technical learning objectives.

## Essential Setup

- [ ] Completed all previous katas and have access to Fabric workspace

- [ ] Power BI Desktop or Fabric web interface available

- [ ] Sample edge-to-cloud data pipeline running

- [ ] Permissions to publish and share dashboards

> **🤖 Want Interactive AI Coaching?**
>
> Load the **Learning Kata Coach** custom agent for task check-offs, progress tracking, progressive hints, and personalized guidance.
>
> In GitHub Copilot Chat, select **Learning Kata Coach** custom agent and say:
>
> ```text
> I'm working on 04 - Fabric Analytics Dashboards kata and want interactive coaching with progress tracking.
> ```

## Practice Tasks

### Task 1: Design Dashboard Architecture (30-35 minutes)

<!-- AI_COACH: Dashboard architecture requires balancing real-time requirements with query performance. Encourage learners to map data sources first, then define refresh strategy. Consider asking: Which metrics need second-by-second updates vs hourly aggregates? How does DirectQuery impact user experience? What happens when multiple users access the dashboard simultaneously? Guide exploration of semantic models and composite models for optimal performance. -->

**What You'll Do**: Design the dashboard architecture and plan data integration for real-time analytics.

**Steps**:

1. **Map** requirements and data sources
   - [ ] List dashboard requirements: metrics, KPIs, time ranges, drill-down needs
   - [ ] Identify data sources: Eventhouse tables, EventStream, cloud databases
   - [ ] **Pro tip**: Group requirements by update frequency to optimize refresh strategy
   - [ ] Document data source locations and access methods
   - [ ] **Expected result**: Requirements and data source map documented

2. **Plan** refresh strategy
   - [ ] Determine refresh frequency for each data source
   - [ ] Choose refresh method: DirectQuery, Import, Streaming, or Hybrid
   - [ ] Consider latency vs performance tradeoffs
   - [ ] **Validation checkpoint**: Can you explain why you chose DirectQuery vs Import for each source?
   - [ ] **Expected result**: Refresh strategy documented with justifications

3. **Document** architecture
   - [ ] Create architecture diagram showing data flow
   - [ ] Document integration points and dependencies
   - [ ] List technical constraints and assumptions
   - [ ] **Success check**: Architecture diagram clearly shows edge-to-dashboard data flow
   - [ ] **Expected result**: Complete architecture documentation ready for implementation

### Task 2: Integrate Data Sources and Build Visuals (35-40 minutes)

<!-- AI_COACH: Data integration in Fabric involves multiple connection types and authentication methods. Rather than prescribing specific approaches, guide learners to explore workspace connections, semantic models, and data source settings. For visuals, encourage starting with simple charts before adding complexity. Consider asking: What story does each visual tell? How do visuals guide users to insights? Are there too many visuals causing cognitive overload? -->

**What You'll Do**: Connect data sources and create dashboard visuals for unified visualization.

**Steps**:

1. **Connect** data sources
   - [ ] In Fabric workspace, add connections to Eventhouse, EventStream, other sources
   - [ ] Configure authentication and permissions
   - [ ] Test connectivity and query performance
   - [ ] **Pro tip**: Use managed identities for secure, credential-free connections
   - [ ] **Expected result**: All data sources connected and accessible

2. **Build** initial visuals
   - [ ] Create visuals for key metrics: telemetry trends, alert counts, KPIs
   - [ ] Add time series charts for production metrics
   - [ ] Implement drill-down capability for detailed analysis
   - [ ] **Validation checkpoint**: Do visuals update automatically as new data arrives?
   - [ ] **Expected result**: Core visuals displaying live data

3. **Implement** joins and transformations
   - [ ] Create relationships between data sources
   - [ ] Add calculated columns and measures for derived metrics
   - [ ] Test unified view across edge and cloud data
   - [ ] **Success check**: Dashboard shows correlated data from multiple sources
   - [ ] **Expected result**: Unified dashboard with integrated data sources

### Task 3: Apply Advanced Queries (35-40 minutes)

<!-- AI_COACH: Advanced analytics require deep understanding of KQL and DAX semantics. Encourage learners to start simple and iterate. For anomaly detection, guide exploration of statistical functions and moving averages. For predictive queries, suggest time series functions. Rather than providing query templates, prompt learners to break down requirements: What defines an anomaly? What historical window is relevant? How should predictions handle seasonality? -->

**What You'll Do**: Implement advanced KQL and DAX queries for insights and anomaly detection.

**Steps**:

1. **Write** anomaly detection queries
   - [ ] Create KQL queries using statistical functions (percentiles, standard deviation)
   - [ ] Implement moving average calculations for baseline comparison
   - [ ] Add anomaly flagging logic
   - [ ] **Pro tip**: Use `series_decompose_anomalies()` in KQL for built-in anomaly detection
   - [ ] **Expected result**: Anomaly detection queries identifying outliers

2. **Implement** trend analysis
   - [ ] Write queries for time series analysis and forecasting
   - [ ] Add DAX measures for period-over-period comparisons
   - [ ] Create rolling aggregations for smoothed trends
   - [ ] **Validation checkpoint**: Do trends match expected patterns from your domain knowledge?
   - [ ] **Expected result**: Trend analysis queries showing patterns over time

3. **Optimize** query performance
   - [ ] Profile queries to identify slow operations
   - [ ] Add indexes or materialized views in Eventhouse if needed
   - [ ] Reduce query complexity where possible
   - [ ] Test performance under load (multiple concurrent users)
   - [ ] **Success check**: Dashboard loads in under 5 seconds with production data volumes
   - [ ] **Expected result**: Optimized queries with documented performance metrics

### Task 4: Automate Deployment and Sharing (30-35 minutes)

<!-- AI_COACH: Automation prevents manual errors and enables reliable operations. For dashboard refresh, encourage learners to explore both scheduled and event-driven triggers. For sharing, guide consideration of security and compliance: Who needs access? What permissions are appropriate? How should sensitive data be protected? Suggest exploring row-level security and dynamic permissions. Consider deployment pipelines for moving dashboards through dev/test/prod environments. -->

**What You'll Do**: Automate dashboard operations and configure access for production use.

**Steps**:

1. **Configure** automated refresh
   - [ ] Set up scheduled refresh for imported data (if applicable)
   - [ ] Configure event-driven refresh triggers for real-time updates
   - [ ] Add refresh failure alerts and monitoring
   - [ ] **Pro tip**: Stagger refresh times to avoid overwhelming data sources
   - [ ] **Expected result**: Automated refresh configured with monitoring

2. **Setup** sharing and permissions
   - [ ] Create workspace roles for different user types (viewer, contributor, admin)
   - [ ] Configure dashboard sharing with appropriate permissions
   - [ ] Implement row-level security if needed for data segregation
   - [ ] **Validation checkpoint**: Can you explain who has access to what data and why?
   - [ ] **Expected result**: Sharing configured with documented access control

3. **Document** deployment process
   - [ ] Create deployment runbook for moving dashboard to production
   - [ ] Document refresh schedule and dependencies
   - [ ] Write operational procedures for troubleshooting
   - [ ] **Success check**: Another team member can deploy and manage the dashboard using your documentation
   - [ ] **Expected result**: Complete deployment and operations documentation

## Completion Check

**You've Succeeded When:**

- [ ] You can describe your dashboard architecture decisions, including why you chose DirectQuery vs Import for specific data sources and how this impacts user experience

- [ ] You can explain how you handled data source authentication and permissions, including what security controls ensure only authorized users access sensitive telemetry data

- [ ] You can articulate your visualization choices and rationale, including how your visuals guide users from high-level KPIs to detailed drill-down analysis

- [ ] You can explain how your anomaly detection queries identify outliers, including what statistical methods you used and how you tuned thresholds to avoid false positives

- [ ] You can analyze your query performance results, including what optimizations you implemented to achieve sub-5-second dashboard load times and what bottlenecks remain

- [ ] You can walk through your automated refresh and sharing configuration, including how your solution ensures dashboards stay current without manual intervention and how access is controlled

---

## Reference Appendix

### Help Resources

- **Microsoft Fabric Dashboards**: [Real-time dashboards in Fabric][fabric-dashboards]

- **KQL**: [Kusto Query Language reference][kql-reference]

- **DAX**: [Data Analysis Expressions reference][dax-reference]

- **Power BI**: [Power BI documentation][powerbi-docs]

### Professional Tips

- **Real-Time Strategy**: Use DirectQuery or streaming datasets for true real-time dashboards - imported data introduces refresh latency

- **Query Optimization**: Always test query performance with production-scale data volumes before deploying to dashboards

- **Visual Hierarchy**: Design dashboards with key metrics at top, supporting details below - users scan top-to-bottom

- **Automation First**: Set up automated refresh and deployment from the start - retrofitting automation is time-consuming

- **Access Control**: Plan workspace and dashboard permissions carefully - use groups instead of individual users for easier management

### Troubleshooting

**Issue**: Dashboard not showing real-time data

```copilot-prompt
My Fabric dashboard is not updating in real time. Help me troubleshoot:

1. How to verify data source connection mode (DirectQuery vs Import)

2. How to check refresh schedule and trigger settings

3. How to test query execution time and identify bottlenecks

4. What are the limitations of real-time dashboards in Fabric?

Provide step-by-step diagnostic steps.

```

**Issue**: Slow dashboard performance with complex queries

- **Profile Queries**: Use query profiling tools to identify slow-running KQL or DAX queries

- **Add Aggregation**: Pre-aggregate data in Eventhouse tables or use materialized views to reduce query complexity

- **Limit Timeframes**: Restrict dashboard queries to recent time windows (last 24 hours) instead of all historical data

- **Cache Results**: Enable query result caching in Fabric for frequently accessed dashboards

**Issue**: Missing data or incomplete joins between sources

```copilot-prompt
My dashboard is missing data from some sources or showing incomplete joins.

1. How to verify all data sources are connected and accessible

2. How to test join logic in KQL or DAX with sample data

3. What are common join pitfalls in Fabric dashboards?

4. How to debug missing data in EventStream or Eventhouse?

```

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
[dax-reference]: https://learn.microsoft.com/dax/
[fabric-dashboards]: https://learn.microsoft.com/fabric/real-time-intelligence/dashboard-real-time-create
[kql-reference]: https://learn.microsoft.com/azure/data-explorer/kusto/query/
[powerbi-docs]: https://learn.microsoft.com/power-bi/

**Ready to practice?** 🏆 **Start with Essential Setup above**
