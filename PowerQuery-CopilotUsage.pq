// ============================================================
// Power Query M Code for Copilot Usage Dashboard
// ============================================================
// Copy and paste these queries into Power BI Power Query Editor
// Go to: Home > Advanced Editor to paste each query
// ============================================================

// ============================================================
// QUERY 1: CopilotUsage (Main Data Table)
// ============================================================
// Instructions:
// 1. In Power Query Editor, click "New Source" > "Blank Query"
// 2. Right-click the query and select "Advanced Editor"
// 3. Replace all content with the code below
// 4. Update the file path on line 4 to your CSV location
// ============================================================

let
    // UPDATE THIS PATH to your CSV file location
    FilePath = "C:\Exports\CopilotChat_All_YYYYMMDD_HHMMSS.csv",
    
    // Load the source CSV
    Source = Csv.Document(
        File.Contents(FilePath),
        [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    
    // Promote headers from first row
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    
    // Set appropriate data types
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
    
    // Add Date column (date only, no time)
    AddedDate = Table.AddColumn(TypedColumns, "Date", 
        each Date.From([TimeGeneratedUtc]), type date),
    
    // Add Hour column (0-23)
    AddedHour = Table.AddColumn(AddedDate, "Hour", 
        each Time.Hour([TimeGeneratedUtc]), Int64.Type),
    
    // Add Day of Week name
    AddedDayOfWeek = Table.AddColumn(AddedHour, "DayOfWeek", 
        each Date.DayOfWeekName([Date]), type text),
    
    // Add Day of Week number (0=Sunday, 6=Saturday)
    AddedDayOfWeekNum = Table.AddColumn(AddedDayOfWeek, "DayOfWeekNumber", 
        each Date.DayOfWeek([Date]), Int64.Type),
    
    // Add Week Number
    AddedWeekNum = Table.AddColumn(AddedDayOfWeekNum, "WeekNumber", 
        each Date.WeekOfYear([Date]), Int64.Type),
    
    // Add Month Name
    AddedMonth = Table.AddColumn(AddedWeekNum, "Month", 
        each Date.MonthName([Date]), type text),
    
    // Add Month Number
    AddedMonthNum = Table.AddColumn(AddedMonth, "MonthNumber", 
        each Date.Month([Date]), Int64.Type),
    
    // Add Year
    AddedYear = Table.AddColumn(AddedMonthNum, "Year", 
        each Date.Year([Date]), Int64.Type),
    
    // Add Year-Month for sorting
    AddedYearMonth = Table.AddColumn(AddedYear, "YearMonth", 
        each Text.From(Date.Year([Date])) & "-" & 
             Text.PadStart(Text.From(Date.Month([Date])), 2, "0"), 
        type text),
    
    // Clean up null AppHost values
    CleanedAppHost = Table.ReplaceValue(AddedYearMonth, null, "Unknown", 
        Replacer.ReplaceValue, {"AppHost"}),
    
    // Clean up null Department values
    CleanedDepartment = Table.ReplaceValue(CleanedAppHost, null, "Unknown", 
        Replacer.ReplaceValue, {"Department"}),
    
    // Add License Status text column for better display
    AddedLicenseStatus = Table.AddColumn(CleanedDepartment, "LicenseStatus", 
        each if [IsCopilotLicensed] = true then "Licensed" else "Unlicensed", 
        type text),
    
    // Add Time Period column for grouping
    AddedTimePeriod = Table.AddColumn(AddedLicenseStatus, "TimePeriod", 
        each if [Hour] >= 6 and [Hour] < 12 then "Morning (6AM-12PM)"
        else if [Hour] >= 12 and [Hour] < 17 then "Afternoon (12PM-5PM)"
        else if [Hour] >= 17 and [Hour] < 21 then "Evening (5PM-9PM)"
        else "Night (9PM-6AM)", 
        type text)
    
in
    AddedTimePeriod


// ============================================================
// QUERY 2: DateTable (Date Dimension)
// ============================================================
// Instructions:
// 1. Create another blank query
// 2. Paste this code in Advanced Editor
// 3. Adjust StartDate if needed
// ============================================================

let
    // Set your date range - adjust StartDate as needed
    StartDate = #date(2024, 1, 1),
    EndDate = Date.From(DateTime.LocalNow()),
    
    // Generate list of all dates in range
    DayCount = Duration.Days(EndDate - StartDate) + 1,
    DateList = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    
    // Convert to table
    DateTable = Table.FromList(DateList, Splitter.SplitByNothing(), {"Date"}),
    
    // Set Date type
    TypedDate = Table.TransformColumnTypes(DateTable, {{"Date", type date}}),
    
    // Add Year
    AddYear = Table.AddColumn(TypedDate, "Year", 
        each Date.Year([Date]), Int64.Type),
    
    // Add Quarter
    AddQuarter = Table.AddColumn(AddYear, "Quarter", 
        each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    
    // Add Month Name
    AddMonth = Table.AddColumn(AddQuarter, "Month", 
        each Date.MonthName([Date]), type text),
    
    // Add Month Number (for sorting)
    AddMonthNum = Table.AddColumn(AddMonth, "MonthNumber", 
        each Date.Month([Date]), Int64.Type),
    
    // Add Week Number
    AddWeekNum = Table.AddColumn(AddMonthNum, "WeekNumber", 
        each Date.WeekOfYear([Date]), Int64.Type),
    
    // Add Day of Week Name
    AddDayOfWeek = Table.AddColumn(AddWeekNum, "DayOfWeek", 
        each Date.DayOfWeekName([Date]), type text),
    
    // Add Day of Week Number (for sorting: 0=Sunday)
    AddDayOfWeekNum = Table.AddColumn(AddDayOfWeek, "DayOfWeekNumber", 
        each Date.DayOfWeek([Date]), Int64.Type),
    
    // Add Day of Month
    AddDayOfMonth = Table.AddColumn(AddDayOfWeekNum, "DayOfMonth", 
        each Date.Day([Date]), Int64.Type),
    
    // Add IsWeekend flag
    AddIsWeekend = Table.AddColumn(AddDayOfMonth, "IsWeekend", 
        each Date.DayOfWeek([Date]) >= 5, type logical),
    
    // Add IsWeekday flag
    AddIsWeekday = Table.AddColumn(AddIsWeekend, "IsWeekday", 
        each Date.DayOfWeek([Date]) < 5, type logical),
    
    // Add Year-Month for sorting
    AddYearMonth = Table.AddColumn(AddIsWeekday, "YearMonth", 
        each Text.From([Year]) & "-" & Text.PadStart(Text.From([MonthNumber]), 2, "0"), 
        type text),
    
    // Add Year-Quarter
    AddYearQuarter = Table.AddColumn(AddYearMonth, "YearQuarter", 
        each Text.From([Year]) & "-" & [Quarter], type text),
    
    // Add Month-Year display format
    AddMonthYear = Table.AddColumn(AddYearQuarter, "MonthYear", 
        each [Month] & " " & Text.From([Year]), type text),
    
    // Add relative date indicators
    Today = Date.From(DateTime.LocalNow()),
    AddIsToday = Table.AddColumn(AddMonthYear, "IsToday", 
        each [Date] = Today, type logical),
    
    AddIsLast7Days = Table.AddColumn(AddIsToday, "IsLast7Days", 
        each [Date] >= Date.AddDays(Today, -7) and [Date] <= Today, type logical),
    
    AddIsLast30Days = Table.AddColumn(AddIsLast7Days, "IsLast30Days", 
        each [Date] >= Date.AddDays(Today, -30) and [Date] <= Today, type logical),
    
    AddIsCurrentMonth = Table.AddColumn(AddIsLast30Days, "IsCurrentMonth", 
        each Date.Year([Date]) = Date.Year(Today) and Date.Month([Date]) = Date.Month(Today), 
        type logical),
    
    AddIsPreviousMonth = Table.AddColumn(AddIsCurrentMonth, "IsPreviousMonth", 
        each Date.Year([Date]) = Date.Year(Date.AddMonths(Today, -1)) and 
             Date.Month([Date]) = Date.Month(Date.AddMonths(Today, -1)), 
        type logical)
    
in
    AddIsPreviousMonth


// ============================================================
// QUERY 3: AppHostColors (Optional - for consistent coloring)
// ============================================================

let
    Source = Table.FromRecords({
        [AppHost = "Word", Color = "#2B579A", SortOrder = 1],
        [AppHost = "Excel", Color = "#217346", SortOrder = 2],
        [AppHost = "PowerPoint", Color = "#B7472A", SortOrder = 3],
        [AppHost = "Teams", Color = "#6264A7", SortOrder = 4],
        [AppHost = "Outlook", Color = "#0078D4", SortOrder = 5],
        [AppHost = "OneNote", Color = "#7719AA", SortOrder = 6],
        [AppHost = "Loop", Color = "#0F6CBD", SortOrder = 7],
        [AppHost = "Whiteboard", Color = "#00BCF2", SortOrder = 8],
        [AppHost = "M365Chat", Color = "#0078D4", SortOrder = 9],
        [AppHost = "Unknown", Color = "#8A8886", SortOrder = 99]
    }),
    TypedColumns = Table.TransformColumnTypes(Source, {
        {"AppHost", type text},
        {"Color", type text},
        {"SortOrder", Int64.Type}
    })
in
    TypedColumns


// ============================================================
// QUERY 4: DepartmentList (Optional - for filtering)
// ============================================================

let
    Source = CopilotUsage,
    UniqueDeparts = Table.Distinct(Table.SelectColumns(Source, {"Department"})),
    Sorted = Table.Sort(UniqueDeparts, {{"Department", Order.Ascending}})
in
    Sorted


// ============================================================
// RELATIONSHIPS TO CREATE (in Model view)
// ============================================================
// After loading data, create these relationships:
//
// 1. CopilotUsage[Date] → DateTable[Date] (Many to One)
// 2. CopilotUsage[AppHost] → AppHostColors[AppHost] (Many to One, optional)
//
// Mark DateTable as a Date Table:
// - Select DateTable in Model view
// - Table tools > Mark as date table > Select "Date" column
// ============================================================
