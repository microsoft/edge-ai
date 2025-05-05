<!-- markdownlint-disable MD033 -->
# Pull Request Analysis for edge-ai

## Overview

This analysis covers pull request activity for the edge-ai project in the ai-at-the-edge-flagship-accelerator organization.

### Summary Statistics

- **Total Pull Requests**: 255
- **Completed**: 222 (87.1%)
- **Active**: 1 (0.4%)
- **Abandoned**: 32 (12.5%)
- **Average Days to Complete**: 3.02
- **Total Contributors**: 28

## Monthly Pull Request Activity

The following chart shows the trend of PRs created and completed each month.

``` mermaid

xychart-beta
    title "Monthly PR Activity Trends"
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#FF6384, #36A2EB"}}}}%%
    x-axis ["Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
    y-axis "Number of PRs"
    line "Created PRs" [18, 8, 60, 47, 56, 50, 2]
    line "Completed PRs" [15, 6, 52, 36, 53, 49, 1]
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
    x-axis ["44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"]
    y-axis "Number of PRs"
    bar [5, 3, 8, 2, 2, 4, 0, 2, 0, 0, 7, 11, 16, 18, 11, 8, 7, 12, 10, 18, 12, 7, 16, 8, 3, 17, 10, 0]
```

## PR Completion Time by Size

The size of a PR significantly impacts how long it takes to review and merge.

``` mermaid

xychart-beta
    title "Average Days to Complete by PR Size"
    x-axis ["Small (≤5 files)", "Medium (6-20 files)", "Large (>20 files)"]
    y-axis "Days" 2 --> 5.1
    bar [2.7, 3.3, 4.1]
```

## PR Completion Time Distribution

``` mermaid

pie showData
    title "PR Completion Time Distribution"
    "Under 1 Day" : 96
    "1-3 Days" : 68
    "4-7 Days" : 38
    "Over 7 Days" : 20
```

## SLO Compliance Trend

The following chart shows the trend of SLO compliance percentage over time (48 hour response window) and the number of PRs closed each week:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4BC0C0, #FF6384"}}}}%%
xychart-beta
    title "Weekly SLO Compliance and PR Closure"
    x-axis ["41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18"]
    y-axis "Percentage" 0 --> 100
    line [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 93.3, 100, 100, 94.4, 100, 100, 87.5, 100, 100, 100]
    bar [0, 22.2, 5.6, 27.8, 16.7, 44.4, 11.1, 11.1, 22.2, 0, 11.1, 38.9, 61.1, 88.9, 100, 61.1, 44.4, 38.9, 66.7, 55.6, 100, 66.7, 38.9, 88.9, 44.4, 16.7, 94.4, 55.6]
```

### Chart Legend

| Metric           | Description                                                                   | Color                                   |
|------------------|-------------------------------------------------------------------------------|-----------------------------------------|
| SLO Compliance % | Percentage of PRs meeting the 48 hour response window                         | <span style='color:#4BC0C0'>■■■■</span> |
| PRs Closed       | Total number of PRs closed in each week (scaled to percentage of maximum: 18) | <span style='color:#FF6384'>■■■■</span> |

## GitHub Copilot Impact

The following chart shows PR complexity metrics over time:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4BC0C0, #FF6384, #36A2EB, #9966FF, #FFCE56"}}}}%%
xychart-beta
    title "PR Complexity and Contributors"
x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
y-axis "Value (scaled)" 0 --> 215
line "Avg Files Changed" [14.5, 22.7, 37.5, 65.4, 55.6, 52.1, 92.6, 65]
line "Avg Days to Complete" [100, 68.2, 62.5, 86.5, 95.2, 60.8, 97.5, 25]
line "Avg Files/Day" [10.8, 24.9, 45, 56.7, 43.8, 64.2, 71.2, 195]
line "Avg Lines/Day" [6, 91.4, 50.9, 47.4, 33.1, 74.7, 100.6, 85.2]
line "Total Contributors" [16, 32, 24, 80, 80, 112, 96, 8]
```

### PR Complexity Chart Legend

| Metric                                                       | Description                                                     | Actual Value Range | Scaling Factor |
|--------------------------------------------------------------|-----------------------------------------------------------------|--------------------|----------------|
| <span style='color:#4BC0C0'>■■■■</span> Avg Files Changed    | Average number of files modified per PR                         | 2.9-18.5 files     | ×5             |
| <span style='color:#FF6384'>■■■■</span> Avg Days to Complete | Average time (in days) taken to complete PRs                    | 1-4 days           | ×25            |
| <span style='color:#36A2EB'>■■■■</span> Avg Files/Day        | Productivity metric (files changed divided by days to complete) | 0.7-13 files/day   | ×15            |
| <span style='color:#9966FF'>■■■■</span> Avg Lines/Day        | Productivity metric (lines changed divided by days to complete) | 15-251.6 lines/day | ×0.4           |
| <span style='color:#FFCE56'>■■■■</span> Total Contributors   | Count of unique contributors (new + returning) per month        | 1-14 contributors  | ×8             |

*Note: Scaling factors are applied to make different metrics comparable on the same chart.*

The following metrics show GitHub Copilot's impact on development productivity:

### Copilot Impact Metrics (% Change)

| Metric                | Before Copilot | After Copilot | % Change |
|-----------------------|----------------|---------------|----------|
| Files Changed per PR  | 10.2           | 14.1          | 38.3%    |
| Lines Changed per PR  | 382.1          | 679.4         | 77.8%    |
| Days to Complete PR   | 3.4            | 2.6           | -21.6%   |
| Files Changed per Day | 3.4            | 4.7           | 38.2%    |

**Note**: GitHub Copilot was introduced on February 25, 2025. PR completion time has decreased by 21.6% since Copilot adoption, while developer productivity (measured by files changed per day) has increased by 38.2%.

## Contributor Summary

Over the past 3 months:

- **Total Unique Contributors**: 27
- **New Contributors**: 9 (31%)
- **Returning Contributors**: 20 (69%)

### Contributors

<!-- cspell:disable -->
| Contributor               | PRs | Files Changed | Lines Added | Lines Deleted | Work Items Closed |
|---------------------------|-----|---------------|-------------|---------------|-------------------|
| Alain Uyidi               | 2   | 3             | 135         | 12            | 2                 |
| Allen Greaves             | 26  | 1084          | 24991       | 9582          | 26                |
| Andrej Kyselica           | 2   | 4             | 49          | 9             | 1                 |
| Andrew Malkov             | 1   | 2             | 1390        | 0             | 1                 |
| Andrew Nguyen             | 1   | 9             | 477         | 3             | 1                 |
| Basia Mahoney             | 1   | 1             | 1           | 1             | 1                 |
| Bill Berry                | 101 | 570           | 33904       | 7630          | 182               |
| Braden Eriksen            | 1   | 3             | 126         | 38            | 1                 |
| Cheng Chen                | 2   | 3             | 307         | 0             | 2                 |
| Efrat Lecker              | 1   | 1             | 7           | 0             | 1                 |
| Eliise Seling             | 14  | 355           | 5761        | 3836          | 22                |
| Eugene Fedorenko          | 6   | 11            | 599         | 6             | 6                 |
| Jeffrey Feng              | 3   | 4             | 2946        | 0             | 2                 |
| Joshua Phelps             | 1   | 0             | 0           | 0             | 1                 |
| Katrien De Graeve         | 28  | 249           | 10684       | 2787          | 41                |
| Lauren Luttrell (SHE HER) | 1   | 1             | 7           | 7             | 1                 |
| Liam Moat                 | 1   | 2             | 13          | 13            | 2                 |
| Madhav Annamraju          | 3   | 3             | 555         | 0             | 3                 |
| Marcel Bindseil           | 27  | 204           | 4161        | 545           | 33                |
| Michael Brown (ISE)       | 9   | 85            | 1847        | 153           | 9                 |
| Mykhailo Skuba            | 1   | 2             | 42          | 3             | 0                 |
| Olha Konstantinova        | 1   | 19            | 703         | 11            | 1                 |
| Omer Demir                | 2   | 6             | 360         | 6             | 2                 |
| Paul Bouwer               | 3   | 8             | 244         | 41            | 3                 |
| Rahul Dani                | 2   | 32            | 1040        | 55            | 2                 |
| Suneet Nangia             | 3   | 2             | 359         | 0             | 3                 |
| Vy Ta                     | 3   | 31            | 1469        | 20            | 8                 |

## Reviewers

| Reviewer            | Approvals | Comments |
|---------------------|-----------|----------|
| Alain Uyidi         | 18        | 34       |
| Allen Greaves       | 113       | 307      |
| Andrej Kyselica     | 1         | 0        |
| Basia Mahoney       | 1         | 2        |
| Bill Berry          | 103       | 426      |
| Braden Eriksen      | 2         | 8        |
| Cheng Chen          | 3         | 12       |
| Daisuke Inoue       | 1         | 6        |
| Dariusz Porowski    | 1         | 6        |
| Eliise Seling       | 51        | 76       |
| Emmeline Hoops      | 2         | 22       |
| Engin Polat         | 1         | 11       |
| Eugene Fedorenko    | 1         | 2        |
| Katrien De Graeve   | 74        | 167      |
| Larry Lieberman     | 39        | 5        |
| Mack Renard         | 2         | 0        |
| Madhav Annamraju    | 1         | 15       |
| Marcel Bindseil     | 35        | 39       |
| Marcia Dos Santos   | 1         | 10       |
| Michael Brown (ISE) | 10        | 10       |

<!-- cspell:enable -->

## Contributor Trends

The contributor retention rate (returning vs. new) suggests a growing, but potentially less stable contributor base.

This chart shows the pattern of new vs. returning contributors over time:

``` mermaid

xychart-beta
    title "Contributor Trends: New vs. Returning"
    x-axis ["Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
    y-axis "Number of Contributors"
    line [3, 1, 8, 5, 6, 3, 0]
    line [3, 4, 8, 7, 10, 8, 2]
```

### Contributor Chart Legend

| Contributor Type       | Color                                   |
|------------------------|-----------------------------------------|
| New Contributors       | <span style='color:#4287f5'>■■■■</span> |
| Returning Contributors | <span style='color:#42f5a7'>■■■■</span> |

## File Types

| File Type                | Current Branch Files | % of Files | PR Changes Count | % of Changes |
|--------------------------|----------------------|------------|------------------|--------------|
| Terraform                | 297                  | 37.9%      | 1368             | 39.7%        |
| Documentation (Markdown) | 206                  | 26.3%      | 1000             | 29.0%        |
| Bicep/ARM Templates      | 56                   | 7.1%       | 372              | 10.8%        |
| YAML                     | 56                   | 7.1%       | 330              | 9.6%         |
| Shell Scripts            | 32                   | 4.1%       | 158              | 4.6%         |
| Other                    | 87                   | 11.1%      | 146              | 4.2%         |
| PowerShell               | 19                   | 2.4%       | 43               | 1.2%         |
| Python                   | 4                    | 0.5%       | 15               | 0.4%         |
| C#                       | 11                   | 1.4%       | 11               | 0.3%         |
| Docker                   | 1                    | 0.1%       | 0                | 0.0%         |
| JSON                     | 15                   | 1.9%       | 0                | 0.0%         |
| **Total**                | **784**              | **100%**   | **3443**         | **100%**     |

## Focus Area Trends

The xy-chart below tracks how development focus areas have evolved over time in the project:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#9966FF, #FF6384, #36A2EB, #4BC0C0, #FF9F40, #326CE5, #8B8000"}}}}%%
xychart-beta
    title "Focus Area Trends Over Time (% of monthly PRs)"
    x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025"]
    y-axis "Percentage of PRs (log scale)" 1 --> 100
        line "Features" [35.7, 72.2, 75, 51.7, 42.6, 53.6, 70, 50]     line "CI/CD" [7.1, 50, 50, 31.7, 40.4, 46.4, 38, 50]     line "Documentation" [28.6, 16.7, 25, 40, 27.7, 42.9, 52, 50]     line "Bug Fixes" [28.6, 33.3, 50, 36.7, 21.3, 44.6, 34, 0.1]     line "Terraform" [0.1, 22.2, 25, 15, 14.9, 21.4, 16, 0.1]     line "Kubernetes" [7.1, 16.7, 25, 11.7, 10.6, 17.9, 10, 0.1]     line "Refactoring" [14.3, 5.6, 12.5, 13.3, 8.5, 10.7, 18, 0.1]
```

### Focus Area Chart Legend

| Focus Area    | Color                                   | Focus Area  | Color                                   |
|---------------|-----------------------------------------|-------------|-----------------------------------------|
| Features      | <span style='color:#9966FF'>■■■■</span> | Terraform   | <span style='color:#FF9F40'>■■■■</span> |
| CI/CD         | <span style='color:#FF6384'>■■■■</span> | Kubernetes  | <span style='color:#326CE5'>■■■■</span> |
| Documentation | <span style='color:#36A2EB'>■■■■</span> | Refactoring | <span style='color:#8B8000'>■■■■</span> |
| Bug Fixes     | <span style='color:#4BC0C0'>■■■■</span> |             |                                         |

## Industry Backlog Visualization

The following Sankey diagram visualizes the flow from scenarios through capabilities to specific backlog features.

Scenarios are weighted by the number of industry customers requiring them, and capabilities are weighted by the number of scenarios they support.

|   |                                                            **Scenarios**                                                             |                                                                             **Capabilities**                                                                             |                                                                               **Features**                                                                               |   |
|:-:|:------------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|:-:|
|   | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; |   |

``` mermaid

---
config:
  sankey:
    showValues: false
    width: 1200
    height: 1400
---
sankey-beta

"Automated Formula Management","Azure VM Host Infrastructure",0
"Automated Quality Diagnostics & Simulation","Azure VM Host Infrastructure",3
"Facility Design & Simulation","Azure VM Host Infrastructure",3
"Immersive Remote Operations","Azure VM Host Infrastructure",5
"Integrated Maintenance/Work Orders","Azure VM Host Infrastructure",1
"Predictive Maintenance","Azure VM Host Infrastructure",8
"Product Innovation","Azure VM Host Infrastructure",0
"Product Lifecycle Simulation","Azure VM Host Infrastructure",0
"Semi-Autonomous Cell","Azure VM Host Infrastructure",2
"Virtual Training","Azure VM Host Infrastructure",0
"Automated Quality Diagnostics & Simulation","Cloud Container Platform Infrastructure",3
"Autonomous Cell","Cloud Container Platform Infrastructure",2
"Facility Design & Simulation","Cloud Container Platform Infrastructure",3
"Immersive Remote Operations","Cloud Container Platform Infrastructure",5
"Intelligent Assistant (CoPilot/Companion)","Cloud Container Platform Infrastructure",6
"Operational Performance Monitoring","Cloud Container Platform Infrastructure",7
"Predictive Maintenance","Cloud Container Platform Infrastructure",8
"Semi-Autonomous Cell","Cloud Container Platform Infrastructure",2
"Yield Process Optimization","Cloud Container Platform Infrastructure",6
"Automated Formula Management","Cloud Data Platform",0
"Automated Product Design","Cloud Data Platform",0
"Automated Quality Diagnostics & Simulation","Cloud Data Platform",3
"Autonomous Cell","Cloud Data Platform",2
"Autonomous Material Movement","Cloud Data Platform",0
"Changeover & Cycle Time Optimization","Cloud Data Platform",1
"Compressed Air Optimization","Cloud Data Platform",0
"Connected Consumer Insights","Cloud Data Platform",0
"Digital Inspection / Survey","Cloud Data Platform",7
"Ecosystem Decision Support","Cloud Data Platform",0
"Ecosystem Orchestration","Cloud Data Platform",0
"End-to-end Batch Planning and Optimization","Cloud Data Platform",0
"End-to-end Material Handling","Cloud Data Platform",2
"Enhanced Personal Safety","Cloud Data Platform",3
"Facility Design & Simulation","Cloud Data Platform",3
"Immersive Remote Operations","Cloud Data Platform",5
"Integrated Maintenance/Work Orders","Cloud Data Platform",1
"Intelligent Assistant (CoPilot/Companion)","Cloud Data Platform",6
"Inventory Optimization","Cloud Data Platform",2
"Logistics Optimization & Automation","Cloud Data Platform",2
"Operational Performance Monitoring","Cloud Data Platform",7
"Packaging Line Performance Optimization","Cloud Data Platform",3
"Predictive Maintenance","Cloud Data Platform",8
"Product Innovation","Cloud Data Platform",0
"Product Lifecycle Simulation","Cloud Data Platform",0
"Quality Process Optimization & Automation","Cloud Data Platform",6
"Semi-Autonomous Cell","Cloud Data Platform",2
"Virtual Training","Cloud Data Platform",0
"Waste Circular Economy","Cloud Data Platform",0
"Water Usage Optimization","Cloud Data Platform",1
"Yield Process Optimization","Cloud Data Platform",6
"Automated Formula Management","Cloud Identity Management",0
"Automated Product Design","Cloud Identity Management",0
"Automated Quality Diagnostics & Simulation","Cloud Identity Management",3
"Autonomous Cell","Cloud Identity Management",2
"Autonomous Material Movement","Cloud Identity Management",0
"Changeover & Cycle Time Optimization","Cloud Identity Management",1
"Compressed Air Optimization","Cloud Identity Management",0
"Connected Consumer Insights","Cloud Identity Management",0
"Digital Inspection / Survey","Cloud Identity Management",7
"Ecosystem Decision Support","Cloud Identity Management",0
"Ecosystem Orchestration","Cloud Identity Management",0
"End-to-end Batch Planning and Optimization","Cloud Identity Management",0
"End-to-end Material Handling","Cloud Identity Management",2
"Enhanced Personal Safety","Cloud Identity Management",3
"Facility Design & Simulation","Cloud Identity Management",3
"Immersive Remote Operations","Cloud Identity Management",5
"Integrated Maintenance/Work Orders","Cloud Identity Management",1
"Intelligent Assistant (CoPilot/Companion)","Cloud Identity Management",6
"Inventory Optimization","Cloud Identity Management",2
"Logistics Optimization & Automation","Cloud Identity Management",2
"Operational Performance Monitoring","Cloud Identity Management",7
"Packaging Line Performance Optimization","Cloud Identity Management",3
"Predictive Maintenance","Cloud Identity Management",8
"Product Innovation","Cloud Identity Management",0
"Product Lifecycle Simulation","Cloud Identity Management",0
"Quality Process Optimization & Automation","Cloud Identity Management",6
"Semi-Autonomous Cell","Cloud Identity Management",2
"Virtual Training","Cloud Identity Management",0
"Waste Circular Economy","Cloud Identity Management",0
"Water Usage Optimization","Cloud Identity Management",1
"Yield Process Optimization","Cloud Identity Management",6
"Automated Formula Management","Cloud Messaging and Event Infrastructure",0
"Automated Product Design","Cloud Messaging and Event Infrastructure",0
"Automated Quality Diagnostics & Simulation","Cloud Messaging and Event Infrastructure",3
"Autonomous Cell","Cloud Messaging and Event Infrastructure",2
"Autonomous Material Movement","Cloud Messaging and Event Infrastructure",0
"Changeover & Cycle Time Optimization","Cloud Messaging and Event Infrastructure",1
"Compressed Air Optimization","Cloud Messaging and Event Infrastructure",0
"Connected Consumer Insights","Cloud Messaging and Event Infrastructure",0
"Digital Inspection / Survey","Cloud Messaging and Event Infrastructure",7
"Ecosystem Decision Support","Cloud Messaging and Event Infrastructure",0
"Ecosystem Orchestration","Cloud Messaging and Event Infrastructure",0
"End-to-end Batch Planning and Optimization","Cloud Messaging and Event Infrastructure",0
"End-to-end Material Handling","Cloud Messaging and Event Infrastructure",2
"Enhanced Personal Safety","Cloud Messaging and Event Infrastructure",3
"Facility Design & Simulation","Cloud Messaging and Event Infrastructure",3
"Immersive Remote Operations","Cloud Messaging and Event Infrastructure",5
"Integrated Maintenance/Work Orders","Cloud Messaging and Event Infrastructure",1
"Intelligent Assistant (CoPilot/Companion)","Cloud Messaging and Event Infrastructure",6
"Inventory Optimization","Cloud Messaging and Event Infrastructure",2
"Logistics Optimization & Automation","Cloud Messaging and Event Infrastructure",2
"Operational Performance Monitoring","Cloud Messaging and Event Infrastructure",7
"Packaging Line Performance Optimization","Cloud Messaging and Event Infrastructure",3
"Predictive Maintenance","Cloud Messaging and Event Infrastructure",8
"Product Innovation","Cloud Messaging and Event Infrastructure",0
"Product Lifecycle Simulation","Cloud Messaging and Event Infrastructure",0
"Quality Process Optimization & Automation","Cloud Messaging and Event Infrastructure",6
"Semi-Autonomous Cell","Cloud Messaging and Event Infrastructure",2
"Virtual Training","Cloud Messaging and Event Infrastructure",0
"Waste Circular Economy","Cloud Messaging and Event Infrastructure",0
"Water Usage Optimization","Cloud Messaging and Event Infrastructure",1
"Yield Process Optimization","Cloud Messaging and Event Infrastructure",6
"Automated Formula Management","Cloud Observability Foundation",0
"Automated Product Design","Cloud Observability Foundation",0
"Automated Quality Diagnostics & Simulation","Cloud Observability Foundation",3
"Autonomous Cell","Cloud Observability Foundation",2
"Autonomous Material Movement","Cloud Observability Foundation",0
"Changeover & Cycle Time Optimization","Cloud Observability Foundation",1
"Compressed Air Optimization","Cloud Observability Foundation",0
"Connected Consumer Insights","Cloud Observability Foundation",0
"Digital Inspection / Survey","Cloud Observability Foundation",7
"Ecosystem Decision Support","Cloud Observability Foundation",0
"Ecosystem Orchestration","Cloud Observability Foundation",0
"End-to-end Batch Planning and Optimization","Cloud Observability Foundation",0
"End-to-end Material Handling","Cloud Observability Foundation",2
"Enhanced Personal Safety","Cloud Observability Foundation",3
"Facility Design & Simulation","Cloud Observability Foundation",3
"Immersive Remote Operations","Cloud Observability Foundation",5
"Integrated Maintenance/Work Orders","Cloud Observability Foundation",1
"Intelligent Assistant (CoPilot/Companion)","Cloud Observability Foundation",6
"Inventory Optimization","Cloud Observability Foundation",2
"Logistics Optimization & Automation","Cloud Observability Foundation",2
"Operational Performance Monitoring","Cloud Observability Foundation",7
"Packaging Line Performance Optimization","Cloud Observability Foundation",3
"Predictive Maintenance","Cloud Observability Foundation",8
"Product Innovation","Cloud Observability Foundation",0
"Product Lifecycle Simulation","Cloud Observability Foundation",0
"Quality Process Optimization & Automation","Cloud Observability Foundation",6
"Semi-Autonomous Cell","Cloud Observability Foundation",2
"Virtual Training","Cloud Observability Foundation",0
"Waste Circular Economy","Cloud Observability Foundation",0
"Water Usage Optimization","Cloud Observability Foundation",1
"Yield Process Optimization","Cloud Observability Foundation",6
"Automated Formula Management","Cloud Secret and Certificate Management",0
"Automated Product Design","Cloud Secret and Certificate Management",0
"Automated Quality Diagnostics & Simulation","Cloud Secret and Certificate Management",3
"Autonomous Cell","Cloud Secret and Certificate Management",2
"Autonomous Material Movement","Cloud Secret and Certificate Management",0
"Changeover & Cycle Time Optimization","Cloud Secret and Certificate Management",1
"Compressed Air Optimization","Cloud Secret and Certificate Management",0
"Connected Consumer Insights","Cloud Secret and Certificate Management",0
"Digital Inspection / Survey","Cloud Secret and Certificate Management",7
"Ecosystem Decision Support","Cloud Secret and Certificate Management",0
"Ecosystem Orchestration","Cloud Secret and Certificate Management",0
"End-to-end Batch Planning and Optimization","Cloud Secret and Certificate Management",0
"End-to-end Material Handling","Cloud Secret and Certificate Management",2
"Enhanced Personal Safety","Cloud Secret and Certificate Management",3
"Facility Design & Simulation","Cloud Secret and Certificate Management",3
"Immersive Remote Operations","Cloud Secret and Certificate Management",5
"Integrated Maintenance/Work Orders","Cloud Secret and Certificate Management",1
"Intelligent Assistant (CoPilot/Companion)","Cloud Secret and Certificate Management",6
"Inventory Optimization","Cloud Secret and Certificate Management",2
"Logistics Optimization & Automation","Cloud Secret and Certificate Management",2
"Operational Performance Monitoring","Cloud Secret and Certificate Management",7
"Packaging Line Performance Optimization","Cloud Secret and Certificate Management",3
"Predictive Maintenance","Cloud Secret and Certificate Management",8
"Product Innovation","Cloud Secret and Certificate Management",0
"Product Lifecycle Simulation","Cloud Secret and Certificate Management",0
"Quality Process Optimization & Automation","Cloud Secret and Certificate Management",6
"Semi-Autonomous Cell","Cloud Secret and Certificate Management",2
"Virtual Training","Cloud Secret and Certificate Management",0
"Waste Circular Economy","Cloud Secret and Certificate Management",0
"Water Usage Optimization","Cloud Secret and Certificate Management",1
"Yield Process Optimization","Cloud Secret and Certificate Management",6
"Automated Quality Diagnostics & Simulation","Edge Camera Control",3
"Autonomous Cell","Edge Camera Control",2
"Digital Inspection / Survey","Edge Camera Control",7
"End-to-end Material Handling","Edge Camera Control",2
"Enhanced Personal Safety","Edge Camera Control",3
"Immersive Remote Operations","Edge Camera Control",5
"Integrated Maintenance/Work Orders","Edge Camera Control",1
"Operational Performance Monitoring","Edge Camera Control",7
"Predictive Maintenance","Edge Camera Control",8
"Quality Process Optimization & Automation","Edge Camera Control",6
"Semi-Autonomous Cell","Edge Camera Control",2
"Automated Formula Management","Edge Compute Orchestration Platform",0
"Autonomous Cell","Edge Compute Orchestration Platform",2
"Autonomous Material Movement","Edge Compute Orchestration Platform",0
"Compressed Air Optimization","Edge Compute Orchestration Platform",0
"Digital Inspection / Survey","Edge Compute Orchestration Platform",7
"Ecosystem Decision Support","Edge Compute Orchestration Platform",0
"Ecosystem Orchestration","Edge Compute Orchestration Platform",0
"End-to-end Material Handling","Edge Compute Orchestration Platform",2
"Enhanced Personal Safety","Edge Compute Orchestration Platform",3
"Immersive Remote Operations","Edge Compute Orchestration Platform",5
"Integrated Maintenance/Work Orders","Edge Compute Orchestration Platform",1
"Inventory Optimization","Edge Compute Orchestration Platform",2
"Logistics Optimization & Automation","Edge Compute Orchestration Platform",2
"Operational Performance Monitoring","Edge Compute Orchestration Platform",7
"Predictive Maintenance","Edge Compute Orchestration Platform",8
"Semi-Autonomous Cell","Edge Compute Orchestration Platform",2
"Waste Circular Economy","Edge Compute Orchestration Platform",0
"Water Usage Optimization","Edge Compute Orchestration Platform",1
"Yield Process Optimization","Edge Compute Orchestration Platform",6
"Automated Formula Management","Edge Dashboard Visualization",0
"Automated Product Design","Edge Dashboard Visualization",0
"Automated Quality Diagnostics & Simulation","Edge Dashboard Visualization",3
"Autonomous Cell","Edge Dashboard Visualization",2
"Autonomous Material Movement","Edge Dashboard Visualization",0
"Changeover & Cycle Time Optimization","Edge Dashboard Visualization",1
"Compressed Air Optimization","Edge Dashboard Visualization",0
"Connected Consumer Insights","Edge Dashboard Visualization",0
"Digital Inspection / Survey","Edge Dashboard Visualization",7
"Ecosystem Decision Support","Edge Dashboard Visualization",0
"Ecosystem Orchestration","Edge Dashboard Visualization",0
"End-to-end Batch Planning and Optimization","Edge Dashboard Visualization",0
"End-to-end Material Handling","Edge Dashboard Visualization",2
"Enhanced Personal Safety","Edge Dashboard Visualization",3
"Facility Design & Simulation","Edge Dashboard Visualization",3
"Immersive Remote Operations","Edge Dashboard Visualization",5
"Integrated Maintenance/Work Orders","Edge Dashboard Visualization",1
"Intelligent Assistant (CoPilot/Companion)","Edge Dashboard Visualization",6
"Inventory Optimization","Edge Dashboard Visualization",2
"Logistics Optimization & Automation","Edge Dashboard Visualization",2
"Operational Performance Monitoring","Edge Dashboard Visualization",7
"Packaging Line Performance Optimization","Edge Dashboard Visualization",3
"Predictive Maintenance","Edge Dashboard Visualization",8
"Product Innovation","Edge Dashboard Visualization",0
"Product Lifecycle Simulation","Edge Dashboard Visualization",0
"Quality Process Optimization & Automation","Edge Dashboard Visualization",6
"Semi-Autonomous Cell","Edge Dashboard Visualization",2
"Virtual Training","Edge Dashboard Visualization",0
"Waste Circular Economy","Edge Dashboard Visualization",0
"Water Usage Optimization","Edge Dashboard Visualization",1
"Yield Process Optimization","Edge Dashboard Visualization",6
"Automated Formula Management","Edge Inferencing Application Framework",0
"Automated Quality Diagnostics & Simulation","Edge Inferencing Application Framework",3
"Autonomous Cell","Edge Inferencing Application Framework",2
"Autonomous Material Movement","Edge Inferencing Application Framework",0
"Changeover & Cycle Time Optimization","Edge Inferencing Application Framework",1
"Compressed Air Optimization","Edge Inferencing Application Framework",0
"Digital Inspection / Survey","Edge Inferencing Application Framework",7
"End-to-end Batch Planning and Optimization","Edge Inferencing Application Framework",0
"End-to-end Material Handling","Edge Inferencing Application Framework",2
"Enhanced Personal Safety","Edge Inferencing Application Framework",3
"Intelligent Assistant (CoPilot/Companion)","Edge Inferencing Application Framework",6
"Inventory Optimization","Edge Inferencing Application Framework",2
"Operational Performance Monitoring","Edge Inferencing Application Framework",7
"Packaging Line Performance Optimization","Edge Inferencing Application Framework",3
"Predictive Maintenance","Edge Inferencing Application Framework",8
"Quality Process Optimization & Automation","Edge Inferencing Application Framework",6
"Semi-Autonomous Cell","Edge Inferencing Application Framework",2
"Water Usage Optimization","Edge Inferencing Application Framework",1
"Yield Process Optimization","Edge Inferencing Application Framework",6
"Autonomous Cell","OCP UA Closed-Loop Control",2
"Changeover & Cycle Time Optimization","OCP UA Closed-Loop Control",1
"Packaging Line Performance Optimization","OCP UA Closed-Loop Control",3
"Quality Process Optimization & Automation","OCP UA Closed-Loop Control",6
"Semi-Autonomous Cell","OCP UA Closed-Loop Control",2
"Waste Circular Economy","OCP UA Closed-Loop Control",0
"Water Usage Optimization","OCP UA Closed-Loop Control",1
"Yield Process Optimization","OCP UA Closed-Loop Control",6
"Automated Quality Diagnostics & Simulation","OPC UA Data Ingestion",3
"Autonomous Cell","OPC UA Data Ingestion",2
"Changeover & Cycle Time Optimization","OPC UA Data Ingestion",1
"Integrated Maintenance/Work Orders","OPC UA Data Ingestion",1
"Operational Performance Monitoring","OPC UA Data Ingestion",7
"Packaging Line Performance Optimization","OPC UA Data Ingestion",3
"Predictive Maintenance","OPC UA Data Ingestion",8
"Quality Process Optimization & Automation","OPC UA Data Ingestion",6
"Semi-Autonomous Cell","OPC UA Data Ingestion",2
"Yield Process Optimization","OPC UA Data Ingestion",6
"Automated Formula Management","Resource Group Management",0
"Automated Product Design","Resource Group Management",0
"Automated Quality Diagnostics & Simulation","Resource Group Management",3
"Autonomous Cell","Resource Group Management",2
"Autonomous Material Movement","Resource Group Management",0
"Changeover & Cycle Time Optimization","Resource Group Management",1
"Compressed Air Optimization","Resource Group Management",0
"Connected Consumer Insights","Resource Group Management",0
"Digital Inspection / Survey","Resource Group Management",7
"Ecosystem Decision Support","Resource Group Management",0
"Ecosystem Orchestration","Resource Group Management",0
"End-to-end Batch Planning and Optimization","Resource Group Management",0
"End-to-end Material Handling","Resource Group Management",2
"Enhanced Personal Safety","Resource Group Management",3
"Facility Design & Simulation","Resource Group Management",3
"Immersive Remote Operations","Resource Group Management",5
"Integrated Maintenance/Work Orders","Resource Group Management",1
"Intelligent Assistant (CoPilot/Companion)","Resource Group Management",6
"Inventory Optimization","Resource Group Management",2
"Logistics Optimization & Automation","Resource Group Management",2
"Operational Performance Monitoring","Resource Group Management",7
"Packaging Line Performance Optimization","Resource Group Management",3
"Predictive Maintenance","Resource Group Management",8
"Product Innovation","Resource Group Management",0
"Product Lifecycle Simulation","Resource Group Management",0
"Quality Process Optimization & Automation","Resource Group Management",6
"Semi-Autonomous Cell","Resource Group Management",2
"Virtual Training","Resource Group Management",0
"Waste Circular Economy","Resource Group Management",0
"Water Usage Optimization","Resource Group Management",1
"Yield Process Optimization","Resource Group Management",6
"Automated Formula Management","Stamp Architecture Deployment",0
"Automated Product Design","Stamp Architecture Deployment",0
"Automated Quality Diagnostics & Simulation","Stamp Architecture Deployment",3
"Autonomous Cell","Stamp Architecture Deployment",2
"Autonomous Material Movement","Stamp Architecture Deployment",0
"Changeover & Cycle Time Optimization","Stamp Architecture Deployment",1
"Compressed Air Optimization","Stamp Architecture Deployment",0
"Connected Consumer Insights","Stamp Architecture Deployment",0
"Digital Inspection / Survey","Stamp Architecture Deployment",7
"Ecosystem Decision Support","Stamp Architecture Deployment",0
"Ecosystem Orchestration","Stamp Architecture Deployment",0
"End-to-end Batch Planning and Optimization","Stamp Architecture Deployment",0
"End-to-end Material Handling","Stamp Architecture Deployment",2
"Enhanced Personal Safety","Stamp Architecture Deployment",3
"Facility Design & Simulation","Stamp Architecture Deployment",3
"Immersive Remote Operations","Stamp Architecture Deployment",5
"Integrated Maintenance/Work Orders","Stamp Architecture Deployment",1
"Intelligent Assistant (CoPilot/Companion)","Stamp Architecture Deployment",6
"Inventory Optimization","Stamp Architecture Deployment",2
"Logistics Optimization & Automation","Stamp Architecture Deployment",2
"Operational Performance Monitoring","Stamp Architecture Deployment",7
"Packaging Line Performance Optimization","Stamp Architecture Deployment",3
"Predictive Maintenance","Stamp Architecture Deployment",8
"Product Innovation","Stamp Architecture Deployment",0
"Product Lifecycle Simulation","Stamp Architecture Deployment",0
"Quality Process Optimization & Automation","Stamp Architecture Deployment",6
"Semi-Autonomous Cell","Stamp Architecture Deployment",2
"Virtual Training","Stamp Architecture Deployment",0
"Waste Circular Economy","Stamp Architecture Deployment",0
"Water Usage Optimization","Stamp Architecture Deployment",1
"Yield Process Optimization","Stamp Architecture Deployment",6
"Azure VM Host Infrastructure","Cloud Virtual Machine Host(s) (050-vm-host)",10
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

*Note: Link widths represent the strength of relationships between connected items. The diagram shows the complex relationships between scenarios, capabilities, and features in the product backlog.*

## Report Generation

This report was generated on 2025-05-05 using data from all 255 pull requests in the edge-ai project.
