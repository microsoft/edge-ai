<!-- markdownlint-disable MD033 -->
# Pull Request Analysis for edge-ai

## Overview

This analysis covers pull request activity for the edge-ai project in the ai-at-the-edge-flagship-accelerator organization.

### Summary Statistics

- **Total Pull Requests**: 236
- **Completed**: 202 (85.6%)
- **Active**: 5 (2.1%)
- **Abandoned**: 29 (12.3%)
- **Average Days to Complete**: 3.06
- **Total Contributors**: 26

## Monthly Pull Request Activity

The following chart shows the trend of PRs created and completed each month.

``` mermaid

xychart-beta
    title "Monthly PR Activity Trends"
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#FF6384, #36A2EB"}}}}%%
    x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025"]
    y-axis "Number of PRs"
    line "Created PRs" [14, 18, 8, 60, 47, 56, 33]
    line "Completed PRs" [10, 15, 6, 52, 36, 53, 30]
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
    x-axis ["42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17"]
    y-axis "Number of PRs"
    bar [4, 1, 5, 3, 8, 2, 2, 4, 0, 2, 0, 0, 7, 11, 16, 18, 11, 8, 7, 12, 10, 18, 12, 7, 16, 8, 3, 7]
```

## PR Completion Time by Size

The size of a PR significantly impacts how long it takes to review and merge.

``` mermaid

xychart-beta
    title "Average Days to Complete by PR Size"
    x-axis ["Small (≤5 files)", "Medium (6-20 files)", "Large (>20 files)"]
    y-axis "Days" 2 --> 5.2
    bar [2.8, 3.1, 4.2]
```

## PR Completion Time Distribution

``` mermaid

pie showData
    title "PR Completion Time Distribution"
    "Under 1 Day" : 83
    "1-3 Days" : 67
    "4-7 Days" : 36
    "Over 7 Days" : 16
```

## SLO Compliance Trend

The following chart shows the trend of SLO compliance percentage over time (48 hour response window) and the number of PRs closed each week:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4BC0C0, #FF6384"}}}}%%
xychart-beta
    title "Weekly SLO Compliance and PR Closure"
    x-axis ["41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17"]
    y-axis "Percentage" 0 --> 100
    line [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 93.3, 100, 100, 94.4, 100, 100, 87.5, 100, 100]
    bar [0, 22.2, 5.6, 27.8, 16.7, 44.4, 11.1, 11.1, 22.2, 0, 11.1, 38.9, 61.1, 88.9, 100, 61.1, 44.4, 38.9, 66.7, 55.6, 100, 66.7, 38.9, 88.9, 44.4, 16.7, 38.9]
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
x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025"]
y-axis "Value (scaled)" 0 --> 134
line "Avg Files Changed" [14.5, 22.7, 37.5, 65.6, 55.8, 52.2, 121]
line "Avg Days to Complete" [100, 68.2, 62.5, 86.5, 95.2, 60.8, 107.5]
line "Avg Files/Day" [10.8, 24.9, 45, 56.8, 44, 64.4, 84.4]
line "Avg Lines/Day" [4.9, 91.4, 50.9, 47.5, 33.1, 74.8, 86.6]
line "Total Contributors" [16, 32, 24, 80, 80, 112, 72]
```

### PR Complexity Chart Legend

| Metric                                                       | Description                                                     | Actual Value Range   | Scaling Factor |
|--------------------------------------------------------------|-----------------------------------------------------------------|----------------------|----------------|
| <span style='color:#4BC0C0'>■■■■</span> Avg Files Changed    | Average number of files modified per PR                         | 2.9-24.2 files       | ×5             |
| <span style='color:#FF6384'>■■■■</span> Avg Days to Complete | Average time (in days) taken to complete PRs                    | 2.4-4.3 days         | ×25            |
| <span style='color:#36A2EB'>■■■■</span> Avg Files/Day        | Productivity metric (files changed divided by days to complete) | 0.7-5.6 files/day    | ×15            |
| <span style='color:#9966FF'>■■■■</span> Avg Lines/Day        | Productivity metric (lines changed divided by days to complete) | 12.3-228.6 lines/day | ×0.4           |
| <span style='color:#FFCE56'>■■■■</span> Total Contributors   | Count of unique contributors (new + returning) per month        | 2-14 contributors    | ×8             |

*Note: Scaling factors are applied to make different metrics comparable on the same chart.*

The following metrics show GitHub Copilot's impact on development productivity:

### Copilot Impact Metrics (% Change)

| Metric                | Before Copilot | After Copilot | % Change |
|-----------------------|----------------|---------------|----------|
| Files Changed per PR  | 10.3           | 15.2          | 47.8%    |
| Lines Changed per PR  | 381.4          | 602.7         | 58%      |
| Days to Complete PR   | 3.4            | 2.6           | -22%     |
| Files Changed per Day | 3.4            | 5.1           | 47.6%    |

**Note**: GitHub Copilot was introduced on February 25, 2025. PR completion time has decreased by 22% since Copilot adoption, while developer productivity (measured by files changed per day) has increased by 47.6%.

## Contributor Summary

Over the past 3 months:

- **Total Unique Contributors**: 25
- **New Contributors**: 12 (33.3%)
- **Returning Contributors**: 24 (66.7%)

### Contributors

<!-- cspell:disable -->
| Contributor               | PRs | Files Changed | Lines Added | Lines Deleted | Work Items Closed |
|---------------------------|-----|---------------|-------------|---------------|-------------------|
| Alain Uyidi               | 2   | 3             | 135         | 12            | 0                 |
| Allen Greaves             | 23  | 997           | 18599       | 8448          | 0                 |
| Andrej Kyselica           | 2   | 4             | 49          | 9             | 0                 |
| Andrew Malkov             | 1   | 2             | 1390        | 0             | 0                 |
| Basia Mahoney             | 1   | 1             | 1           | 1             | 0                 |
| Bill Berry                | 98  | 532           | 25863       | 7202          | 0                 |
| Braden Eriksen            | 1   | 3             | 126         | 38            | 0                 |
| Cheng Chen                | 2   | 3             | 307         | 0             | 0                 |
| Efrat Lecker              | 1   | 1             | 7           | 0             | 0                 |
| Eliise Seling             | 14  | 357           | 5774        | 3842          | 0                 |
| Eugene Fedorenko          | 6   | 10            | 484         | 6             | 0                 |
| Jeffrey Feng              | 1   | 0             | 0           | 0             | 0                 |
| Katrien De Graeve         | 26  | 247           | 10626       | 2777          | 0                 |
| Lauren Luttrell (SHE HER) | 1   | 1             | 7           | 7             | 0                 |
| Liam Moat                 | 1   | 2             | 13          | 13            | 0                 |
| Madhav Annamraju          | 3   | 3             | 555         | 0             | 0                 |
| Marcel Bindseil           | 22  | 200           | 4082        | 541           | 0                 |
| Michael Brown (ISE)       | 7   | 39            | 1209        | 41            | 0                 |
| Mykhailo Skuba            | 1   | 2             | 42          | 3             | 0                 |
| Olha Konstantinova        | 1   | 19            | 703         | 11            | 0                 |
| Omer Demir                | 2   | 6             | 360         | 6             | 0                 |
| Paul Bouwer               | 3   | 8             | 244         | 41            | 0                 |
| Rahul Dani                | 2   | 32            | 1040        | 55            | 0                 |
| Suneet Nangia             | 3   | 2             | 359         | 0             | 0                 |
| Vy Ta                     | 3   | 31            | 1469        | 20            | 0                 |

## Reviewers

| Reviewer            | Approvals | Comments |
|---------------------|-----------|----------|
| Alain Uyidi         | 18        | 34       |
| Allen Greaves       | 106       | 303      |
| Andrej Kyselica     | 1         | 0        |
| Basia Mahoney       | 1         | 2        |
| Bill Berry          | 92        | 411      |
| Braden Eriksen      | 2         | 8        |
| Cheng Chen          | 3         | 12       |
| Daisuke Inoue       | 1         | 6        |
| Dariusz Porowski    | 1         | 6        |
| Eliise Seling       | 49        | 76       |
| Emmeline Hoops      | 2         | 22       |
| Engin Polat         | 1         | 11       |
| Eugene Fedorenko    | 1         | 2        |
| Katrien De Graeve   | 67        | 148      |
| Larry Lieberman     | 38        | 5        |
| Mack Renard         | 2         | 0        |
| Madhav Annamraju    | 1         | 15       |
| Marcel Bindseil     | 31        | 31       |
| Marcia Dos Santos   | 1         | 10       |
| Michael Brown (ISE) | 10        | 10       |

<!-- cspell:enable -->

## Contributor Trends

The contributor retention rate (returning vs. new) suggests a growing, but potentially less stable contributor base.

This chart shows the pattern of new vs. returning contributors over time:

``` mermaid

xychart-beta
    title "Contributor Trends: New vs. Returning"
    x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025"]
    y-axis "Number of Contributors"
    line [2, 3, 1, 8, 5, 6, 1]
    line [1, 3, 4, 8, 7, 10, 7]
```

### Contributor Chart Legend

| Contributor Type       | Color                                   |
|------------------------|-----------------------------------------|
| New Contributors       | <span style='color:#4287f5'>■■■■</span> |
| Returning Contributors | <span style='color:#42f5a7'>■■■■</span> |

## File Types

| File Type                | Current Branch Files | % of Files | PR Changes Count | % of Changes |
|--------------------------|----------------------|------------|------------------|--------------|
| Terraform                | 268                  | 38.8%      | 1364             | 42.7%        |
| Documentation (Markdown) | 183                  | 26.5%      | 906              | 28.4%        |
| YAML                     | 53                   | 7.7%       | 317              | 9.9%         |
| Bicep/ARM Templates      | 43                   | 6.2%       | 300              | 9.4%         |
| Shell Scripts            | 26                   | 3.8%       | 132              | 4.1%         |
| Other                    | 72                   | 10.4%      | 123              | 3.8%         |
| PowerShell               | 17                   | 2.5%       | 27               | 0.8%         |
| Python                   | 4                    | 0.6%       | 15               | 0.5%         |
| C#                       | 11                   | 1.6%       | 11               | 0.3%         |
| Docker                   | 1                    | 0.1%       | 0                | 0.0%         |
| JSON                     | 13                   | 1.9%       | 0                | 0.0%         |
| **Total**                | **691**              | **100%**   | **3195**         | **100%**     |

## Focus Area Trends

The xy-chart below tracks how development focus areas have evolved over time in the project:

``` mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#9966FF, #FF6384, #4BC0C0, #36A2EB, #FF9F40, #326CE5, #8B8000"}}}}%%
xychart-beta
    title "Focus Area Trends Over Time (% of monthly PRs)"
    x-axis ["Oct 2024", "Nov 2024", "Dec 2024", "Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025"]
    y-axis "Percentage of PRs (log scale)" 1 --> 100
        line "Features" [35.7, 72.2, 75, 51.7, 42.6, 53.6, 69.7]     line "CI/CD" [7.1, 50, 50, 31.7, 40.4, 46.4, 36.4]     line "Bug Fixes" [28.6, 33.3, 50, 36.7, 21.3, 44.6, 30.3]     line "Documentation" [28.6, 16.7, 25, 40, 27.7, 42.9, 57.6]     line "Terraform" [0.1, 22.2, 25, 15, 14.9, 21.4, 21.2]     line "Kubernetes" [7.1, 16.7, 25, 11.7, 10.6, 17.9, 9.1]     line "Refactoring" [14.3, 5.6, 12.5, 13.3, 8.5, 10.7, 15.2]
```

### Focus Area Chart Legend

| Focus Area    | Color                                   | Focus Area  | Color                                   |
|---------------|-----------------------------------------|-------------|-----------------------------------------|
| Features      | <span style='color:#9966FF'>■■■■</span> | Terraform   | <span style='color:#FF9F40'>■■■■</span> |
| CI/CD         | <span style='color:#FF6384'>■■■■</span> | Kubernetes  | <span style='color:#326CE5'>■■■■</span> |
| Bug Fixes     | <span style='color:#4BC0C0'>■■■■</span> | Refactoring | <span style='color:#8B8000'>■■■■</span> |
| Documentation | <span style='color:#36A2EB'>■■■■</span> |             |                                         |

## Report Generation

This report was generated on 2025-04-22 using data from all 226 pull requests in the edge-ai project.
