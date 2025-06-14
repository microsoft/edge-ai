---
title: Pull Request Analysis for edge-ai
description: Analysis of pull request activity and contributor statistics for the
  edge-ai project
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: hub-page
keywords:
  - pull request analysis
  - contributor statistics
  - development metrics
  - github copilot impact
  - pr trends
  - code review
  - development productivity
  - project analytics
  - slo compliance
  - terraform
  - bicep
  - infrastructure as code
  - edge ai
  - azure iot operations
estimated_reading_time: 20
---
<!-- markdownlint-disable MD033 -->

## Overview

This analysis covers pull request activity for the edge-ai project in the ai-at-the-edge-flagship-accelerator organization.

### Summary Statistics

- **Total Pull Requests**: 306
- **Completed**: 265 (86.6%)
- **Active**: 7 (2.3%)
- **Abandoned**: 34 (11.1%)
- **Average Days to Complete**: 2.91
- **Total Contributors**: 32

## Monthly Pull Request Activity

The following chart shows the trend of PRs created and completed each month.

``` mermaid

xychart-beta
    title "Monthly PR Activity Trends"
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#FF6384, #36A2EB"}}}}%%
    x-axis ["Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
    y-axis "Number of PRs"
    line "Created PRs" [18, 8, 60, 47, 56, 50, 53]
    line "Completed PRs" [15, 6, 52, 36, 53, 49, 44]
```

### PR Activity Chart Legend

| PR Type       | Color                                   |
|---------------|-----------------------------------------|
| Created PRs   | <span style='color:#FF6384'>■■■■</span> |
| Completed PRs | <span style='color:#36A2EB'>■■■■</span> |

## Weekly Completed Pull Requests

This chart shows PR completion trends by week (Monday-Friday work weeks).

``` mermaid

xychart-beta
    title "Weekly PR Completion Activity (Last 26 Weeks)"
    x-axis ["46", "47", "48", "49", "50", "51", "52", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21"]
    y-axis "Number of PRs"
    bar [8, 2, 2, 4, 0, 2, 0, 0, 7, 11, 16, 18, 11, 8, 7, 12, 10, 18, 12, 7, 16, 8, 3, 17, 11, 10, 11, 21]
```

## PR Completion Time by Size

The size of a PR significantly impacts how long it takes to review and merge.

``` mermaid

xychart-beta
    title "Average Days to Complete by PR Size"
    x-axis ["Small (≤5 files)", "Medium (6-20 files)", "Large (>20 files)"]
    y-axis "Days" 2 --> 4.9
    bar [2.7, 2.9, 3.9]
```

## PR Completion Time Distribution

``` mermaid

pie showData
    title "PR Completion Time Distribution"
    "Under 1 Day" : 116
    "1-3 Days" : 80
    "4-7 Days" : 45
    "Over 7 Days" : 24
```

## SLO Compliance Trend

The following chart shows the trend of SLO compliance percentage over time (48 hour response window) and the number of PRs closed each week:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4BC0C0, #FF6384"}}}}%%
xychart-beta
    title "Weekly SLO Compliance and PR Closure"
    x-axis ["41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21"]
    y-axis "Percentage" 0 --> 100
    line [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 90.9, 100, 100, 100, 93.3, 100, 88.9, 88.9, 100, 100, 87.5, 100, 100, 100, 93.3, 100, 95]
    bar [0, 19, 4.8, 23.8, 14.3, 38.1, 9.5, 9.5, 19, 0, 9.5, 33.3, 52.4, 76.2, 85.7, 52.4, 38.1, 33.3, 57.1, 47.6, 85.7, 57.1, 33.3, 76.2, 38.1, 14.3, 81, 52.4, 47.6, 52.4, 100]
```

### Chart Legend

| Metric           | Description                                                                   | Color                                   |
|------------------|-------------------------------------------------------------------------------|-----------------------------------------|
| SLO Compliance % | Percentage of PRs meeting the 48 hour response window                         | <span style='color:#4BC0C0'>■■■■</span> |
| PRs Closed       | Total number of PRs closed in each week (scaled to percentage of maximum: 21) | <span style='color:#FF6384'>■■■■</span> |

## GitHub Copilot Impact

The following chart shows PR complexity metrics over time:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4BC0C0, #FF6384, #36A2EB, #9966FF, #FFCE56"}}}}%%
xychart-beta
    title "PR Complexity and Contributors"
x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
y-axis "Value (scaled)" 0 --> 124
line "Avg Files Changed" [16.5, 27.6, 37.5, 65.8, 55.6, 52.1, 101.1, 66.4]
line "Avg Days to Complete" [100, 68.2, 62.5, 86.5, 95.2, 60.8, 97.5, 62.5]
line "Avg Files/Day" [12.3, 30.3, 45, 57.2, 43.8, 64.2, 77.9, 79.6]
line "Avg Lines/Day" [5.8, 100, 50.9, 47.5, 33.1, 74.7, 106.3, 111.3]
line "Total Contributors" [16, 32, 24, 80, 80, 112, 96, 96]
```

### PR Complexity Chart Legend

| Metric                                                       | Description                                                     | Actual Value Range   | Scaling Factor |
|--------------------------------------------------------------|-----------------------------------------------------------------|----------------------|----------------|
| <span style='color:#4BC0C0'>■■■■</span> Avg Files Changed    | Average number of files modified per PR                         | 3.3-20.2 files       | ×5             |
| <span style='color:#FF6384'>■■■■</span> Avg Days to Complete | Average time (in days) taken to complete PRs                    | 2.4-4 days           | ×25            |
| <span style='color:#36A2EB'>■■■■</span> Avg Files/Day        | Productivity metric (files changed divided by days to complete) | 0.8-5.3 files/day    | ×15            |
| <span style='color:#9966FF'>■■■■</span> Avg Lines/Day        | Productivity metric (lines changed divided by days to complete) | 14.4-278.4 lines/day | ×0.4           |
| <span style='color:#FFCE56'>■■■■</span> Total Contributors   | Count of unique contributors (new + returning) per month        | 2-14 contributors    | ×8             |

*Note: Scaling factors are applied to make different metrics comparable on the same chart.*

The following metrics show GitHub Copilot's impact on development productivity:

### Copilot Impact Metrics (% Change)

| Metric                | Before Copilot | After Copilot | % Change |
|-----------------------|----------------|---------------|----------|
| Files Changed per PR  | 10.4           | 14.5          | 38.5%    |
| Lines Changed per PR  | 389.9          | 705.2         | 80.9%    |
| Days to Complete PR   | 3.4            | 2.6           | -24.3%   |
| Files Changed per Day | 3.5            | 4.8           | 39.4%    |

**Note**: GitHub Copilot was introduced on February 25, 2025. PR completion time has decreased by 24.3% since Copilot adoption, while developer productivity (measured by files changed per day) has increased by 39.4%.

## Contributor Summary

Over the past 3 months:

- **Total Unique Contributors**: 31
- **New Contributors**: 13 (29.5%)
- **Returning Contributors**: 31 (70.5%)
- **Total Unique Reviewers**: 24

### Contributors

<!-- cspell:disable -->
| Contributor               | PRs | Files Changed | Lines Added | Lines Deleted | Work Items Closed |
|---------------------------|-----|---------------|-------------|---------------|-------------------|
| Alain Uyidi               | 4   | 4             | 141         | 15            | 4                 |
| Allen Greaves             | 41  | 1327          | 32909       | 15204         | 42                |
| Andrej Kyselica           | 2   | 4             | 49          | 9             | 1                 |
| Andrew Malkov             | 1   | 2             | 1390        | 0             | 1                 |
| Andrew Nguyen             | 2   | 24            | 1223        | 8             | 2                 |
| Audrey Olson              | 2   | 10            | 708         | 7             | 2                 |
| Basia Mahoney             | 1   | 1             | 1           | 1             | 1                 |
| Bill Berry                | 106 | 594           | 36660       | 8739          | 186               |
| Braden Eriksen            | 1   | 3             | 126         | 38            | 1                 |
| Cheng Chen                | 2   | 3             | 307         | 0             | 2                 |
| Dariusz Porowski          | 2   | 15            | 21          | 21            | 2                 |
| Efrat Lecker              | 1   | 1             | 7           | 0             | 1                 |
| Eliise Seling             | 14  | 374           | 6170        | 3855          | 22                |
| Eugene Fedorenko          | 6   | 11            | 599         | 6             | 6                 |
| Jeffrey Feng              | 5   | 14            | 6095        | 4             | 4                 |
| Joshua Phelps             | 2   | 17            | 1575        | 3             | 2                 |
| Katrien De Graeve         | 40  | 418           | 14684       | 3360          | 56                |
| Lauren Luttrell (SHE HER) | 1   | 1             | 7           | 7             | 1                 |
| Lee Cattarin              | 3   | 6             | 285         | 20            | 3                 |
| Liam Moat                 | 1   | 2             | 13          | 13            | 2                 |
| Madhav Annamraju          | 3   | 7             | 1672        | 0             | 3                 |
| Marcel Bindseil           | 29  | 301           | 6294        | 618           | 35                |
| Michael Brown (ISE)       | 10  | 85            | 1847        | 153           | 10                |
| Mykhailo Skuba            | 1   | 2             | 42          | 3             | 1                 |
| Olha Konstantinova        | 1   | 19            | 703         | 11            | 1                 |
| Omer Demir                | 2   | 6             | 360         | 6             | 2                 |
| Paul Bouwer               | 3   | 7             | 172         | 24            | 3                 |
| Rahul Dani                | 2   | 32            | 1040        | 55            | 2                 |
| Suneet Nangia             | 3   | 2             | 359         | 0             | 3                 |
| Vy Ta                     | 3   | 31            | 1469        | 20            | 8                 |

## Reviewers

| Reviewer            | Approvals | Comments |
|---------------------|-----------|----------|
| Alain Uyidi         | 23        | 42       |
| Allen Greaves       | 137       | 408      |
| Basia Mahoney       | 1         | 2        |
| Bill Berry          | 139       | 524      |
| Braden Eriksen      | 2         | 15       |
| Cheng Chen          | 3         | 13       |
| Daisuke Inoue       | 1         | 6        |
| Dariusz Porowski    | 1         | 8        |
| Eliise Seling       | 52        | 87       |
| Emmeline Hoops      | 2         | 22       |
| Engin Polat         | 1         | 11       |
| Eugene Fedorenko    | 1         | 2        |
| Katrien De Graeve   | 101       | 246      |
| Larry Lieberman     | 44        | 5        |
| Madhav Annamraju    | 1         | 16       |
| Marcel Bindseil     | 43        | 65       |
| Marcia Dos Santos   | 1         | 10       |
| Michael Brown (ISE) | 12        | 10       |
| Olha Konstantinova  | 1         | 6        |
| Paul Bouwer         | 3         | 7        |
| Rahul Dani          | 4         | 2        |
| Rajasa Savant (RJ)  | 1         | 2        |
| Suneet Nangia       | 2         | 4        |
| Vy Ta               | 11        | 19       |
<!-- cspell:enable -->
## Contributor Trends

The contributor retention rate (returning vs. new) suggests a growing, but potentially less stable contributor base.

This chart shows the pattern of new vs. returning contributors over time:

``` mermaid

xychart-beta
    title "Contributor Trends: New vs. Returning"
    x-axis ["Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
    y-axis "Number of Contributors"
    line [3, 1, 8, 5, 6, 3, 4]
    line [3, 4, 8, 7, 10, 8, 13]
```

### Contributor Chart Legend

| Contributor Type       | Color                                   |
|------------------------|-----------------------------------------|
| New Contributors       | <span style='color:#4287f5'>■■■■</span> |
| Returning Contributors | <span style='color:#42f5a7'>■■■■</span> |

## File Types

| File Type                | Current Branch Files | % of Files | PR Changes Count | % of Changes |
|--------------------------|----------------------|------------|------------------|--------------|
| Terraform                | 330                  | 36.9%      | 1669             | 38.9%        |
| Documentation (Markdown) | 239                  | 26.7%      | 1311             | 30.5%        |
| Bicep/ARM Templates      | 82                   | 9.2%       | 508              | 11.8%        |
| YAML                     | 58                   | 6.5%       | 371              | 8.6%         |
| Shell Scripts            | 36                   | 4.0%       | 185              | 4.3%         |
| Other                    | 91                   | 10.2%      | 159              | 3.7%         |
| PowerShell               | 19                   | 2.1%       | 58               | 1.4%         |
| Python                   | 4                    | 0.4%       | 16               | 0.4%         |
| C#                       | 11                   | 1.2%       | 11               | 0.3%         |
| Rust                     | 4                    | 0.4%       | 4                | 0.1%         |
| Configuration Files      | 1                    | 0.1%       | 0                | 0.0%         |
| Docker                   | 3                    | 0.3%       | 0                | 0.0%         |
| JSON                     | 16                   | 1.8%       | 0                | 0.0%         |
| **Total**                | **894**              | **100%**   | **4292**         | **100%**     |

## Focus Area Trends

The xy-chart below tracks how development focus areas have evolved over time in the project:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#9966FF, #FF6384, #36A2EB, #4BC0C0, #FF9F40, #326CE5, #8B8000"}}}}%%
xychart-beta
    title "Focus Area Trends Over Time (% of monthly PRs)"
    x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
    y-axis "Percentage of PRs (log scale)" 1 --> 100
        line "Features" [35.7, 72.2, 75, 51.7, 42.6, 53.6, 70, 79.2]     line "CI/CD" [7.1, 50, 50, 31.7, 40.4, 46.4, 38, 43.4]     line "Documentation" [28.6, 16.7, 25, 40, 27.7, 42.9, 52, 47.2]     line "Bug Fixes" [28.6, 33.3, 50, 36.7, 21.3, 44.6, 34, 18.9]     line "Terraform" [0.1, 22.2, 25, 15, 14.9, 21.4, 16, 41.5]     line "Kubernetes" [7.1, 16.7, 25, 11.7, 10.6, 17.9, 10, 20.8]     line "Refactoring" [14.3, 5.6, 12.5, 13.3, 8.5, 10.7, 18, 26.4]
```

### Focus Area Chart Legend

| Focus Area    | Color                                   | Focus Area  | Color                                   |
|---------------|-----------------------------------------|-------------|-----------------------------------------|
| Features      | <span style='color:#9966FF'>■■■■</span> | Terraform   | <span style='color:#FF9F40'>■■■■</span> |
| CI/CD         | <span style='color:#FF6384'>■■■■</span> | Kubernetes  | <span style='color:#326CE5'>■■■■</span> |
| Documentation | <span style='color:#36A2EB'>■■■■</span> | Refactoring | <span style='color:#8B8000'>■■■■</span> |
| Bug Fixes     | <span style='color:#4BC0C0'>■■■■</span> |             |                                         |

## Industry Backlog Visualization

The following Sankey diagrams visualize the flow from scenarios through capabilities to specific backlog features, segmented by scenario priority.

The line weights in these diagrams are calculated as follows:

- **Scenario to Capability**: The weight of a link from a Scenario to a Capability represents the total number of customers for that Scenario. This weighting is determined by the number of distinct customer tags associated with the Scenario.
- **Capability to Feature**: The weight of a link from a Capability to a Feature represents the sum of all incoming link weights to that Capability from its connected Scenarios. This effectively shows the aggregated customer demand flowing through the Capability to its Features.

### Top 5 Scenarios (by Customer Weighting)

Scenarios are weighted by the number of industry customers requiring them. This chart shows the top 5 scenarios.

Scenario -> Capability -> Implementation/Feature

``` mermaid

---
config:
  sankey:
    showValues: false
    width: 1200
    height: 1400 # Consider making height dynamic or adjusting per chart
---
sankey-beta
%% Top 5 Scenarios (by Customer Weighting) - Mermaid does not render title for sankey-beta directly in diagram
"Predictive Maintenance","VM Host Infrastructure",8
"Operational Performance Monitoring","Cloud Container Platform Infrastructure",8
"Predictive Maintenance","Cloud Container Platform Infrastructure",8
"Yield Process Optimization","Cloud Container Platform Infrastructure",6
"Digital Inspection / Survey","Cloud Data Platform",7
"Operational Performance Monitoring","Cloud Data Platform",8
"Predictive Maintenance","Cloud Data Platform",8
"Quality Process Optimization & Automation","Cloud Data Platform",7
"Yield Process Optimization","Cloud Data Platform",6
"Digital Inspection / Survey","Cloud Identity Management",7
"Operational Performance Monitoring","Cloud Identity Management",8
"Predictive Maintenance","Cloud Identity Management",8
"Quality Process Optimization & Automation","Cloud Identity Management",7
"Yield Process Optimization","Cloud Identity Management",6
"Digital Inspection / Survey","Cloud Messaging and Event Infrastructure",7
"Operational Performance Monitoring","Cloud Messaging and Event Infrastructure",8
"Predictive Maintenance","Cloud Messaging and Event Infrastructure",8
"Quality Process Optimization & Automation","Cloud Messaging and Event Infrastructure",7
"Yield Process Optimization","Cloud Messaging and Event Infrastructure",6
"Digital Inspection / Survey","Cloud Observability Foundation",7
"Operational Performance Monitoring","Cloud Observability Foundation",8
"Predictive Maintenance","Cloud Observability Foundation",8
"Quality Process Optimization & Automation","Cloud Observability Foundation",7
"Yield Process Optimization","Cloud Observability Foundation",6
"Digital Inspection / Survey","Cloud Secret and Certificate Management",7
"Operational Performance Monitoring","Cloud Secret and Certificate Management",8
"Predictive Maintenance","Cloud Secret and Certificate Management",8
"Quality Process Optimization & Automation","Cloud Secret and Certificate Management",7
"Yield Process Optimization","Cloud Secret and Certificate Management",6
"Digital Inspection / Survey","Edge Camera Control",7
"Operational Performance Monitoring","Edge Camera Control",8
"Predictive Maintenance","Edge Camera Control",8
"Quality Process Optimization & Automation","Edge Camera Control",7
"Digital Inspection / Survey","Edge Compute Orchestration Platform",7
"Operational Performance Monitoring","Edge Compute Orchestration Platform",8
"Predictive Maintenance","Edge Compute Orchestration Platform",8
"Yield Process Optimization","Edge Compute Orchestration Platform",6
"Digital Inspection / Survey","Edge Dashboard Visualization",7
"Operational Performance Monitoring","Edge Dashboard Visualization",8
"Predictive Maintenance","Edge Dashboard Visualization",8
"Quality Process Optimization & Automation","Edge Dashboard Visualization",7
"Yield Process Optimization","Edge Dashboard Visualization",6
"Digital Inspection / Survey","Edge Inferencing Application Framework",7
"Operational Performance Monitoring","Edge Inferencing Application Framework",8
"Predictive Maintenance","Edge Inferencing Application Framework",8
"Quality Process Optimization & Automation","Edge Inferencing Application Framework",7
"Yield Process Optimization","Edge Inferencing Application Framework",6
"Quality Process Optimization & Automation","OCP UA Closed-Loop Control",7
"Yield Process Optimization","OCP UA Closed-Loop Control",6
"Operational Performance Monitoring","OPC UA Data Ingestion",8
"Predictive Maintenance","OPC UA Data Ingestion",8
"Quality Process Optimization & Automation","OPC UA Data Ingestion",7
"Yield Process Optimization","OPC UA Data Ingestion",6
"Digital Inspection / Survey","Resource Group Management",7
"Operational Performance Monitoring","Resource Group Management",8
"Predictive Maintenance","Resource Group Management",8
"Quality Process Optimization & Automation","Resource Group Management",7
"Yield Process Optimization","Resource Group Management",6
"Digital Inspection / Survey","Stamp Architecture Deployment",7
"Operational Performance Monitoring","Stamp Architecture Deployment",8
"Predictive Maintenance","Stamp Architecture Deployment",8
"Quality Process Optimization & Automation","Stamp Architecture Deployment",7
"Yield Process Optimization","Stamp Architecture Deployment",6
"VM Host Infrastructure","Cloud Virtual Machine Host(s) (050-vm-host)",10
"Cloud Container Platform Infrastructure","Cloud AKS Cluster and ACR (060-aks-acr)",9
"OCP UA Closed-Loop Control","Cloud AKS Cluster and ACR (060-aks-acr)",9
"Cloud Data Platform","Cloud Data Persistence (030-data)",33
"Cloud Messaging and Event Infrastructure","Edge Messaging & Data Routing (130-messaging)",33
"OPC UA Data Ingestion","Edge Messaging & Data Routing (130-messaging)",11
"Cloud Data Platform","Edge Messaging & Data Routing (130-messaging)",33
"Edge Compute Orchestration Platform","Cloud Security and Identity (010-security-identity)",26
"Cloud Secret and Certificate Management","Cloud Security and Identity (010-security-identity)",33
"Cloud Identity Management","Cloud Security and Identity (010-security-identity)",33
"Cloud Messaging and Event Infrastructure","Cloud Messaging (040-messaging)",33
"Cloud Observability Foundation","Cloud Observability (020-observability)",33
"Edge Dashboard Visualization","Cloud Observability (020-observability)",33
"OPC UA Data Ingestion","Edge Observability (120-observability)",11
"Edge Compute Orchestration Platform","Edge Observability (120-observability)",26
"Edge Dashboard Visualization","Edge Observability (120-observability)",33
"Cloud Observability Foundation","Edge Observability (120-observability)",33
"Cloud Secret and Certificate Management","Edge CNCF Cluster Setup & Arc Onboarding (100-cncf-cluster)",33
"OCP UA Closed-Loop Control","Edge CNCF Cluster Setup & Arc Onboarding (100-cncf-cluster)",9
"Edge Camera Control","RTSP Camera Stream Management",12
"Edge Camera Control","ONVIF Camera Control",12
"OCP UA Closed-Loop Control","Edge Azure IoT Operations Core (110-iot-ops)",9
"OPC UA Data Ingestion","Edge Azure IoT Operations Core (110-iot-ops)",11
"Edge Compute Orchestration Platform","Edge Azure IoT Operations Core (110-iot-ops)",26
"Edge Inferencing Application Framework","Inference Pipeline Application (500-basic-inference)",20
"Resource Group Management","Comprehensive resource tagging solutions",33
"Resource Group Management","Cloud Azure Resource Group (000-resource-group)",33
"Stamp Architecture Deployment","Industry Solution Blueprints Framework",33
"Stamp Architecture Deployment","Integration Environment for IaC Upgrade Testing",33
"Stamp Architecture Deployment","Ephemeral Environment Testing for Blueprints",33
```

### Other Scenarios (Customer Weighting >= 2, Excluding Top 5)

This chart shows other scenarios that have a customer use weighting of 1 or more, excluding the top 5.

Scenario -> Capability -> Implementation/Feature

``` mermaid

---
config:
  sankey:
    showValues: false
    width: 1200
    height: 1400 # Consider making height dynamic or adjusting per chart
---
sankey-beta
%% Other Scenarios (Customer Weighting >= 2, Excluding Top 5) - Mermaid does not render title for sankey-beta directly in diagram
"Automated Quality Diagnostics & Simulation","VM Host Infrastructure",4
"Facility Design & Simulation","VM Host Infrastructure",3
"Immersive Remote Operations","VM Host Infrastructure",5
"Semi-Autonomous Cell","VM Host Infrastructure",2
"Automated Quality Diagnostics & Simulation","Cloud Container Platform Infrastructure",4
"Autonomous Cell","Cloud Container Platform Infrastructure",2
"Facility Design & Simulation","Cloud Container Platform Infrastructure",3
"Immersive Remote Operations","Cloud Container Platform Infrastructure",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Container Platform Infrastructure",7
"Semi-Autonomous Cell","Cloud Container Platform Infrastructure",2
"Automated Quality Diagnostics & Simulation","Cloud Data Platform",4
"Autonomous Cell","Cloud Data Platform",2
"End-to-end Material Handling","Cloud Data Platform",2
"Enhanced Personal Safety","Cloud Data Platform",3
"Facility Design & Simulation","Cloud Data Platform",3
"Immersive Remote Operations","Cloud Data Platform",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Data Platform",7
"Inventory Optimization","Cloud Data Platform",3
"Logistics Optimization & Automation","Cloud Data Platform",2
"Packaging Line Performance Optimization","Cloud Data Platform",3
"Semi-Autonomous Cell","Cloud Data Platform",2
"Automated Quality Diagnostics & Simulation","Cloud Identity Management",4
"Autonomous Cell","Cloud Identity Management",2
"End-to-end Material Handling","Cloud Identity Management",2
"Enhanced Personal Safety","Cloud Identity Management",3
"Facility Design & Simulation","Cloud Identity Management",3
"Immersive Remote Operations","Cloud Identity Management",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Identity Management",7
"Inventory Optimization","Cloud Identity Management",3
"Logistics Optimization & Automation","Cloud Identity Management",2
"Packaging Line Performance Optimization","Cloud Identity Management",3
"Semi-Autonomous Cell","Cloud Identity Management",2
"Automated Quality Diagnostics & Simulation","Cloud Messaging and Event Infrastructure",4
"Autonomous Cell","Cloud Messaging and Event Infrastructure",2
"End-to-end Material Handling","Cloud Messaging and Event Infrastructure",2
"Enhanced Personal Safety","Cloud Messaging and Event Infrastructure",3
"Facility Design & Simulation","Cloud Messaging and Event Infrastructure",3
"Immersive Remote Operations","Cloud Messaging and Event Infrastructure",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Messaging and Event Infrastructure",7
"Inventory Optimization","Cloud Messaging and Event Infrastructure",3
"Logistics Optimization & Automation","Cloud Messaging and Event Infrastructure",2
"Packaging Line Performance Optimization","Cloud Messaging and Event Infrastructure",3
"Semi-Autonomous Cell","Cloud Messaging and Event Infrastructure",2
"Automated Quality Diagnostics & Simulation","Cloud Observability Foundation",4
"Autonomous Cell","Cloud Observability Foundation",2
"End-to-end Material Handling","Cloud Observability Foundation",2
"Enhanced Personal Safety","Cloud Observability Foundation",3
"Facility Design & Simulation","Cloud Observability Foundation",3
"Immersive Remote Operations","Cloud Observability Foundation",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Observability Foundation",7
"Inventory Optimization","Cloud Observability Foundation",3
"Logistics Optimization & Automation","Cloud Observability Foundation",2
"Packaging Line Performance Optimization","Cloud Observability Foundation",3
"Semi-Autonomous Cell","Cloud Observability Foundation",2
"Automated Quality Diagnostics & Simulation","Cloud Secret and Certificate Management",4
"Autonomous Cell","Cloud Secret and Certificate Management",2
"End-to-end Material Handling","Cloud Secret and Certificate Management",2
"Enhanced Personal Safety","Cloud Secret and Certificate Management",3
"Facility Design & Simulation","Cloud Secret and Certificate Management",3
"Immersive Remote Operations","Cloud Secret and Certificate Management",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Secret and Certificate Management",7
"Inventory Optimization","Cloud Secret and Certificate Management",3
"Logistics Optimization & Automation","Cloud Secret and Certificate Management",2
"Packaging Line Performance Optimization","Cloud Secret and Certificate Management",3
"Semi-Autonomous Cell","Cloud Secret and Certificate Management",2
"Autonomous Cell","Constrained Edge Device",2
"Semi-Autonomous Cell","Constrained Edge Device",2
"Automated Quality Diagnostics & Simulation","Edge Camera Control",4
"Autonomous Cell","Edge Camera Control",2
"End-to-end Material Handling","Edge Camera Control",2
"Enhanced Personal Safety","Edge Camera Control",3
"Immersive Remote Operations","Edge Camera Control",5
"Semi-Autonomous Cell","Edge Camera Control",2
"Autonomous Cell","Edge Compute Orchestration Platform",2
"End-to-end Material Handling","Edge Compute Orchestration Platform",2
"Enhanced Personal Safety","Edge Compute Orchestration Platform",3
"Immersive Remote Operations","Edge Compute Orchestration Platform",5
"Inventory Optimization","Edge Compute Orchestration Platform",3
"Logistics Optimization & Automation","Edge Compute Orchestration Platform",2
"Semi-Autonomous Cell","Edge Compute Orchestration Platform",2
"Automated Quality Diagnostics & Simulation","Edge Dashboard Visualization",4
"Autonomous Cell","Edge Dashboard Visualization",2
"End-to-end Material Handling","Edge Dashboard Visualization",2
"Enhanced Personal Safety","Edge Dashboard Visualization",3
"Facility Design & Simulation","Edge Dashboard Visualization",3
"Immersive Remote Operations","Edge Dashboard Visualization",5
"Intelligent Assistant (CoPilot/Companion)","Edge Dashboard Visualization",7
"Inventory Optimization","Edge Dashboard Visualization",3
"Logistics Optimization & Automation","Edge Dashboard Visualization",2
"Packaging Line Performance Optimization","Edge Dashboard Visualization",3
"Semi-Autonomous Cell","Edge Dashboard Visualization",2
"Automated Quality Diagnostics & Simulation","Edge Inferencing Application Framework",4
"Autonomous Cell","Edge Inferencing Application Framework",2
"End-to-end Material Handling","Edge Inferencing Application Framework",2
"Enhanced Personal Safety","Edge Inferencing Application Framework",3
"Intelligent Assistant (CoPilot/Companion)","Edge Inferencing Application Framework",7
"Inventory Optimization","Edge Inferencing Application Framework",3
"Packaging Line Performance Optimization","Edge Inferencing Application Framework",3
"Semi-Autonomous Cell","Edge Inferencing Application Framework",2
"Autonomous Cell","OCP UA Closed-Loop Control",2
"Packaging Line Performance Optimization","OCP UA Closed-Loop Control",3
"Semi-Autonomous Cell","OCP UA Closed-Loop Control",2
"Automated Quality Diagnostics & Simulation","OPC UA Data Ingestion",4
"Autonomous Cell","OPC UA Data Ingestion",2
"Packaging Line Performance Optimization","OPC UA Data Ingestion",3
"Semi-Autonomous Cell","OPC UA Data Ingestion",2
"Automated Quality Diagnostics & Simulation","Resource Group Management",4
"Autonomous Cell","Resource Group Management",2
"End-to-end Material Handling","Resource Group Management",2
"Enhanced Personal Safety","Resource Group Management",3
"Facility Design & Simulation","Resource Group Management",3
"Immersive Remote Operations","Resource Group Management",5
"Intelligent Assistant (CoPilot/Companion)","Resource Group Management",7
"Inventory Optimization","Resource Group Management",3
"Logistics Optimization & Automation","Resource Group Management",2
"Packaging Line Performance Optimization","Resource Group Management",3
"Semi-Autonomous Cell","Resource Group Management",2
"Automated Quality Diagnostics & Simulation","Stamp Architecture Deployment",4
"Autonomous Cell","Stamp Architecture Deployment",2
"End-to-end Material Handling","Stamp Architecture Deployment",2
"Enhanced Personal Safety","Stamp Architecture Deployment",3
"Facility Design & Simulation","Stamp Architecture Deployment",3
"Immersive Remote Operations","Stamp Architecture Deployment",5
"Intelligent Assistant (CoPilot/Companion)","Stamp Architecture Deployment",7
"Inventory Optimization","Stamp Architecture Deployment",3
"Logistics Optimization & Automation","Stamp Architecture Deployment",2
"Packaging Line Performance Optimization","Stamp Architecture Deployment",3
"Semi-Autonomous Cell","Stamp Architecture Deployment",2
"VM Host Infrastructure","Cloud Virtual Machine Host(s) (050-vm-host)",10
"Cloud Container Platform Infrastructure","Cloud AKS Cluster and ACR (060-aks-acr)",9
"OCP UA Closed-Loop Control","Cloud AKS Cluster and ACR (060-aks-acr)",9
"Cloud Data Platform","Cloud Data Persistence (030-data)",33
"Cloud Messaging and Event Infrastructure","Edge Messaging & Data Routing (130-messaging)",33
"OPC UA Data Ingestion","Edge Messaging & Data Routing (130-messaging)",11
"Cloud Data Platform","Edge Messaging & Data Routing (130-messaging)",33
"Edge Compute Orchestration Platform","Cloud Security and Identity (010-security-identity)",26
"Cloud Secret and Certificate Management","Cloud Security and Identity (010-security-identity)",33
"Cloud Identity Management","Cloud Security and Identity (010-security-identity)",33
"Cloud Messaging and Event Infrastructure","Cloud Messaging (040-messaging)",33
"Cloud Observability Foundation","Cloud Observability (020-observability)",33
"Edge Dashboard Visualization","Cloud Observability (020-observability)",33
"OPC UA Data Ingestion","Edge Observability (120-observability)",11
"Edge Compute Orchestration Platform","Edge Observability (120-observability)",26
"Edge Dashboard Visualization","Edge Observability (120-observability)",33
"Cloud Observability Foundation","Edge Observability (120-observability)",33
"Cloud Secret and Certificate Management","Edge CNCF Cluster Setup & Arc Onboarding (100-cncf-cluster)",33
"OCP UA Closed-Loop Control","Edge CNCF Cluster Setup & Arc Onboarding (100-cncf-cluster)",9
"Edge Camera Control","RTSP Camera Stream Management",12
"Edge Camera Control","ONVIF Camera Control",12
"OCP UA Closed-Loop Control","Edge Azure IoT Operations Core (110-iot-ops)",9
"OPC UA Data Ingestion","Edge Azure IoT Operations Core (110-iot-ops)",11
"Edge Compute Orchestration Platform","Edge Azure IoT Operations Core (110-iot-ops)",26
"Edge Inferencing Application Framework","Inference Pipeline Application (500-basic-inference)",20
"Resource Group Management","Comprehensive resource tagging solutions",33
"Resource Group Management","Cloud Azure Resource Group (000-resource-group)",33
"Stamp Architecture Deployment","Industry Solution Blueprints Framework",33
"Stamp Architecture Deployment","Integration Environment for IaC Upgrade Testing",33
"Stamp Architecture Deployment","Ephemeral Environment Testing for Blueprints",33
```

### Scenarios with No Direct Customer Weighting (Value <= 1)

This chart shows scenarios with no direct customer use weighting (value of 0), and all their related capabilities and features.

Scenario -> Capability -> Implementation/Feature

``` mermaid

---
config:
  sankey:
    showValues: false
    width: 1200
    height: 1400 # Consider making height dynamic or adjusting per chart
---
sankey-beta
%% Scenarios with No Direct Customer Weighting (Value <= 1) - Mermaid does not render title for sankey-beta directly in diagram
"Automated Formula Management","VM Host Infrastructure",0
"Integrated Maintenance/Work Orders","VM Host Infrastructure",1
"Product Innovation","VM Host Infrastructure",0
"Product Lifecycle Simulation","VM Host Infrastructure",0
"Virtual Training","VM Host Infrastructure",0
"Automated Formula Management","Cloud Data Platform",0
"Automated Product Design","Cloud Data Platform",0
"Autonomous Material Movement","Cloud Data Platform",0
"Changeover & Cycle Time Optimization","Cloud Data Platform",1
"Compressed Air Optimization","Cloud Data Platform",0
"Connected Consumer Insights","Cloud Data Platform",1
"Ecosystem Decision Support","Cloud Data Platform",1
"Ecosystem Orchestration","Cloud Data Platform",0
"End-to-end Batch Planning and Optimization","Cloud Data Platform",0
"Integrated Maintenance/Work Orders","Cloud Data Platform",1
"Product Innovation","Cloud Data Platform",0
"Product Lifecycle Simulation","Cloud Data Platform",0
"Virtual Training","Cloud Data Platform",0
"Waste Circular Economy","Cloud Data Platform",0
"Water Usage Optimization","Cloud Data Platform",1
"Automated Formula Management","Cloud Identity Management",0
"Automated Product Design","Cloud Identity Management",0
"Autonomous Material Movement","Cloud Identity Management",0
"Changeover & Cycle Time Optimization","Cloud Identity Management",1
"Compressed Air Optimization","Cloud Identity Management",0
"Connected Consumer Insights","Cloud Identity Management",1
"Ecosystem Decision Support","Cloud Identity Management",1
"Ecosystem Orchestration","Cloud Identity Management",0
"End-to-end Batch Planning and Optimization","Cloud Identity Management",0
"Integrated Maintenance/Work Orders","Cloud Identity Management",1
"Product Innovation","Cloud Identity Management",0
"Product Lifecycle Simulation","Cloud Identity Management",0
"Virtual Training","Cloud Identity Management",0
"Waste Circular Economy","Cloud Identity Management",0
"Water Usage Optimization","Cloud Identity Management",1
"Automated Formula Management","Cloud Messaging and Event Infrastructure",0
"Automated Product Design","Cloud Messaging and Event Infrastructure",0
"Autonomous Material Movement","Cloud Messaging and Event Infrastructure",0
"Changeover & Cycle Time Optimization","Cloud Messaging and Event Infrastructure",1
"Compressed Air Optimization","Cloud Messaging and Event Infrastructure",0
"Connected Consumer Insights","Cloud Messaging and Event Infrastructure",1
"Ecosystem Decision Support","Cloud Messaging and Event Infrastructure",1
"Ecosystem Orchestration","Cloud Messaging and Event Infrastructure",0
"End-to-end Batch Planning and Optimization","Cloud Messaging and Event Infrastructure",0
"Integrated Maintenance/Work Orders","Cloud Messaging and Event Infrastructure",1
"Product Innovation","Cloud Messaging and Event Infrastructure",0
"Product Lifecycle Simulation","Cloud Messaging and Event Infrastructure",0
"Virtual Training","Cloud Messaging and Event Infrastructure",0
"Waste Circular Economy","Cloud Messaging and Event Infrastructure",0
"Water Usage Optimization","Cloud Messaging and Event Infrastructure",1
"Automated Formula Management","Cloud Observability Foundation",0
"Automated Product Design","Cloud Observability Foundation",0
"Autonomous Material Movement","Cloud Observability Foundation",0
"Changeover & Cycle Time Optimization","Cloud Observability Foundation",1
"Compressed Air Optimization","Cloud Observability Foundation",0
"Connected Consumer Insights","Cloud Observability Foundation",1
"Ecosystem Decision Support","Cloud Observability Foundation",1
"Ecosystem Orchestration","Cloud Observability Foundation",0
"End-to-end Batch Planning and Optimization","Cloud Observability Foundation",0
"Integrated Maintenance/Work Orders","Cloud Observability Foundation",1
"Product Innovation","Cloud Observability Foundation",0
"Product Lifecycle Simulation","Cloud Observability Foundation",0
"Virtual Training","Cloud Observability Foundation",0
"Waste Circular Economy","Cloud Observability Foundation",0
"Water Usage Optimization","Cloud Observability Foundation",1
"Automated Formula Management","Cloud Secret and Certificate Management",0
"Automated Product Design","Cloud Secret and Certificate Management",0
"Autonomous Material Movement","Cloud Secret and Certificate Management",0
"Changeover & Cycle Time Optimization","Cloud Secret and Certificate Management",1
"Compressed Air Optimization","Cloud Secret and Certificate Management",0
"Connected Consumer Insights","Cloud Secret and Certificate Management",1
"Ecosystem Decision Support","Cloud Secret and Certificate Management",1
"Ecosystem Orchestration","Cloud Secret and Certificate Management",0
"End-to-end Batch Planning and Optimization","Cloud Secret and Certificate Management",0
"Integrated Maintenance/Work Orders","Cloud Secret and Certificate Management",1
"Product Innovation","Cloud Secret and Certificate Management",0
"Product Lifecycle Simulation","Cloud Secret and Certificate Management",0
"Virtual Training","Cloud Secret and Certificate Management",0
"Waste Circular Economy","Cloud Secret and Certificate Management",0
"Water Usage Optimization","Cloud Secret and Certificate Management",1
"Product Innovation","Constrained Edge Device",0
"Integrated Maintenance/Work Orders","Edge Camera Control",1
"Automated Formula Management","Edge Compute Orchestration Platform",0
"Autonomous Material Movement","Edge Compute Orchestration Platform",0
"Compressed Air Optimization","Edge Compute Orchestration Platform",0
"Ecosystem Decision Support","Edge Compute Orchestration Platform",1
"Ecosystem Orchestration","Edge Compute Orchestration Platform",0
"Integrated Maintenance/Work Orders","Edge Compute Orchestration Platform",1
"Waste Circular Economy","Edge Compute Orchestration Platform",0
"Water Usage Optimization","Edge Compute Orchestration Platform",1
"Automated Formula Management","Edge Dashboard Visualization",0
"Automated Product Design","Edge Dashboard Visualization",0
"Autonomous Material Movement","Edge Dashboard Visualization",0
"Changeover & Cycle Time Optimization","Edge Dashboard Visualization",1
"Compressed Air Optimization","Edge Dashboard Visualization",0
"Connected Consumer Insights","Edge Dashboard Visualization",1
"Ecosystem Decision Support","Edge Dashboard Visualization",1
"Ecosystem Orchestration","Edge Dashboard Visualization",0
"End-to-end Batch Planning and Optimization","Edge Dashboard Visualization",0
"Integrated Maintenance/Work Orders","Edge Dashboard Visualization",1
"Product Innovation","Edge Dashboard Visualization",0
"Product Lifecycle Simulation","Edge Dashboard Visualization",0
"Virtual Training","Edge Dashboard Visualization",0
"Waste Circular Economy","Edge Dashboard Visualization",0
"Water Usage Optimization","Edge Dashboard Visualization",1
"Automated Formula Management","Edge Inferencing Application Framework",0
"Autonomous Material Movement","Edge Inferencing Application Framework",0
"Changeover & Cycle Time Optimization","Edge Inferencing Application Framework",1
"Compressed Air Optimization","Edge Inferencing Application Framework",0
"End-to-end Batch Planning and Optimization","Edge Inferencing Application Framework",0
"Water Usage Optimization","Edge Inferencing Application Framework",1
"Changeover & Cycle Time Optimization","OCP UA Closed-Loop Control",1
"Waste Circular Economy","OCP UA Closed-Loop Control",0
"Water Usage Optimization","OCP UA Closed-Loop Control",1
"Changeover & Cycle Time Optimization","OPC UA Data Ingestion",1
"Integrated Maintenance/Work Orders","OPC UA Data Ingestion",1
"Automated Formula Management","Resource Group Management",0
"Automated Product Design","Resource Group Management",0
"Autonomous Material Movement","Resource Group Management",0
"Changeover & Cycle Time Optimization","Resource Group Management",1
"Compressed Air Optimization","Resource Group Management",0
"Connected Consumer Insights","Resource Group Management",1
"Ecosystem Decision Support","Resource Group Management",1
"Ecosystem Orchestration","Resource Group Management",0
"End-to-end Batch Planning and Optimization","Resource Group Management",0
"Integrated Maintenance/Work Orders","Resource Group Management",1
"Product Innovation","Resource Group Management",0
"Product Lifecycle Simulation","Resource Group Management",0
"Virtual Training","Resource Group Management",0
"Waste Circular Economy","Resource Group Management",0
"Water Usage Optimization","Resource Group Management",1
"Automated Formula Management","Stamp Architecture Deployment",0
"Automated Product Design","Stamp Architecture Deployment",0
"Autonomous Material Movement","Stamp Architecture Deployment",0
"Changeover & Cycle Time Optimization","Stamp Architecture Deployment",1
"Compressed Air Optimization","Stamp Architecture Deployment",0
"Connected Consumer Insights","Stamp Architecture Deployment",1
"Ecosystem Decision Support","Stamp Architecture Deployment",1
"Ecosystem Orchestration","Stamp Architecture Deployment",0
"End-to-end Batch Planning and Optimization","Stamp Architecture Deployment",0
"Integrated Maintenance/Work Orders","Stamp Architecture Deployment",1
"Product Innovation","Stamp Architecture Deployment",0
"Product Lifecycle Simulation","Stamp Architecture Deployment",0
"Virtual Training","Stamp Architecture Deployment",0
"Waste Circular Economy","Stamp Architecture Deployment",0
"Water Usage Optimization","Stamp Architecture Deployment",1
"VM Host Infrastructure","Cloud Virtual Machine Host(s) (050-vm-host)",10
"OCP UA Closed-Loop Control","Cloud AKS Cluster and ACR (060-aks-acr)",9
"Cloud Data Platform","Cloud Data Persistence (030-data)",33
"Cloud Messaging and Event Infrastructure","Edge Messaging & Data Routing (130-messaging)",33
"OPC UA Data Ingestion","Edge Messaging & Data Routing (130-messaging)",11
"Cloud Data Platform","Edge Messaging & Data Routing (130-messaging)",33
"Edge Compute Orchestration Platform","Cloud Security and Identity (010-security-identity)",26
"Cloud Secret and Certificate Management","Cloud Security and Identity (010-security-identity)",33
"Cloud Identity Management","Cloud Security and Identity (010-security-identity)",33
"Cloud Messaging and Event Infrastructure","Cloud Messaging (040-messaging)",33
"Cloud Observability Foundation","Cloud Observability (020-observability)",33
"Edge Dashboard Visualization","Cloud Observability (020-observability)",33
"OPC UA Data Ingestion","Edge Observability (120-observability)",11
"Edge Compute Orchestration Platform","Edge Observability (120-observability)",26
"Edge Dashboard Visualization","Edge Observability (120-observability)",33
"Cloud Observability Foundation","Edge Observability (120-observability)",33
"Cloud Secret and Certificate Management","Edge CNCF Cluster Setup & Arc Onboarding (100-cncf-cluster)",33
"OCP UA Closed-Loop Control","Edge CNCF Cluster Setup & Arc Onboarding (100-cncf-cluster)",9
"Edge Camera Control","RTSP Camera Stream Management",12
"Edge Camera Control","ONVIF Camera Control",12
"OCP UA Closed-Loop Control","Edge Azure IoT Operations Core (110-iot-ops)",9
"OPC UA Data Ingestion","Edge Azure IoT Operations Core (110-iot-ops)",11
"Edge Compute Orchestration Platform","Edge Azure IoT Operations Core (110-iot-ops)",26
"Edge Inferencing Application Framework","Inference Pipeline Application (500-basic-inference)",20
"Resource Group Management","Comprehensive resource tagging solutions",33
"Resource Group Management","Cloud Azure Resource Group (000-resource-group)",33
"Stamp Architecture Deployment","Industry Solution Blueprints Framework",33
"Stamp Architecture Deployment","Integration Environment for IaC Upgrade Testing",33
"Stamp Architecture Deployment","Ephemeral Environment Testing for Blueprints",33
```

*Note: Link widths represent the strength of relationships between connected items. The diagrams show the complex relationships between scenarios, capabilities, and features in the product backlog.*

## Report Generation

This report was generated on 2025-05-23 using data from all 306 pull requests in the edge-ai project.

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
