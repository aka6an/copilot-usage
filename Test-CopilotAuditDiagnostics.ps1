<#
.SYNOPSIS
  Diagnostic script to troubleshoot Copilot audit logging issues.
  Run this AFTER connecting to Exchange Online to identify why CopilotInteraction events aren't appearing.

.NOTES
  Known limitations (as of 2024-2025):
  - Outlook clients (OWA, desktop) do NOT log Copilot interactions for drafting/summarizing
  - Microsoft Copilot (free/Bing Chat Enterprise) may not log to Unified Audit
  - M365 Copilot in Word, Excel, PowerPoint, Teams SHOULD log interactions
  - Audit events can take 30-60 minutes (sometimes up to 24 hours) to appear
  
.EXAMPLE
  # After connecting to EXO:
  Connect-ExchangeOnline
  .\Test-CopilotAuditDiagnostics.ps1 -DaysBack 14
#>

param(
    [int]$DaysBack = 7
)

Write-Host "`n=== Copilot Audit Diagnostics ===" -ForegroundColor Cyan
Write-Host "Checking audit configuration and searching for Copilot-related events...`n" -ForegroundColor Gray

$startDate = (Get-Date).AddDays(-$DaysBack)
$endDate = Get-Date

# ========================
# CHECK 1: Verify Audit is Enabled
# ========================
Write-Host "1. Checking Unified Audit Log Status..." -ForegroundColor Yellow
try {
    $auditConfig = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($auditConfig.UnifiedAuditLogIngestionEnabled) {
        Write-Host "   [OK] Unified Audit Log ingestion is ENABLED" -ForegroundColor Green
    } else {
        Write-Host "   [FAIL] Unified Audit Log ingestion is DISABLED" -ForegroundColor Red
        Write-Host "   Run: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [WARN] Could not check audit config: $_" -ForegroundColor Yellow
    Write-Host "   You may need Organization Management or Audit Logs role" -ForegroundColor Gray
}

# ========================
# CHECK 2: Test Basic Audit Access
# ========================
Write-Host "`n2. Testing Basic Audit Log Access..." -ForegroundColor Yellow
try {
    $testSearch = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -ResultSize 1 -ErrorAction Stop
    if ($testSearch) {
        Write-Host "   [OK] Audit log access confirmed - found events" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] Audit log accessible but no events found in last $DaysBack days" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [FAIL] Cannot access audit log: $_" -ForegroundColor Red
    Write-Host "   Verify you have: View-Only Audit Logs or Audit Logs role in Purview" -ForegroundColor Yellow
}

# ========================
# CHECK 3: Search by RecordType CopilotInteraction (most reliable)
# ========================
Write-Host "`n3. Searching by RecordType 'CopilotInteraction' (RecordType 261)..." -ForegroundColor Yellow
Write-Host "   Date range: $($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
$copilotEvents = $null
try {
    $copilotEvents = Search-UnifiedAuditLog `
        -StartDate $startDate -EndDate $endDate `
        -RecordType CopilotInteraction `
        -ResultSize 100 `
        -ErrorAction Stop
        
    if ($copilotEvents) {
        Write-Host "   [OK] Found $($copilotEvents.Count) CopilotInteraction events!" -ForegroundColor Green
        
        # Analyze by AppHost (which app was used)
        $byAppHost = $copilotEvents | ForEach-Object {
            try {
                $data = $_.AuditData | ConvertFrom-Json
                $data.CopilotEventData.AppHost
            } catch { "Unknown" }
        } | Where-Object { $_ } | Group-Object | Sort-Object Count -Descending
        
        if ($byAppHost) {
            Write-Host "   Events by Application (AppHost):" -ForegroundColor Cyan
            foreach ($grp in $byAppHost) {
                Write-Host "      - $($grp.Name): $($grp.Count) events" -ForegroundColor White
            }
        }
        
        # Show unique users
        $uniqueUsers = $copilotEvents | Select-Object -ExpandProperty UserIds -Unique
        Write-Host "   Unique users with Copilot activity: $($uniqueUsers.Count)" -ForegroundColor Cyan
        
    } else {
        Write-Host "   [WARN] No CopilotInteraction events found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [FAIL] Search failed: $_" -ForegroundColor Red
}

# ========================
# CHECK 4: Search for Operation Name variations
# ========================
Write-Host "`n4. Searching by Operation Names..." -ForegroundColor Yellow

$copilotOperations = @(
    "CopilotInteraction",
    "Copilot",
    "MicrosoftCopilot"
)

$foundOperations = @{}

foreach ($op in $copilotOperations) {
    Write-Host "   Checking operation: $op..." -ForegroundColor Gray -NoNewline
    try {
        $results = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -Operations $op -ResultSize 50 -ErrorAction SilentlyContinue
        if ($results) {
            $count = $results.Count
            Write-Host " Found $count event(s)" -ForegroundColor Green
            $foundOperations[$op] = $count
        } else {
            Write-Host " None" -ForegroundColor Gray
        }
    } catch {
        Write-Host " Error: $_" -ForegroundColor Red
    }
}

# ========================
# CHECK 5: Check for Copilot workload
# ========================
Write-Host "`n5. Searching by Workload and FreeText..." -ForegroundColor Yellow
try {
    # Search for "Copilot" in FreeText to catch any Copilot-related events
    $workloadResults = Search-UnifiedAuditLog -StartDate $startDate -EndDate $endDate -FreeText "Copilot" -ResultSize 100 -ErrorAction SilentlyContinue
    if ($workloadResults) {
        Write-Host "   [OK] Found $($workloadResults.Count) events with 'Copilot' reference" -ForegroundColor Green
        
        # Group by Workload
        $byWorkload = $workloadResults | ForEach-Object {
            try { ($_.AuditData | ConvertFrom-Json).Workload } catch { "Unknown" }
        } | Group-Object | Sort-Object Count -Descending
        
        Write-Host "   Workloads found:" -ForegroundColor Cyan
        foreach ($grp in $byWorkload) {
            Write-Host "      - $($grp.Name): $($grp.Count) events" -ForegroundColor White
        }
        
        # Group by Operation
        $byOp = $workloadResults | Group-Object Operations | Sort-Object Count -Descending
        Write-Host "   Operations found:" -ForegroundColor Cyan
        foreach ($grp in $byOp) {
            Write-Host "      - $($grp.Name): $($grp.Count) events" -ForegroundColor White
        }
    } else {
        Write-Host "   [WARN] No events found with 'Copilot' in FreeText" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [FAIL] FreeText search failed: $_" -ForegroundColor Red
}

# ========================
# CHECK 6: Sample a Copilot event to show structure
# ========================
if ($copilotEvents -and $copilotEvents.Count -gt 0) {
    Write-Host "`n6. Sample Event Structure..." -ForegroundColor Yellow
    $sample = $copilotEvents | Select-Object -First 1
    try {
        $auditData = $sample.AuditData | ConvertFrom-Json
        Write-Host "   CreationDate: $($sample.CreationDate)" -ForegroundColor White
        Write-Host "   UserId: $($sample.UserIds)" -ForegroundColor White
        Write-Host "   Operation: $($sample.Operations)" -ForegroundColor White
        Write-Host "   RecordType: $($sample.RecordType)" -ForegroundColor White
        if ($auditData.CopilotEventData) {
            Write-Host "   AppHost: $($auditData.CopilotEventData.AppHost)" -ForegroundColor White
            Write-Host "   ThreadId: $($auditData.CopilotEventData.ThreadId)" -ForegroundColor White
        }
    } catch {
        Write-Host "   Could not parse sample event" -ForegroundColor Gray
    }
}

# ========================
# SUMMARY
# ========================
Write-Host "`n=== Diagnostics Summary ===" -ForegroundColor Cyan

$totalFound = 0
if ($copilotEvents) { $totalFound = $copilotEvents.Count }
if ($foundOperations.Count -gt 0) {
    foreach ($key in $foundOperations.Keys) {
        if ($foundOperations[$key] -gt $totalFound) { $totalFound = $foundOperations[$key] }
    }
}

if ($totalFound -gt 0) {
    Write-Host "`nCopilot events FOUND: $totalFound events in the last $DaysBack days" -ForegroundColor Green
    Write-Host "Your main export script should work - try running it again." -ForegroundColor Green
    Write-Host "`nIf the main script still shows 0 events, check:" -ForegroundColor Yellow
    Write-Host "  - Date range alignment (script uses UTC)" -ForegroundColor Gray
    Write-Host "  - UserType filter (are you filtering to Members only?)" -ForegroundColor Gray
} else {
    Write-Host @"

NO COPILOT EVENTS FOUND in the last $DaysBack days.

KNOWN LIMITATIONS (per Microsoft documentation):
================================================
1. OUTLOOK DOES NOT LOG COPILOT EVENTS
   - Neither OWA nor Outlook desktop capture Copilot interactions
   - This is a known gap as of 2024/2025
   - Usage may show in M365 Admin Center reports but not in audit logs

2. MICROSOFT COPILOT (FREE) vs M365 COPILOT (LICENSED)
   - Microsoft Copilot (free/Bing Chat) may not log to Unified Audit
   - Microsoft 365 Copilot in apps (Word, Excel, PPT, Teams) SHOULD log
   - "Copilot Chat" experience depends on licensing

3. COPILOT FOR SALES/SERVICE/FINANCE
   - These may use different audit mechanisms
   - Check specific product documentation

WHAT APPS SHOULD LOG COPILOT EVENTS:
====================================
+ Word (drafting, summarizing)
+ Excel (formulas, analysis)  
+ PowerPoint (creating slides, summarizing)
+ Teams (meeting summaries, chat)
+ Microsoft 365 Chat (copilot.microsoft.com for licensed users)
+ Loop
+ OneNote
+ Whiteboard

WHAT DOES NOT LOG (currently):
==============================
- Outlook (OWA, desktop - any client)
- Possibly: Free Microsoft Copilot (Bing Chat)

NEXT STEPS:
===========
a) Verify users are actively using Copilot in Word, Excel, PPT, or Teams
   (NOT just Outlook or free Microsoft Copilot)

b) Check the M365 Admin Center usage reports:
   Microsoft 365 admin center > Reports > Usage > Microsoft 365 Copilot

c) Wait 24 hours if Copilot was recently enabled

d) Check Microsoft Purview portal directly:
   purview.microsoft.com > Audit > Search
   Select "Copilot activities" > "Interacted with Copilot"

e) Consider using the Copilot Usage Report API instead:
   GET https://graph.microsoft.com/beta/reports/getMicrosoft365CopilotUsageUserDetail(period='D7')
   (Requires Reports.Read.All permission)

"@ -ForegroundColor Yellow
}

Write-Host "`nDiagnostics complete.`n" -ForegroundColor Cyan
