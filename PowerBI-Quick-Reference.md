# Power BI Copilot Usage Dashboard - Quick Reference Card

## Page 1: Executive Summary

| # | Visual Type | Title | Data Fields | Key Settings |
|---|-------------|-------|-------------|--------------|
| 1.1 | Text Box | Dashboard Title | N/A | Segoe UI Semibold, 24pt |
| 1.2 | Slicer | Date Range | `DateTable[Date]` | Style: Between, Slider: On |
| 1.3 | Card | Total Interactions | `[Total Interactions]` | Color: #0078D4, 32pt |
| 1.4 | Card | Unique Users | `[Unique Users]` | Color: #0078D4, 32pt |
| 1.5 | Card | Licensed Users | `[Licensed Users]` | Color: #107C10 (green), 32pt |
| 1.6 | Card | Unlicensed Users | `[Unlicensed Users]` | Color: #FFB900 (amber), 32pt |
| 1.7 | Card | MoM Change | `[MoM Change Display]` | Color: Dynamic, 24pt |
| 1.8 | Line Chart | Daily Interactions | X: `DateTable[Date]`, Y: `[Total Interactions]` | Stroke: 3px, Markers: On |
| 1.9 | Donut Chart | License Split | Legend: `[LicenseStatus]`, Values: `[Total Interactions]` | Inner: 50%, Labels: Category + % |
| 1.10 | Bar Chart | By Application | Y: `[AppHost]`, X: `[Total Interactions]` | App-specific colors, Data labels: On |
| 1.11 | Treemap | By Department | Category: `[Department]`, Values: `[Total Interactions]` | Gradient: Light to #0078D4 |
| 1.12 | Card | Last Refresh | `[Last Refresh Date]` | 10pt, subtle styling |

## Page 2: User Analytics

| # | Visual Type | Title | Data Fields | Key Settings |
|---|-------------|-------|-------------|--------------|
| 2.1 | Slicer | Department | `[Department]` | Style: Dropdown |
| 2.2 | Slicer | License Status | `[LicenseStatus]` | Style: Tile/Buttons |
| 2.3 | Slicer | Search User | `[DisplayName]` | Style: Dropdown, Search: On |
| 2.4 | Bar Chart | Top 10 Users | Y: `[DisplayName]`, X: `[Total Interactions]` | Filter: Top N = 10 |
| 2.5 | Stacked Column | Users by License (Monthly) | X: `[YearMonth]`, Y: `[Unique Users]`, Legend: `[LicenseStatus]` | Colors: Green/Amber |
| 2.6 | Table | User Details | DisplayName, Department, JobTitle, LicenseStatus, Interactions | Conditional: License bg, Data bars |

## Page 3: Application Analysis

| # | Visual Type | Title | Data Fields | Key Settings |
|---|-------------|-------|-------------|--------------|
| 3.1 | Card | Word | `[Word Interactions]` | Color: #2B579A |
| 3.2 | Card | Teams | `[Teams Interactions]` | Color: #6264A7 |
| 3.3 | Card | Excel | `[Excel Interactions]` | Color: #217346 |
| 3.4 | Card | PowerPoint | `[PowerPoint Interactions]` | Color: #B7472A |
| 3.5 | Stacked Area | App Trend | X: `[Date]`, Y: `[Total Interactions]`, Legend: `[AppHost]` | App-specific colors |
| 3.6 | Matrix | Dept × App | Rows: `[Department]`, Cols: `[AppHost]`, Values: `[Total Interactions]` | Gradient background |
| 3.7 | Scatter | Adoption | X: `[Total Interactions]`, Y: `[Unique Users]`, Legend: `[AppHost]`, Size: Interactions | Bubble sizing |

## Page 4: Usage Patterns

| # | Visual Type | Title | Data Fields | Key Settings |
|---|-------------|-------|-------------|--------------|
| 4.1 | Matrix | Heatmap | Rows: `[DayOfWeek]`, Cols: `[Hour]`, Values: `[Total Interactions]` | Gradient: Gray→Blue |
| 4.2 | Column Chart | By Hour | X: `[Hour]`, Y: `[Total Interactions]` | Conditional colors for peaks |
| 4.3 | Line Chart | Weekly Trend | X: `[Date]`, Y: `[Total Interactions]` | Trend line: On, Forecast: 7 days |
| 4.4 | Donut Chart | Weekday/Weekend | Legend: `[DayType]`, Values: `[Total Interactions]` | Colors: Blue/Amber |

## Page 5: License Optimization

| # | Visual Type | Title | Data Fields | Key Settings |
|---|-------------|-------|-------------|--------------|
| 5.1 | Multi-row Card | Overview | Licensed, Unlicensed, Potential Savings | 16pt callout |
| 5.2 | Table | Unlicensed High Usage | DisplayName, Dept, Title, Interactions | Filter: Licensed=FALSE, Top 10 |
| 5.3 | Table | Licensed Low Usage | DisplayName, Dept, Title, Interactions | Filter: Licensed=TRUE, Bottom 10 |
| 5.4 | Column Chart | Distribution | X: Interaction Bins, Y: User Count, Legend: LicenseStatus | Stacked bars |
| 5.5 | Card | Savings | `[Savings Summary]` | Green background |

---

## Color Reference

| Element | Hex Code | Usage |
|---------|----------|-------|
| Microsoft Blue | #0078D4 | Primary, default bars |
| Licensed Green | #107C10 | Licensed status |
| Unlicensed Amber | #FFB900 | Unlicensed status |
| Warning Red | #D83B01 | Alerts, negative trends |
| Word | #2B579A | Word visuals |
| Excel | #217346 | Excel visuals |
| PowerPoint | #B7472A | PowerPoint visuals |
| Teams | #6264A7 | Teams visuals |
| Background | #FAF9F8 | Page background |
| Card Background | #FFFFFF | Visual backgrounds |
| Text Primary | #323130 | Main text |
| Text Secondary | #605E5C | Labels, subtitles |
| Border/Grid | #E1DFDD | Borders, gridlines |

---

## Key Measures Quick Reference

| Measure | Formula | Purpose |
|---------|---------|---------|
| `Total Interactions` | `COUNTROWS('CopilotUsage')` | Base metric |
| `Unique Users` | `DISTINCTCOUNT([UserPrincipalName])` | User count |
| `Licensed Users` | `CALCULATE(DISTINCTCOUNT([UPN]), [IsCopilotLicensed]=TRUE)` | Licensed count |
| `% Licensed` | `DIVIDE([Licensed Interactions], [Total Interactions])` | Percentage |
| `MoM Change` | Current vs DATEADD(-1, MONTH) | Trend |
| `7-Day Rolling Avg` | `AVERAGEX(DATESINPERIOD(-7))` | Smoothed trend |
| `Potential Savings` | `[Licensed Low Usage Users] * [License Cost]` | Optimization |

---

## Filter Configurations

| Visual | Filter Type | Configuration |
|--------|-------------|---------------|
| Top 10 Users | Top N | Field: DisplayName, Top 10 by [Total Interactions] |
| Unlicensed High Usage | Basic + Top N | IsCopilotLicensed = FALSE, Top 10 |
| Licensed Low Usage | Basic + Bottom N | IsCopilotLicensed = TRUE, Bottom 10 |
| Date Range | Between | Start/End date selection |

---

## Conditional Formatting Summary

| Visual | Column/Element | Type | Rules |
|--------|----------------|------|-------|
| User Table | License Status (bg) | Rules | Licensed=#E6F4E6, Unlicensed=#FFF4CE |
| User Table | Interactions | Data bars | Color: #0078D4 |
| Bar Charts | Bars | Rules | App-specific colors |
| Heatmap Matrix | Values (bg) | Gradient | Min=#F3F2F1, Max=#0078D4 |
| Hour Chart | Columns | Rules | Peak hours=#D83B01, Normal=#0078D4 |

---

## Slicer Sync Matrix

| Slicer | Page 1 | Page 2 | Page 3 | Page 4 | Page 5 |
|--------|--------|--------|--------|--------|--------|
| Date Range | ✓ Sync | ✓ Sync | ✓ Sync | ✓ Sync | ✓ Sync |
| Department | - | ✓ Sync | ✓ Sync | ✓ Sync | ✓ Sync |
| License Status | - | ✓ Sync | ✓ Sync | ✓ Sync | - |
| AppHost | - | - | ✓ Sync | ✓ Sync | - |

---

## Relationships Required

```
CopilotUsage[Date] ──────►  DateTable[Date]
     (Many)                    (One)
     
CopilotUsage[AppHost] ────► AppHostColors[AppHost]  (Optional)
     (Many)                    (One)
```

Mark `DateTable` as Date Table using the `Date` column.

---

## Checklist Before Publishing

- [ ] All measures created and working
- [ ] Relationships configured correctly
- [ ] DateTable marked as date table
- [ ] Theme applied
- [ ] Slicers synced across pages
- [ ] Conditional formatting applied
- [ ] Titles and labels reviewed
- [ ] Page names set correctly
- [ ] Report filters configured (exclude test accounts)
- [ ] Drillthrough configured
- [ ] Tooltips customized
- [ ] Bookmarks created
- [ ] Tested with sample data
- [ ] Row-level security (if needed)
