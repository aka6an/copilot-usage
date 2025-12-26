# Power BI Copilot Usage Dashboard - Detailed Visual Configuration Guide

## Prerequisites

Before configuring visuals, ensure you have:
1. Loaded the CSV data using the Power Query code
2. Created the DateTable
3. Added all DAX measures from the measures file
4. Created the relationship: `CopilotUsage[Date]` → `DateTable[Date]` (Many to One)
5. Applied the theme JSON file

---

# PAGE 1: EXECUTIVE SUMMARY

## Page Setup

1. **Right-click** the page tab → **Rename** → "Executive Summary"
2. **Format pane** → **Canvas settings**:
   - Type: Custom
   - Width: 1280
   - Height: 720
3. **Canvas background**:
   - Color: #FAF9F8
   - Transparency: 0%

---

## Visual 1.1: Page Title

**Type:** Text Box

**Steps:**
1. **Insert** → **Text box**
2. Enter text: "M365 Copilot Chat Usage Dashboard"
3. **Format text**:
   - Font: Segoe UI Semibold
   - Size: 24pt
   - Color: #323130
4. **Position**: X: 20, Y: 10, Width: 500, Height: 40

---

## Visual 1.2: Date Range Slicer

**Type:** Slicer

**Steps:**
1. **Visualizations** → **Slicer** icon
2. **Add field**: `DateTable[Date]`
3. **Format pane**:

| Setting | Value |
|---------|-------|
| **Slicer settings** → Style | Between |
| **Slicer settings** → Slider | On |
| **Selection** → Single select | Off |
| **Slicer header** → Title | On |
| **Slicer header** → Text | "Date Range" |
| **Slicer header** → Font | Segoe UI Semibold, 11pt |
| **Slicer header** → Font color | #323130 |
| **Values** → Font | Segoe UI, 10pt |
| **Values** → Font color | #323130 |
| **Background** → Color | #FFFFFF |
| **Border** → Color | #E1DFDD |
| **Border** → Radius | 4px |

4. **Position**: X: 900, Y: 10, Width: 360, Height: 50

---

## Visual 1.3: Total Interactions Card

**Type:** Card

**Steps:**
1. **Visualizations** → **Card** icon
2. **Add field**: Drag measure `[Total Interactions]` to **Fields**
3. **Format pane**:

| Setting | Value |
|---------|-------|
| **Callout value** → Font | Segoe UI Light |
| **Callout value** → Size | 32pt |
| **Callout value** → Color | #0078D4 |
| **Callout value** → Display units | Auto |
| **Category label** → Show | On |
| **Category label** → Text | "Total Interactions" |
| **Category label** → Font | Segoe UI |
| **Category label** → Size | 11pt |
| **Category label** → Color | #605E5C |
| **General** → Title | Off |
| **Background** → Color | #FFFFFF |
| **Border** → Show | On |
| **Border** → Color | #E1DFDD |
| **Border** → Radius | 8px |
| **Shadow** → Show | On |
| **Shadow** → Preset | Bottom right |
| **Shadow** → Transparency | 85% |

4. **Position**: X: 20, Y: 70, Width: 200, Height: 100

---

## Visual 1.4: Unique Users Card

**Type:** Card

**Steps:**
1. **Visualizations** → **Card** icon
2. **Add field**: `[Unique Users]` measure
3. **Format pane**: Same as Visual 1.3, except:

| Setting | Value |
|---------|-------|
| **Category label** → Text | "Unique Users" |

4. **Position**: X: 235, Y: 70, Width: 200, Height: 100

---

## Visual 1.5: Licensed Users Card

**Type:** Card

**Steps:**
1. **Visualizations** → **Card** icon
2. **Add field**: `[Licensed Users]` measure
3. **Format pane**: Same as Visual 1.3, except:

| Setting | Value |
|---------|-------|
| **Callout value** → Color | #107C10 (green) |
| **Category label** → Text | "Licensed Users" |

4. **Position**: X: 450, Y: 70, Width: 200, Height: 100

---

## Visual 1.6: Unlicensed Users Card

**Type:** Card

**Steps:**
1. **Visualizations** → **Card** icon
2. **Add field**: `[Unlicensed Users]` measure
3. **Format pane**: Same as Visual 1.3, except:

| Setting | Value |
|---------|-------|
| **Callout value** → Color | #FFB900 (amber) |
| **Category label** → Text | "Unlicensed Users" |

4. **Position**: X: 665, Y: 70, Width: 200, Height: 100

---

## Visual 1.7: MoM Change Card

**Type:** Card

**Steps:**
1. **Visualizations** → **Card** icon
2. **Add field**: `[MoM Change Display]` measure
3. **Format pane**: Same as Visual 1.3, except:

| Setting | Value |
|---------|-------|
| **Callout value** → Size | 24pt |
| **Category label** → Text | "vs Last Month" |

4. **Position**: X: 880, Y: 70, Width: 150, Height: 100

---

## Visual 1.8: Interactions Over Time (Line Chart)

**Type:** Line Chart

**Steps:**
1. **Visualizations** → **Line chart** icon
2. **Add fields**:
   - **X-axis**: `DateTable[Date]`
   - **Y-axis**: `[Total Interactions]` measure
   - **Secondary Y-axis**: (leave empty)
   - **Legend**: (leave empty)

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title | On |
| **General** → Title text | "Daily Copilot Interactions" |
| **General** → Title font | Segoe UI Semibold, 12pt |
| **General** → Title color | #323130 |
| **X-axis** → Show | On |
| **X-axis** → Type | Continuous |
| **X-axis** → Title | Off |
| **X-axis** → Values font | Segoe UI, 9pt |
| **X-axis** → Values color | #605E5C |
| **Y-axis** → Show | On |
| **Y-axis** → Title | Off |
| **Y-axis** → Values font | Segoe UI, 9pt |
| **Y-axis** → Values color | #605E5C |
| **Y-axis** → Gridlines | On |
| **Y-axis** → Gridline color | #E1DFDD |
| **Lines** → Stroke width | 3px |
| **Lines** → Line style | Solid |
| **Lines** → Colors | #0078D4 |
| **Markers** → Show | On |
| **Markers** → Shape | Circle |
| **Markers** → Size | 5 |
| **Data labels** → Show | Off |
| **Background** → Color | #FFFFFF |
| **Border** → Show | On |
| **Border** → Color | #E1DFDD |
| **Border** → Radius | 8px |

4. **Position**: X: 20, Y: 185, Width: 520, Height: 250

---

## Visual 1.9: Licensed vs Unlicensed (Donut Chart)

**Type:** Donut Chart

**Steps:**
1. **Visualizations** → **Donut chart** icon
2. **Add fields**:
   - **Legend**: `CopilotUsage[LicenseStatus]`
   - **Values**: `[Total Interactions]` measure

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title | On |
| **General** → Title text | "Interactions by License Status" |
| **General** → Title font | Segoe UI Semibold, 12pt |
| **Legend** → Show | On |
| **Legend** → Position | Right |
| **Legend** → Font | Segoe UI, 10pt |
| **Legend** → Color | #323130 |
| **Slices** → Inner radius | 50% |
| **Detail labels** → Show | On |
| **Detail labels** → Label style | Category, percent of total |
| **Detail labels** → Font | Segoe UI, 10pt |
| **Colors** → Licensed | #107C10 |
| **Colors** → Unlicensed | #FFB900 |
| **Background** → Color | #FFFFFF |
| **Border** → Show | On |
| **Border** → Color | #E1DFDD |
| **Border** → Radius | 8px |

4. **Position**: X: 555, Y: 185, Width: 350, Height: 250

---

## Visual 1.10: Usage by Application (Bar Chart)

**Type:** Clustered Bar Chart

**Steps:**
1. **Visualizations** → **Clustered bar chart** icon
2. **Add fields**:
   - **Y-axis**: `CopilotUsage[AppHost]`
   - **X-axis**: `[Total Interactions]` measure

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title | On |
| **General** → Title text | "Interactions by Application" |
| **General** → Title font | Segoe UI Semibold, 12pt |
| **Y-axis** → Show | On |
| **Y-axis** → Title | Off |
| **Y-axis** → Values font | Segoe UI, 10pt |
| **Y-axis** → Values color | #323130 |
| **X-axis** → Show | On |
| **X-axis** → Title | Off |
| **X-axis** → Values font | Segoe UI, 9pt |
| **X-axis** → Gridlines | On |
| **X-axis** → Gridline color | #E1DFDD |
| **Bars** → Colors | (see below) |
| **Bars** → Spacing | 30% |
| **Data labels** → Show | On |
| **Data labels** → Font | Segoe UI, 9pt |
| **Data labels** → Position | Outside end |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

**To set individual bar colors:**
1. Click on the chart
2. **Format** → **Bars** → **Colors**
3. Click **fx** (conditional formatting) → **Rules**
4. Add rules:
   - If AppHost = "Word" then #2B579A
   - If AppHost = "Excel" then #217346
   - If AppHost = "PowerPoint" then #B7472A
   - If AppHost = "Teams" then #6264A7
   - Default: #0078D4

4. **Position**: X: 20, Y: 450, Width: 410, Height: 250

---

## Visual 1.11: Usage by Department (Treemap)

**Type:** Treemap

**Steps:**
1. **Visualizations** → **Treemap** icon
2. **Add fields**:
   - **Category**: `CopilotUsage[Department]`
   - **Values**: `[Total Interactions]` measure

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title | On |
| **General** → Title text | "Interactions by Department" |
| **General** → Title font | Segoe UI Semibold, 12pt |
| **Data labels** → Show | On |
| **Data labels** → Label style | Category, data value |
| **Data labels** → Font | Segoe UI, 10pt |
| **Data labels** → Color | #FFFFFF |
| **Data labels** → Display units | Auto |
| **Colors** → Diverging | Off |
| **Colors** → Minimum | #D0E8FF |
| **Colors** → Maximum | #0078D4 |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

4. **Position**: X: 445, Y: 450, Width: 410, Height: 250

---

## Visual 1.12: Last Refresh Timestamp

**Type:** Card

**Steps:**
1. **Visualizations** → **Card** icon
2. **Add field**: `[Last Refresh Date]` measure
3. **Format pane**:

| Setting | Value |
|---------|-------|
| **Callout value** → Font | Segoe UI |
| **Callout value** → Size | 10pt |
| **Callout value** → Color | #605E5C |
| **Category label** → Show | On |
| **Category label** → Text | "Last Refreshed" |
| **Category label** → Size | 9pt |
| **Background** → Transparency | 100% |
| **Border** → Show | Off |

4. **Position**: X: 1100, Y: 690, Width: 160, Height: 30

---

# PAGE 2: USER ANALYTICS

## Page Setup

1. **Add new page** → Right-click → **Rename** → "User Analytics"
2. Apply same canvas settings as Page 1

---

## Visual 2.1: Department Slicer

**Type:** Slicer

**Steps:**
1. **Visualizations** → **Slicer** icon
2. **Add field**: `CopilotUsage[Department]`
3. **Format pane**:

| Setting | Value |
|---------|-------|
| **Slicer settings** → Style | Dropdown |
| **Selection** → Multi-select with Ctrl | On |
| **Selection** → Show "Select all" | On |
| **Slicer header** → Title text | "Department" |
| **Slicer header** → Font | Segoe UI Semibold, 11pt |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 4px |

4. **Position**: X: 20, Y: 10, Width: 180, Height: 50

---

## Visual 2.2: License Status Slicer

**Type:** Slicer

**Steps:**
1. **Visualizations** → **Slicer** icon
2. **Add field**: `CopilotUsage[LicenseStatus]`
3. **Format pane**:

| Setting | Value |
|---------|-------|
| **Slicer settings** → Style | Tile |
| **Selection** → Multi-select with Ctrl | On |
| **Slicer header** → Title text | "License Status" |
| **Values** → Font | Segoe UI, 10pt |
| **Background** → Color | #FFFFFF |

4. **Position**: X: 210, Y: 10, Width: 200, Height: 50

---

## Visual 2.3: Search Box for Users

**Type:** Slicer (with search enabled)

**Steps:**
1. **Visualizations** → **Slicer** icon
2. **Add field**: `CopilotUsage[DisplayName]`
3. **Format pane**:

| Setting | Value |
|---------|-------|
| **Slicer settings** → Style | Dropdown |
| **Search** → Show search box | On |
| **Slicer header** → Title text | "Search User" |
| **Background** → Color | #FFFFFF |

4. **Position**: X: 1050, Y: 10, Width: 210, Height: 50

---

## Visual 2.4: Top 10 Users by Interactions (Bar Chart)

**Type:** Clustered Bar Chart

**Steps:**
1. **Visualizations** → **Clustered bar chart** icon
2. **Add fields**:
   - **Y-axis**: `CopilotUsage[DisplayName]`
   - **X-axis**: `[Total Interactions]` measure

3. **Apply Top N Filter**:
   - Click on the visual
   - **Filters pane** → **Filters on this visual**
   - Expand `DisplayName`
   - **Filter type**: Top N
   - **Show items**: Top 10
   - **By value**: Drag `[Total Interactions]` measure
   - Click **Apply filter**

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title | On |
| **General** → Title text | "Top 10 Users by Copilot Interactions" |
| **General** → Title font | Segoe UI Semibold, 12pt |
| **Y-axis** → Values font | Segoe UI, 10pt |
| **Y-axis** → Maximum category width | 30% |
| **Bars** → Color | #0078D4 |
| **Bars** → Spacing | 25% |
| **Data labels** → Show | On |
| **Data labels** → Position | Outside end |
| **Data labels** → Font | Segoe UI, 9pt |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Position**: X: 20, Y: 75, Width: 600, Height: 300

---

## Visual 2.5: Users by License Status Over Time (Stacked Column)

**Type:** Stacked Column Chart

**Steps:**
1. **Visualizations** → **Stacked column chart** icon
2. **Add fields**:
   - **X-axis**: `DateTable[YearMonth]`
   - **Y-axis**: `[Unique Users]` measure
   - **Legend**: `CopilotUsage[LicenseStatus]`

3. **Sort by YearMonth**:
   - Click on the visual
   - Click **More options** (⋮) → **Sort axis** → **YearMonth**
   - Click **More options** (⋮) → **Sort axis** → **Sort ascending**

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Users by License Status (Monthly)" |
| **Legend** → Position | Top |
| **Legend** → Font | Segoe UI, 10pt |
| **X-axis** → Title | Off |
| **X-axis** → Values font | Segoe UI, 9pt |
| **Y-axis** → Title | Off |
| **Y-axis** → Values font | Segoe UI, 9pt |
| **Columns** → Colors → Licensed | #107C10 |
| **Columns** → Colors → Unlicensed | #FFB900 |
| **Data labels** → Show | Off |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Position**: X: 640, Y: 75, Width: 620, Height: 300

---

## Visual 2.6: User Details Table

**Type:** Table

**Steps:**
1. **Visualizations** → **Table** icon
2. **Add columns** (in this order):
   - `CopilotUsage[DisplayName]`
   - `CopilotUsage[Department]`
   - `CopilotUsage[JobTitle]`
   - `CopilotUsage[LicenseStatus]`
   - `[Total Interactions]` measure
   - `[Avg Interactions Per User]` measure

3. **Rename columns** (click column header → rename):
   - DisplayName → "User"
   - Department → "Department"
   - JobTitle → "Job Title"
   - LicenseStatus → "License"
   - Total Interactions → "Interactions"
   - Avg Interactions Per User → "Avg/User"

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title | On |
| **General** → Title text | "User Activity Details" |
| **Style presets** → Style | Alternating rows |
| **Column headers** → Font | Segoe UI Semibold, 11pt |
| **Column headers** → Background | #0078D4 |
| **Column headers** → Font color | #FFFFFF |
| **Column headers** → Text wrap | On |
| **Values** → Font | Segoe UI, 10pt |
| **Values** → Font color | #323130 |
| **Values** → Alternate background color | #F3F2F1 |
| **Values** → Text wrap | Off |
| **Grid** → Vertical gridlines | On |
| **Grid** → Vertical gridline color | #E1DFDD |
| **Grid** → Horizontal gridlines | On |
| **Grid** → Horizontal gridline color | #E1DFDD |
| **Grid** → Row padding | 4px |
| **Total** → Show | Off |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Add conditional formatting for License column**:
   - Select the visual
   - **Format** → **Cell elements** → **Background color**
   - Select column: "License"
   - Click **fx** → **Format style**: Rules
   - Rule 1: If value = "Licensed" then #E6F4E6 (light green)
   - Rule 2: If value = "Unlicensed" then #FFF4CE (light amber)

6. **Add data bars for Interactions column**:
   - **Format** → **Cell elements** → **Data bars**
   - Select column: "Interactions"
   - Toggle On
   - Positive bar: #0078D4
   - Show bar only: Off

7. **Position**: X: 20, Y: 390, Width: 1240, Height: 320

---

# PAGE 3: APPLICATION DEEP DIVE

## Page Setup

1. **Add new page** → Rename → "Application Analysis"

---

## Visual 3.1-3.4: Application KPI Cards

Create 4 cards for Word, Teams, Excel, PowerPoint:

**Visual 3.1: Word Card**
1. **Card** visual
2. **Field**: `[Word Interactions]` measure
3. **Category label**: "Word"
4. **Callout value color**: #2B579A
5. **Position**: X: 20, Y: 70, Width: 200, Height: 90

**Visual 3.2: Teams Card**
1. **Card** visual
2. **Field**: `[Teams Interactions]` measure
3. **Category label**: "Teams"
4. **Callout value color**: #6264A7
5. **Position**: X: 235, Y: 70, Width: 200, Height: 90

**Visual 3.3: Excel Card**
1. **Card** visual
2. **Field**: `[Excel Interactions]` measure
3. **Category label**: "Excel"
4. **Callout value color**: #217346
5. **Position**: X: 450, Y: 70, Width: 200, Height: 90

**Visual 3.4: PowerPoint Card**
1. **Card** visual
2. **Field**: `[PowerPoint Interactions]` measure
3. **Category label**: "PowerPoint"
4. **Callout value color**: #B7472A
5. **Position**: X: 665, Y: 70, Width: 200, Height: 90

---

## Visual 3.5: Application Usage Trend (Stacked Area Chart)

**Type:** Stacked Area Chart

**Steps:**
1. **Visualizations** → **Stacked area chart** icon
2. **Add fields**:
   - **X-axis**: `DateTable[Date]`
   - **Y-axis**: `[Total Interactions]` measure
   - **Legend**: `CopilotUsage[AppHost]`

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Application Usage Over Time" |
| **Legend** → Position | Top |
| **Legend** → Font | Segoe UI, 10pt |
| **X-axis** → Type | Continuous |
| **X-axis** → Title | Off |
| **Y-axis** → Title | Off |
| **Y-axis** → Gridlines | On |
| **Colors** → Word | #2B579A |
| **Colors** → Excel | #217346 |
| **Colors** → PowerPoint | #B7472A |
| **Colors** → Teams | #6264A7 |
| **Colors** → (others) | #8A8886 |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

4. **Position**: X: 20, Y: 175, Width: 1240, Height: 250

---

## Visual 3.6: App Usage by Department (Matrix)

**Type:** Matrix

**Steps:**
1. **Visualizations** → **Matrix** icon
2. **Add fields**:
   - **Rows**: `CopilotUsage[Department]`
   - **Columns**: `CopilotUsage[AppHost]`
   - **Values**: `[Total Interactions]` measure

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Application Usage by Department" |
| **Style presets** → Style | Minimal |
| **Row headers** → Font | Segoe UI Semibold, 10pt |
| **Row headers** → Background | #F3F2F1 |
| **Column headers** → Font | Segoe UI Semibold, 10pt |
| **Column headers** → Background | #0078D4 |
| **Column headers** → Font color | #FFFFFF |
| **Values** → Font | Segoe UI, 10pt |
| **Grid** → Row padding | 6px |
| **Background** → Color | #FFFFFF |

4. **Add conditional formatting (background color)**:
   - **Format** → **Cell elements** → **Background color**
   - Apply to: Values
   - Click **fx** → **Format style**: Gradient
   - Minimum: #FFFFFF (white)
   - Maximum: #0078D4 (blue)
   - Based on: Total Interactions

5. **Position**: X: 20, Y: 440, Width: 600, Height: 270

---

## Visual 3.7: App Adoption Scatter Plot

**Type:** Scatter Chart

**Steps:**
1. **Visualizations** → **Scatter chart** icon
2. **Add fields**:
   - **X-axis**: `[Total Interactions]` measure
   - **Y-axis**: `[Unique Users]` measure
   - **Legend**: `CopilotUsage[AppHost]`
   - **Size**: `[Total Interactions]` measure

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Application Adoption (Users vs Interactions)" |
| **X-axis** → Title | On |
| **X-axis** → Title text | "Total Interactions" |
| **X-axis** → Font | Segoe UI, 9pt |
| **Y-axis** → Title | On |
| **Y-axis** → Title text | "Unique Users" |
| **Y-axis** → Font | Segoe UI, 9pt |
| **Legend** → Position | Right |
| **Markers** → Shape | Circle |
| **Markers** → Size range | 10 - 50 |
| **Colors** → Word | #2B579A |
| **Colors** → Excel | #217346 |
| **Colors** → PowerPoint | #B7472A |
| **Colors** → Teams | #6264A7 |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

4. **Position**: X: 640, Y: 440, Width: 620, Height: 270

---

# PAGE 4: USAGE PATTERNS

## Page Setup

1. **Add new page** → Rename → "Usage Patterns"

---

## Visual 4.1: Usage Heatmap (Day × Hour)

**Type:** Matrix (styled as heatmap)

**Steps:**
1. **Visualizations** → **Matrix** icon
2. **Add fields**:
   - **Rows**: `CopilotUsage[DayOfWeek]`
   - **Columns**: `CopilotUsage[Hour]`
   - **Values**: `[Total Interactions]` measure

3. **Sort days correctly**:
   - Go to **Data view**
   - Select `DayOfWeek` column
   - **Column tools** → **Sort by column** → `DayOfWeekNumber`

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Usage Heatmap (Day of Week × Hour)" |
| **Style presets** → Style | None |
| **Row headers** → Font | Segoe UI, 10pt |
| **Row headers** → Background | Transparent |
| **Column headers** → Font | Segoe UI, 9pt |
| **Column headers** → Background | Transparent |
| **Column headers** → Alignment | Center |
| **Values** → Font | Segoe UI, 9pt |
| **Values** → Alignment | Center |
| **Grid** → Show vertical gridlines | Off |
| **Grid** → Show horizontal gridlines | Off |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Add background color conditional formatting**:
   - **Format** → **Cell elements** → **Background color**
   - Apply to: Values
   - Click **fx** → **Format style**: Gradient
   - Minimum: #F3F2F1 (light gray)
   - Center: #A8D4FF (light blue)
   - Maximum: #0078D4 (dark blue)
   - Based on: Total Interactions

6. **Position**: X: 20, Y: 70, Width: 1240, Height: 280

---

## Visual 4.2: Peak Usage Hours (Column Chart)

**Type:** Clustered Column Chart

**Steps:**
1. **Visualizations** → **Clustered column chart** icon
2. **Add fields**:
   - **X-axis**: `CopilotUsage[Hour]`
   - **Y-axis**: `[Total Interactions]` measure

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Interactions by Hour of Day" |
| **X-axis** → Type | Categorical |
| **X-axis** → Title text | "Hour (24h)" |
| **X-axis** → Title font | Segoe UI, 9pt |
| **X-axis** → Values font | Segoe UI, 9pt |
| **Y-axis** → Title | Off |
| **Y-axis** → Gridlines | On |
| **Columns** → Colors | #0078D4 |
| **Columns** → Spacing | 15% |
| **Data labels** → Show | Off |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

4. **Add conditional formatting for peak hours**:
   - **Format** → **Columns** → **Colors** → **fx**
   - **Format style**: Rules
   - Rule 1: If value >= (90th percentile) then #D83B01 (orange - peak)
   - Rule 2: If value >= (50th percentile) then #0078D4 (blue)
   - Default: #B4D4FF (light blue)

5. **Position**: X: 20, Y: 365, Width: 600, Height: 250

---

## Visual 4.3: Weekly Trend with Forecast (Line Chart)

**Type:** Line Chart with Analytics

**Steps:**
1. **Visualizations** → **Line chart** icon
2. **Add fields**:
   - **X-axis**: `DateTable[Date]`
   - **Y-axis**: `[Total Interactions]` measure

3. **Add Trend Line**:
   - Select the visual
   - **Analytics pane** (chart icon with magnifying glass)
   - **Trend line** → Toggle On
   - Color: #FF0000 (red)
   - Style: Dashed
   - Transparency: 50%

4. **Add Forecast** (optional):
   - **Analytics pane** → **Forecast**
   - Toggle On
   - Forecast length: 7 days
   - Confidence interval: 95%
   - Style: Dotted
   - Confidence band color: #E1DFDD

5. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Weekly Trend with Forecast" |
| **Lines** → Stroke width | 3px |
| **Lines** → Color | #0078D4 |
| **Markers** → Show | On |
| **Markers** → Size | 4 |
| **X-axis** → Type | Continuous |
| **Y-axis** → Gridlines | On |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

6. **Position**: X: 640, Y: 365, Width: 620, Height: 250

---

## Visual 4.4: Weekday vs Weekend (Donut)

**Type:** Donut Chart

**Steps:**
1. **Visualizations** → **Donut chart** icon
2. **Create a calculated column or use measure**:

First, create a measure:
```dax
Weekday/Weekend = 
IF(
    SELECTEDVALUE(DateTable[IsWeekend]) = TRUE,
    "Weekend",
    "Weekday"
)
```

Or use `DateTable[IsWeekend]` directly.

3. **Add fields**:
   - **Legend**: Create a calculated column `DayType = IF([DayOfWeekNumber] >= 5, "Weekend", "Weekday")`
   - **Values**: `[Total Interactions]` measure

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "Weekday vs Weekend Usage" |
| **Legend** → Position | Right |
| **Slices** → Inner radius | 60% |
| **Colors** → Weekday | #0078D4 |
| **Colors** → Weekend | #FFB900 |
| **Detail labels** → Show | On |
| **Detail labels** → Label style | Category, percent of total |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Position**: X: 20, Y: 630, Width: 300, Height: 180
   (Note: Adjust page height if needed)

---

# PAGE 5: LICENSE OPTIMIZATION

## Page Setup

1. **Add new page** → Rename → "License Optimization"

---

## Visual 5.1: License Summary Header

**Type:** Multi-row Card

**Steps:**
1. **Visualizations** → **Multi-row card** icon
2. **Add fields**:
   - `[Licensed Users]`
   - `[Unlicensed Users]`
   - `[Potential Monthly Savings]`

3. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "License Overview" |
| **Data labels** → Font | Segoe UI Semibold, 16pt |
| **Data labels** → Color | #323130 |
| **Category labels** → Font | Segoe UI, 10pt |
| **Category labels** → Color | #605E5C |
| **Card** → Outline | Bottom only |
| **Card** → Bar thickness | 4px |
| **Card** → Padding | 10px |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

4. **Position**: X: 20, Y: 70, Width: 600, Height: 120

---

## Visual 5.2: Unlicensed High-Usage Users Table

**Type:** Table

**Steps:**
1. **Visualizations** → **Table** icon
2. **Add columns**:
   - `CopilotUsage[DisplayName]`
   - `CopilotUsage[Department]`
   - `CopilotUsage[JobTitle]`
   - `[Total Interactions]` measure

3. **Add filter** (Filters pane):
   - Filter: `CopilotUsage[IsCopilotLicensed]` = FALSE
   - Filter: Top N on `[Total Interactions]`, Top 10

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "🎯 Unlicensed Users with High Usage (License Candidates)" |
| **Column headers** → Background | #FFB900 |
| **Column headers** → Font color | #323130 |
| **Values** → Font | Segoe UI, 10pt |
| **Style presets** → Alternating rows |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Add data bars** for Interactions column

6. **Position**: X: 20, Y: 205, Width: 600, Height: 250

---

## Visual 5.3: Licensed Low-Usage Users Table

**Type:** Table

**Steps:**
1. **Visualizations** → **Table** icon
2. **Add columns**:
   - `CopilotUsage[DisplayName]`
   - `CopilotUsage[Department]`
   - `CopilotUsage[JobTitle]`
   - `[Total Interactions]` measure

3. **Add filters** (Filters pane):
   - Filter: `CopilotUsage[IsCopilotLicensed]` = TRUE
   - Filter: Bottom N on `[Total Interactions]`, Bottom 10

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "⚠️ Licensed Users with Low Usage (Review for Optimization)" |
| **Column headers** → Background | #107C10 |
| **Column headers** → Font color | #FFFFFF |
| **Values** → Font | Segoe UI, 10pt |
| **Style presets** → Alternating rows |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Add data bars** for Interactions column

6. **Position**: X: 640, Y: 205, Width: 620, Height: 250

---

## Visual 5.4: Usage Distribution Box Plot (or Histogram)

**Type:** Histogram (using Python/R visual) or Clustered Column Chart approximation

**Alternative using Clustered Column:**
1. Create bins for interaction counts:

```dax
Interaction Bin = 
VAR UserInteractions = [Total Interactions]
RETURN
    SWITCH(
        TRUE(),
        UserInteractions = 0, "0",
        UserInteractions <= 5, "1-5",
        UserInteractions <= 10, "6-10",
        UserInteractions <= 25, "11-25",
        UserInteractions <= 50, "26-50",
        UserInteractions <= 100, "51-100",
        "100+"
    )
```

2. **Visualizations** → **Clustered column chart**
3. **Add fields**:
   - **X-axis**: Create a calculated column with bins
   - **Y-axis**: Count of users
   - **Legend**: `LicenseStatus`

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **General** → Title text | "User Distribution by Interaction Volume" |
| **Legend** → Position | Top |
| **Columns** → Colors → Licensed | #107C10 |
| **Columns** → Colors → Unlicensed | #FFB900 |
| **X-axis** → Title text | "Interaction Count Range" |
| **Y-axis** → Title text | "Number of Users" |
| **Background** → Color | #FFFFFF |
| **Border** → Radius | 8px |

5. **Position**: X: 20, Y: 470, Width: 850, Height: 240

---

## Visual 5.5: Savings Calculator Card

**Type:** Card with Custom Measure

**Steps:**
1. Create measure:
```dax
Savings Summary = 
VAR LowUsageCount = [Licensed Low Usage Users]
VAR CostPerLicense = [License Monthly Cost]
VAR MonthlySavings = LowUsageCount * CostPerLicense
VAR AnnualSavings = MonthlySavings * 12
RETURN
    "Potential savings: $" & FORMAT(MonthlySavings, "#,##0") & "/month" &
    " ($" & FORMAT(AnnualSavings, "#,##0") & "/year)"
```

2. **Visualizations** → **Card** icon
3. **Add field**: `[Savings Summary]` measure

4. **Format pane**:

| Setting | Value |
|---------|-------|
| **Callout value** → Font | Segoe UI Semibold |
| **Callout value** → Size | 18pt |
| **Callout value** → Color | #107C10 |
| **Category label** → Show | On |
| **Category label** → Text | "License Optimization Opportunity" |
| **Background** → Color | #E6F4E6 |
| **Border** → Color | #107C10 |
| **Border** → Radius | 8px |

5. **Position**: X: 890, Y: 470, Width: 370, Height: 100

---

# FINAL STEPS

## 1. Sync Slicers Across Pages

1. **View** → **Sync slicers**
2. Select each slicer
3. Check which pages it should sync to
4. Recommended: Sync Date slicer to all pages

---

## 2. Add Bookmarks for Quick Views

1. **View** → **Bookmarks**
2. Create bookmarks:
   - "All Users" (no filters)
   - "Licensed Only" (LicenseStatus = Licensed)
   - "Unlicensed Only" (LicenseStatus = Unlicensed)
3. Add bookmark buttons to each page

---

## 3. Enable Drillthrough

1. On User Analytics page, select the User Details table
2. **Visualizations** → **Add drillthrough fields**
3. Add `CopilotUsage[UserPrincipalName]`
4. Now users can right-click on any user in other visuals → Drillthrough → User Analytics

---

## 4. Add Tooltips

1. Create a new page → Rename "User Tooltip"
2. **Format** → **Page information** → **Page type**: Tooltip
3. **Canvas settings** → Size: Tooltip
4. Add small visuals:
   - Card: `[Total Interactions]`
   - Card: `[LicenseStatus]`
   - Card: Last activity date
5. On other visuals, **Format** → **Tooltip** → Page: "User Tooltip"

---

## 5. Configure Row-Level Security (Optional)

If you need department-based security:
1. **Modeling** → **Manage roles**
2. Create role "DepartmentUsers"
3. Add filter: `[Department] = USERPRINCIPALNAME()`
4. Publish and assign members in Power BI Service

---

## 6. Publish and Schedule Refresh

1. **File** → **Publish** → Select workspace
2. In Power BI Service:
   - Dataset settings → Data source credentials
   - Scheduled refresh → Configure daily/weekly refresh
   - Set email notifications for refresh failures

---

# APPENDIX: CREATING REQUIRED CALCULATED COLUMNS

Add these calculated columns in Power Query or DAX:

**In Power Query (recommended):**
Already included in the Power Query file.

**In DAX (if needed):**

```dax
// Add to CopilotUsage table
DayType = IF(WEEKDAY([TimeGeneratedUtc], 2) > 5, "Weekend", "Weekday")

TimePeriod = 
SWITCH(
    TRUE(),
    HOUR([TimeGeneratedUtc]) >= 6 && HOUR([TimeGeneratedUtc]) < 12, "Morning",
    HOUR([TimeGeneratedUtc]) >= 12 && HOUR([TimeGeneratedUtc]) < 17, "Afternoon",
    HOUR([TimeGeneratedUtc]) >= 17 && HOUR([TimeGeneratedUtc]) < 21, "Evening",
    "Night"
)
```

---

This completes the detailed visual configuration guide. Each visual includes exact settings, positions, and formatting to create a professional, cohesive dashboard.
