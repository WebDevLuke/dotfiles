# Story Points Guide

Fibonacci scale for estimating Jira work items. When pointing a ticket, pick the row whose Effort / Time / Complexity / Risk best matches the work as a whole - don't average the columns; the highest-weighted signal usually wins. Points estimate size and uncertainty, not a time commitment.

| Story Point | Effort | Time (Est) | Complexity | Risk/Uncertainty | Notes |
| --- | --- | --- | --- | --- | --- |
| 1 | Minimal | Minutes | Smallest | None | |
| 2 | Minimal | Hours | Minimal | None | |
| 3 | Mild | Few Days | Minimal | None | |
| 5 | Moderate | Many Days | Medium | Moderate | |
| 8 | Severe | Week | Moderate | Moderate | A sign that a ticket may need breaking down. Not always the case though. |
| 13 | Maximum | Weeks / Month | High | High | A sign that a ticket needs breaking down. |

## How to apply

- **Only these values are valid:** 1, 2, 3, 5, 8, 13. Don't invent in-between points.
- **8 is a warning:** consider whether the ticket should be split into smaller stories - not mandatory, but check.
- **13 means break it down:** a 13 should almost always be decomposed before it enters a sprint.
- When Effort, Complexity and Risk disagree, let the **highest** of them pull the estimate up - a "few days" task with High risk is not a 3.
