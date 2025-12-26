# Power BI Dashboard: M365 Copilot Chat Usage Analytics

## Overview

This guide provides everything needed to build a comprehensive Power BI dashboard for analyzing Microsoft 365 Copilot Chat usage based on the CSV exports from the `Export-CopilotChat-MultiCloud-Fixed.ps1` script.

---

## Data Source Setup

### Step 1: Connect to CSV Files

1. Open Power BI Desktop
2. **Get Data** → **Text/CSV**
3. Navigate to your export folder and select the `*_All_*.csv` file
4. Click **Transform Data** to open Power Query Editor

### Step 2: Power Query Transformations

In Power Query Editor, apply these transformations:

```powerquery-m
let
    // Load the source CSV
    Source = Csv.Document(File.Contents("C:\Path\To\CopilotChat_All_YYYYMMDD_HHMMSS.csv"),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]),
    
    // Promote headers
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    
    // Set data types
    TypedColumns = Table.TransformColumnTypes(PromotedHeaders, {
        {"TimeGeneratedUtc", type datetime},
        {"UserPrincipalName", type text},
        {"DisplayName", type text},
        {"Department", type text},
        {"JobTitle", type text},
        {"UserType", type text},
        {"IsCopilotLicensed", type logical},
        {"AppHost", type text},
        {"Workload", type text},
        {"Application", type text},
        {"Operation", type text},
        {"AccessedResources", type text},
        {"ClientIP", type text},
        {"CorrelationId", type text},
        {"ResultStatus", type text},
        {"RecordType", type text},
        {"EventId", type text},
        {"Cloud", type text}
    }),
    
    // Add calculated columns
    AddedDate = Table.AddColumn(TypedColumns, "Date", each Date.From([TimeGeneratedUtc]), type date),
    AddedHour = Table.AddColumn(AddedDate, "Hour", each Time.Hour([TimeGeneratedUtc]), Int64.Type),
    AddedDayOfWeek = Table.AddColumn(AddedHour, "DayOfWeek", each Date.DayOfWeekName([Date]), type text),
    AddedWeekNum = Table.AddColumn(AddedDayOfWeek, "WeekNumber", each Date.WeekOfYear([Date]), Int64.Type),
    AddedMonth = Table.AddColumn(AddedWeekNum, "Month", each Date.MonthName([Date]), type text),
    AddedMonthNum = Table.AddColumn(AddedMonth, "MonthNumber", each Date.Month([Date]), Int64.Type),
    
    // Clean up AppHost values
    CleanedAppHost = Table.ReplaceValue(AddedMonthNum, null, "Unknown", Replacer.ReplaceValue, {"AppHost"}),
    
    // Add License Status text for better display
    AddedLicenseStatus = Table.AddColumn(CleanedAppHost, "LicenseStatus", 
        each if [IsCopilotLicensed] = true then "Licensed" else "Unlicensed", type text)
    
in
    AddedLicenseStatus
```

### Step 3: Create a Date Table

Create a dedicated Date table for time intelligence:

```powerquery-m
let
    // Generate date range based on your data
    StartDate = #date(2024, 1, 1),
    EndDate = Date.From(DateTime.LocalNow()),
    
    // Generate list of dates
    DateList = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
    
    // Convert to table
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    
    // Set data type
    TypedDate = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),
    
    // Add date attributes
    AddYear = Table.AddColumn(TypedDate, "Year", each Date.Year([Date]), Int64.Type),
    AddMonth = Table.AddColumn(AddYear, "Month", each Date.MonthName([Date]), type text),
    AddMonthNum = Table.AddColumn(AddMonth, "MonthNumber", each Date.Month([Date]), Int64.Type),
    AddQuarter = Table.AddColumn(AddMonthNum, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddWeekNum = Table.AddColumn(AddQuarter, "WeekNumber", each Date.WeekOfYear([Date]), Int64.Type),
    AddDayOfWeek = Table.AddColumn(AddWeekNum, "DayOfWeek", each Date.DayOfWeekName([Date]), type text),
    AddDayOfWeekNum = Table.AddColumn(AddDayOfWeek, "DayOfWeekNumber", each Date.DayOfWeek([Date]), Int64.Type),
    AddIsWeekend = Table.AddColumn(AddDayOfWeekNum, "IsWeekend", 
        each if Date.DayOfWeek([Date]) >= 5 then true else false, type logical),
    AddYearMonth = Table.AddColumn(AddIsWeekend, "YearMonth", 
        each Text.From([Year]) & "-" & Text.PadStart(Text.From([MonthNumber]), 2, "0"), type text)
    
in
    AddYearMonth
```

---

## DAX Measures

Create these measures in Power BI for the dashboard:

### Core Metrics

```dax
// Total Interactions
Total Interactions = COUNTROWS('CopilotUsage')

// Unique Users
Unique Users = DISTINCTCOUNT('CopilotUsage'[UserPrincipalName])

// Licensed User Interactions
Licensed Interactions = 
CALCULATE(
    COUNTROWS('CopilotUsage'),
    'CopilotUsage'[IsCopilotLicensed] = TRUE
)

// Unlicensed User Interactions  
Unlicensed Interactions = 
CALCULATE(
    COUNTROWS('CopilotUsage'),
    'CopilotUsage'[IsCopilotLicensed] = FALSE
)

// Licensed Users Count
Licensed Users = 
CALCULATE(
    DISTINCTCOUNT('CopilotUsage'[UserPrincipalName]),
    'CopilotUsage'[IsCopilotLicensed] = TRUE
)

// Unlicensed Users Count
Unlicensed Users = 
CALCULATE(
    DISTINCTCOUNT('CopilotUsage'[UserPrincipalName]),
    'CopilotUsage'[IsCopilotLicensed] = FALSE
)

// Percentage Licensed
% Licensed Interactions = 
DIVIDE([Licensed Interactions], [Total Interactions], 0)

// Percentage Unlicensed
% Unlicensed Interactions = 
DIVIDE([Unlicensed Interactions], [Total Interactions], 0)
```

### Usage Intensity Metrics

```dax
// Average Interactions per User
Avg Interactions Per User = 
DIVIDE([Total Interactions], [Unique Users], 0)

// Average Interactions per Licensed User
Avg Interactions Per Licensed User = 
DIVIDE([Licensed Interactions], [Licensed Users], 0)

// Daily Average Interactions
Daily Avg Interactions = 
AVERAGEX(
    VALUES('DateTable'[Date]),
    CALCULATE(COUNTROWS('CopilotUsage'))
)

// Peak Hour Interactions
Peak Hour = 
VAR HourlyCounts = 
    ADDCOLUMNS(
        VALUES('CopilotUsage'[Hour]),
        "Count", CALCULATE(COUNTROWS('CopilotUsage'))
    )
RETURN
    MAXX(HourlyCounts, [Count])
```

### Trend Metrics

```dax
// Interactions - Previous Period (for comparison)
Interactions Previous Period = 
CALCULATE(
    [Total Interactions],
    DATEADD('DateTable'[Date], -1, MONTH)
)

// Month over Month Change
MoM Change = 
VAR CurrentPeriod = [Total Interactions]
VAR PreviousPeriod = [Interactions Previous Period]
RETURN
    DIVIDE(CurrentPeriod - PreviousPeriod, PreviousPeriod, 0)

// MoM Change % (formatted)
MoM Change % = 
FORMAT([MoM Change], "+0.0%;-0.0%;0.0%")

// 7-Day Rolling Average
7-Day Rolling Avg = 
AVERAGEX(
    DATESINPERIOD('DateTable'[Date], MAX('DateTable'[Date]), -7, DAY),
    CALCULATE(COUNTROWS('CopilotUsage'))
)

// Week over Week Growth
WoW Growth = 
VAR CurrentWeek = [Total Interactions]
VAR PreviousWeek = 
    CALCULATE(
        [Total Interactions],
        DATEADD('DateTable'[Date], -7, DAY)
    )
RETURN
    DIVIDE(CurrentWeek - PreviousWeek, PreviousWeek, 0)
```

### Application Adoption Metrics

```dax
// Top Application
Top Application = 
FIRSTNONBLANK(
    TOPN(
        1,
        VALUES('CopilotUsage'[AppHost]),
        CALCULATE(COUNTROWS('CopilotUsage')),
        DESC
    ),
    1
)

// Application Count
Application Count = DISTINCTCOUNT('CopilotUsage'[AppHost])

// Users per Application
Users Per App = 
DIVIDE(
    [Unique Users],
    [Application Count],
    0
)
```

### Department Metrics

```dax
// Top Department by Usage
Top Department = 
FIRSTNONBLANK(
    TOPN(
        1,
        VALUES('CopilotUsage'[Department]),
        CALCULATE(COUNTROWS('CopilotUsage')),
        DESC
    ),
    1
)

// Department Adoption Rate
Department Adoption Rate = 
VAR UsersInDept = DISTINCTCOUNT('CopilotUsage'[UserPrincipalName])
VAR TotalUsers = CALCULATE(DISTINCTCOUNT('CopilotUsage'[UserPrincipalName]), ALL('CopilotUsage'[Department]))
RETURN
    DIVIDE(UsersInDept, TotalUsers, 0)
```

---

## Dashboard Layout

### Page 1: Executive Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│  M365 Copilot Chat Usage Dashboard                    [Date Slicer] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │  Total   │  │  Unique  │  │ Licensed │  │Unlicensed│            │
│  │Interacts │  │  Users   │  │  Users   │  │  Users   │            │
│  │  12,456  │  │   234    │  │   189    │  │    45    │            │
│  │  ▲ 12%   │  │  ▲ 8%    │  │  ▲ 15%   │  │  ▼ 3%    │            │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │
│                                                                     │
│  ┌────────────────────────────────┐  ┌────────────────────────────┐│
│  │   Interactions Over Time       │  │  Licensed vs Unlicensed    ││
│  │   (Line Chart - Daily/Weekly)  │  │     (Donut Chart)          ││
│  │                                │  │                            ││
│  │   ~~~~~/\~~~~~/\~~~~~          │  │      ████████              ││
│  │                                │  │    ██        ██            ││
│  └────────────────────────────────┘  └────────────────────────────┘│
│                                                                     │
│  ┌────────────────────────────────┐  ┌────────────────────────────┐│
│  │   Usage by Application         │  │  Usage by Department       ││
│  │   (Bar Chart - Horizontal)     │  │  (Treemap or Bar Chart)    ││
│  │                                │  │                            ││
│  │   Word     ████████████        │  │  ┌────┐┌──────┐┌────┐      ││
│  │   Teams    █████████           │  │  │ IT ││ Sales││Mktg│      ││
│  │   Excel    ███████             │  │  └────┘└──────┘└────┘      ││
│  │   PPT      █████               │  │                            ││
│  └────────────────────────────────┘  └────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### Page 2: User Analytics

```
┌─────────────────────────────────────────────────────────────────────┐
│  User Analytics                          [Department] [License] 🔍  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Top 10 Users by Interactions (Bar Chart)                    │  │
│  │                                                              │  │
│  │  John Smith      ██████████████████████  156                 │  │
│  │  Jane Doe        ████████████████████    142                 │  │
│  │  Bob Johnson     █████████████████       128                 │  │
│  │  ...                                                         │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐│
│  │  Users by License Status     │  │  New Users Over Time         ││
│  │  (Stacked Column Chart)      │  │  (Area Chart)                ││
│  │                              │  │                              ││
│  │  Week1 Week2 Week3 Week4     │  │     /\    /\                 ││
│  │  ███   ███   ███   ███       │  │   /    \/    \               ││
│  │  ░░░   ░░░   ░░░   ░░░       │  │  /            \__            ││
│  └──────────────────────────────┘  └──────────────────────────────┘│
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  User Details Table                                          │  │
│  │  ┌────────────┬────────────┬──────────┬─────────┬──────────┐ │  │
│  │  │ User       │ Department │ Licensed │ Total   │ Last Use │ │  │
│  │  ├────────────┼────────────┼──────────┼─────────┼──────────┤ │  │
│  │  │ J. Smith   │ Sales      │ Yes      │ 156     │ Today    │ │  │
│  │  │ J. Doe     │ Marketing  │ Yes      │ 142     │ Today    │ │  │
│  │  │ B. Johnson │ IT         │ No       │ 128     │ Yesterday│ │  │
│  │  └────────────┴────────────┴──────────┴─────────┴──────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Page 3: Application Deep Dive

```
┌─────────────────────────────────────────────────────────────────────┐
│  Application Usage Analysis                              [AppHost] │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │   Word   │  │  Teams   │  │  Excel   │  │   PPT    │            │
│  │   4,523  │  │  3,891   │  │  2,156   │  │  1,886   │            │
│  │  ▲ 18%   │  │  ▲ 12%   │  │  ▲ 5%    │  │  ▲ 22%   │            │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │  Application Usage Trend (Stacked Area Chart)                  ││
│  │                                                                ││
│  │        Word    Teams    Excel    PowerPoint    Other           ││
│  │  ████████████████████████████████████████████████████          ││
│  │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      ││
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                            ││
│  │  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒                                       ││
│  └────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐│
│  │  App Usage by Department     │  │  App Adoption Matrix         ││
│  │  (Matrix/Heatmap)            │  │  (Scatter Plot)              ││
│  │                              │  │                              ││
│  │       Word Teams Excel PPT   │  │  Users ●          ● Word     ││
│  │  IT    ███  ██   ███  █      │  │        │    ● Teams          ││
│  │  Sales ██   ███  █    ██     │  │        │  ● Excel            ││
│  │  Mktg  ███  █    ██   ███    │  │        └──────── Interactions││
│  └──────────────────────────────┘  └──────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### Page 4: Usage Patterns

```
┌─────────────────────────────────────────────────────────────────────┐
│  Usage Patterns & Trends                                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │  Usage Heatmap (Day of Week vs Hour)                           ││
│  │                                                                ││
│  │       12AM  3AM  6AM  9AM  12PM  3PM  6PM  9PM                 ││
│  │  Mon   ░    ░    ░   ███   ███  ███   ░    ░                   ││
│  │  Tue   ░    ░    ░   ███   ███  ███   ░    ░                   ││
│  │  Wed   ░    ░    ░   ███   ████ ███   ░    ░                   ││
│  │  Thu   ░    ░    ░   ███   ███  ███   ░    ░                   ││
│  │  Fri   ░    ░    ░   ██    ██   ██    ░    ░                   ││
│  │  Sat   ░    ░    ░    ░     ░    ░    ░    ░                   ││
│  │  Sun   ░    ░    ░    ░     ░    ░    ░    ░                   ││
│  └────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐│
│  │  Peak Usage Hours            │  │  Weekly Trend                ││
│  │  (Column Chart)              │  │  (Line Chart with Forecast)  ││
│  │                              │  │                              ││
│  │        ████                  │  │        /\    /\    - -       ││
│  │       █████                  │  │      /    \/    \/           ││
│  │      ███████                 │  │    /                         ││
│  │  ░░░████████░░░              │  │  /                           ││
│  │  8  9  10 11 12 1 2 3 4 5    │  │  W1  W2  W3  W4  W5  W6      ││
│  └──────────────────────────────┘  └──────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### Page 5: License Optimization

```
┌─────────────────────────────────────────────────────────────────────┐
│  License Optimization & Recommendations                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    LICENSE SUMMARY                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │  │
│  │  │  Licensed   │  │ Unlicensed  │  │  Potential  │           │  │
│  │  │   Users     │  │   Users     │  │   Savings   │           │  │
│  │  │    189      │  │     45      │  │   $4,500    │           │  │
│  │  │ Active: 156 │  │ Active: 38  │  │  per month  │           │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐│
│  │  Unlicensed Heavy Users      │  │  Licensed Low/No Usage       ││
│  │  (Candidates for License)    │  │  (Candidates for Review)     ││
│  │                              │  │                              ││
│  │  ┌──────────────────────┐    │  │  ┌──────────────────────┐   ││
│  │  │ User      │ Actions  │    │  │  │ User      │ Actions  │   ││
│  │  ├───────────┼──────────┤    │  │  ├───────────┼──────────┤   ││
│  │  │ B.Johnson │ 128      │    │  │  │ A.Williams│ 2        │   ││
│  │  │ M.Chen    │ 95       │    │  │  │ R.Taylor  │ 0        │   ││
│  │  │ S.Patel   │ 87       │    │  │  │ K.Brown   │ 1        │   ││
│  │  └──────────────────────┘    │  │  └──────────────────────┘   ││
│  └──────────────────────────────┘  └──────────────────────────────┘│
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Usage Distribution by License Status (Box Plot / Histogram) │  │
│  │                                                              │  │
│  │  Licensed:    [====|████████████████|========]               │  │
│  │  Unlicensed:  [==|██████|====]                               │  │
│  │               0    25    50    75   100   125   150          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Visualization Specifications

### Card Visuals (KPIs)

| Metric | Measure | Format | Conditional Formatting |
|--------|---------|--------|----------------------|
| Total Interactions | `[Total Interactions]` | #,##0 | None |
| Unique Users | `[Unique Users]` | #,##0 | None |
| Licensed Users | `[Licensed Users]` | #,##0 | Green background |
| Unlicensed Users | `[Unlicensed Users]` | #,##0 | Amber background |
| MoM Change | `[MoM Change %]` | +0.0%;-0.0% | Green ▲ / Red ▼ |

### Color Palette

```
Primary Blue:       #0078D4  (Microsoft Blue)
Secondary Blue:     #106EBE
Licensed Green:     #107C10
Unlicensed Amber:   #FFB900
Warning Red:        #D83B01
Background:         #FAF9F8
Card Background:    #FFFFFF
Text Primary:       #323130
Text Secondary:     #605E5C
```

### Application Colors

```
Word:        #2B579A
Excel:       #217346
PowerPoint:  #B7472A
Teams:       #6264A7
Outlook:     #0078D4
OneNote:     #7719AA
Loop:        #0F6CBD
Other:       #8A8886
```

---

## Additional DAX for License Optimization Page

```dax
// Unlicensed Users with High Usage (Candidates for License)
Unlicensed High Usage Users = 
VAR AvgInteractions = [Avg Interactions Per User]
RETURN
CALCULATE(
    DISTINCTCOUNT('CopilotUsage'[UserPrincipalName]),
    'CopilotUsage'[IsCopilotLicensed] = FALSE,
    FILTER(
        VALUES('CopilotUsage'[UserPrincipalName]),
        CALCULATE(COUNTROWS('CopilotUsage')) > AvgInteractions
    )
)

// Licensed Users with Low/No Usage (Review Candidates)
Licensed Low Usage Users = 
CALCULATE(
    DISTINCTCOUNT('CopilotUsage'[UserPrincipalName]),
    'CopilotUsage'[IsCopilotLicensed] = TRUE,
    FILTER(
        VALUES('CopilotUsage'[UserPrincipalName]),
        CALCULATE(COUNTROWS('CopilotUsage')) < 5
    )
)

// Estimated Monthly Cost per License (customize this value)
License Monthly Cost = 30  // $30 per user per month

// Potential Monthly Savings
Potential Monthly Savings = 
[Licensed Low Usage Users] * [License Monthly Cost]

// ROI per Licensed User
ROI Per Licensed User = 
DIVIDE([Licensed Interactions], [Licensed Users], 0)
```

---

## Report Filters & Slicers

### Recommended Slicers

1. **Date Range Slicer** (Between filter)
   - Field: `DateTable[Date]`
   - Style: Slider or Date picker

2. **Cloud Environment**
   - Field: `CopilotUsage[Cloud]`
   - Style: Dropdown or Buttons

3. **License Status**
   - Field: `CopilotUsage[LicenseStatus]`
   - Style: Buttons (Licensed / Unlicensed / All)

4. **Application (AppHost)**
   - Field: `CopilotUsage[AppHost]`
   - Style: Dropdown with search

5. **Department**
   - Field: `CopilotUsage[Department]`
   - Style: Dropdown with search

---

## Refresh Schedule Recommendations

| Scenario | Refresh Frequency | Method |
|----------|------------------|--------|
| Daily Monitoring | Every 24 hours | Scheduled Refresh |
| Weekly Reporting | Weekly (Monday AM) | Scheduled Refresh |
| Ad-hoc Analysis | On-demand | Manual / Button |
| Near Real-time | Every 30-60 min | Incremental + DirectQuery |

---

## Best Practices

1. **Use Bookmarks** for switching between Licensed/Unlicensed views
2. **Add Tooltips** with detailed user info on hover
3. **Enable Drillthrough** from summary to user details
4. **Add Report-level Filters** to exclude test accounts
5. **Use Sync Slicers** across pages for consistent filtering
6. **Add "Last Refreshed" timestamp** in footer
7. **Include Export to Excel** button for user lists

---

## Sample Report Theme (JSON)

Save this as `CopilotTheme.json` and import into Power BI:

```json
{
  "name": "Copilot Usage Theme",
  "dataColors": [
    "#0078D4",
    "#107C10",
    "#FFB900",
    "#D83B01",
    "#6264A7",
    "#2B579A",
    "#217346",
    "#B7472A"
  ],
  "background": "#FAF9F8",
  "foreground": "#323130",
  "tableAccent": "#0078D4",
  "visualStyles": {
    "*": {
      "*": {
        "border": [{"color": {"solid": {"color": "#E1DFDD"}}}],
        "background": [{"color": {"solid": {"color": "#FFFFFF"}}}],
        "title": [{
          "fontSize": 12,
          "fontColor": {"solid": {"color": "#323130"}},
          "fontFamily": "Segoe UI Semibold"
        }]
      }
    },
    "card": {
      "*": {
        "labels": [{
          "fontSize": 28,
          "fontColor": {"solid": {"color": "#0078D4"}}
        }],
        "categoryLabels": [{
          "fontSize": 12,
          "fontColor": {"solid": {"color": "#605E5C"}}
        }]
      }
    }
  }
}
```

---

## Next Steps

1. Run the `Export-CopilotChat-MultiCloud-Fixed.ps1` script to generate CSV data
2. Create a new Power BI report and import the CSV
3. Apply the Power Query transformations above
4. Create the Date table
5. Add the DAX measures
6. Build the visualizations following the layout guides
7. Apply the theme and configure slicers
8. Set up scheduled refresh in Power BI Service

