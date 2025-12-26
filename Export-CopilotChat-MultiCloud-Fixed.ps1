<# 
.SYNOPSIS
  Export Microsoft 365 Copilot Chat (CopilotInteraction) audit events for Commercial, GCC, and GCC High tenants.
  Produces All/Licensed/Unlicensed CSVs and tags each event with IsCopilotLicensed.
  Uses safe authentication defaults and runtime fallbacks to avoid WAM/parent-window errors.

.DESCRIPTION
  - Connects to Microsoft Graph in the appropriate environment:
      * Commercial & GCC: Global (graph.microsoft.com)
      * GCC High: USGov (graph.microsoft.us)
  - Connects to Exchange Online (Unified Audit Log) using a safe auth path with runtime checks:
      * Prefer DeviceCode (if the module supports -Device).
      * Fallback to interactive with warnings if -Device is unavailable.
      * Support AppOnly (client credentials / certificate) for fully unattended runs.
  - Queries Purview Unified Audit for Operation "CopilotInteraction".
  - Filters users by UserType (Member by default, excludes Guests).
  - Detects Copilot-licensed users via assigned license SKU GUIDs:
      * Auto-detect tenant Copilot SKU(s) OR
      * Provide Copilot SKU GUIDs explicitly.
  - Enriches output with DisplayName/Department/JobTitle/UserType from Entra ID.
  - Exports 3 CSVs: All, Licensed-only, Unlicensed-only.

.PREREQUISITES
  - Roles: Purview Audit Reader (or View-Only Audit Logs) and Directory read permissions.
  - Modules: ExchangeOnlineManagement (v3.0+); Microsoft.Graph (v2.0+).
  - Run in a console host (Windows PowerShell / PowerShell 7) or VS Code; avoid ISE where possible.
  - Audit retention: 180 days (Audit Standard); up to 1 year with Audit Premium/E5.

.PARAMETERS
  -Cloud              : 'Commercial', 'GCC', or 'GCCHigh'. If omitted, interactive prompt appears.
                        - Commercial: Worldwide/Global cloud
                        - GCC: Government Community Cloud (moderate)
                        - GCCHigh: Government Community Cloud High
  -StartDate/-EndDate : Date range (UTC). If omitted, interactive prompt for StartDate.
  -OutputPath         : Folder path for CSV outputs. If omitted, interactive prompt.
  -CsvBaseName        : Base name for CSV files. If omitted, interactive prompt.
  -AutoDetectSkus     : Auto-detect Copilot SKUs via Graph (enabled by default if no SKUs provided).
  -CopilotSkuIds      : Provide one or more Copilot SKU GUIDs (fallback/override).
  -BatchSizeDays      : Audit query batch size (default 7 days).
  -UserTypeFilter     : 'Member' (default), 'Guest', or 'All'. Filters both users and audit events.
  -AuthMode           : 'DeviceCode' (default), 'Interactive', or 'AppOnly'.
  -TenantId           : Required for AppOnly.
  -ClientId           : Required for AppOnly.
  -ClientSecret       : Optional for AppOnly (client secret).
  -CertThumbprint     : Optional for AppOnly (certificate-based).

.EXAMPLE (Interactive mode - prompts for cloud, dates, paths)
  .\Export-CopilotChat-MultiCloud.ps1

.EXAMPLE (Commercial, auto-detect SKUs, device code, Members only)
  .\Export-CopilotChat-MultiCloud.ps1 `
    -Cloud Commercial `
    -StartDate (Get-Date).AddDays(-30) `
    -OutputPath "D:\Exports" `
    -CsvBaseName "CopilotChat_Commercial" `
    -AutoDetectSkus `
    -AuthMode DeviceCode `
    -UserTypeFilter Member

.EXAMPLE (GCC moderate, explicit SKUs, device code)
  .\Export-CopilotChat-MultiCloud.ps1 `
    -Cloud GCC `
    -StartDate (Get-Date).AddDays(-30) `
    -OutputPath "D:\Exports" `
    -CsvBaseName "CopilotChat_GCC" `
    -CopilotSkuIds @("REPLACE-WITH-GCC-COPILOT-SKU-GUID") `
    -AuthMode DeviceCode

.EXAMPLE (GCC High, auto-detect SKUs)
  .\Export-CopilotChat-MultiCloud.ps1 `
    -Cloud GCCHigh `
    -StartDate (Get-Date).AddDays(-30) `
    -OutputPath "D:\Exports" `
    -CsvBaseName "CopilotChat_GCCHigh" `
    -AutoDetectSkus `
    -AuthMode DeviceCode

.EXAMPLE (Commercial, AppOnly w/ client secret)
  .\Export-CopilotChat-MultiCloud.ps1 `
    -Cloud Commercial `
    -StartDate (Get-Date).AddDays(-14) `
    -OutputPath "D:\Exports" `
    -CsvBaseName "CopilotChat_AppOnly" `
    -AuthMode AppOnly `
    -TenantId "<TenantId>" `
    -ClientId "<AppId>" `
    -ClientSecret "<Secret>"

.NOTES
  v2.2 - Added support for Commercial, GCC, and GCC High environments with correct endpoints.
         Interactive cloud selector, UserTypeFilter (Member/Guest/All), ISE fixes, 
         EXO v3+ syntax, Graph SDK v2+ syntax.
         
  Environment Endpoints:
    Commercial: login.microsoftonline.com, graph.microsoft.com, outlook.office365.com
    GCC:        login.microsoftonline.com, graph.microsoft.com, outlook.office365.com
    GCC High:   login.microsoftonline.us, graph.microsoft.us, outlook.office365.us
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Commercial','GCC','GCCHigh')]
    [string]$Cloud,

    [Parameter(Mandatory=$false)]
    [DateTime]$StartDate,

    [Parameter(Mandatory=$false)]
    [DateTime]$EndDate = (Get-Date).ToUniversalTime(),

    [Parameter(Mandatory=$false)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [string]$CsvBaseName,

    [Parameter(Mandatory=$false)]
    [switch]$AutoDetectSkus,

    [Parameter(Mandatory=$false)]
    [string[]]$CopilotSkuIds = @(),

    [Parameter(Mandatory=$false)]
    [int]$BatchSizeDays = 7,

    [Parameter(Mandatory=$false)]
    [ValidateSet('DeviceCode','Interactive','AppOnly')]
    [string]$AuthMode = 'DeviceCode',

    [Parameter(Mandatory=$false)]
    [string]$TenantId,

    [Parameter(Mandatory=$false)]
    [string]$ClientId,

    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,

    [Parameter(Mandatory=$false)]
    [string]$CertThumbprint,

    [Parameter(Mandatory=$false)]
    [ValidateSet('Member','Guest','All')]
    [string]$UserTypeFilter = 'Member'
)

#Requires -Version 5.1

# ========================
# HELPER FUNCTIONS
# ========================

function Test-ModuleAvailable {
    param([string]$Name, [string]$MinVersion = $null)
    $module = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $module) {
        Write-Warning "Module '$Name' not found. Install it: Install-Module $Name -Scope CurrentUser"
        return $false
    }
    if ($MinVersion -and $module.Version -lt [Version]$MinVersion) {
        Write-Warning "Module '$Name' version $($module.Version) is older than recommended $MinVersion. Consider updating."
    }
    return $true
}

function Get-GraphEnvironment {
    param([string]$Cloud)
    # GCC (moderate) uses commercial Graph endpoint; GCC High uses USGov
    switch ($Cloud) {
        'Commercial' { 'Global' }
        'GCC'        { 'Global' }      # GCC uses commercial Graph (graph.microsoft.com)
        'GCCHigh'    { 'USGov' }       # GCC High uses government Graph (graph.microsoft.us)
    }
}

function Get-EXOEnvironmentName {
    param([string]$Cloud)
    # Returns the correct -ExchangeEnvironmentName value for Connect-ExchangeOnline
    switch ($Cloud) {
        'Commercial' { $null }              # Default, no parameter needed
        'GCC'        { 'O365USGovGCC' }     # GCC moderate
        'GCCHigh'    { 'O365USGovGCCHigh' } # GCC High (use O365USGovDoD for DoD)
    }
}

function Get-TokenBaseUrl {
    param([string]$Cloud)
    # GCC uses commercial login; GCC High uses government login
    switch ($Cloud) {
        'Commercial' { 'https://login.microsoftonline.com' }
        'GCC'        { 'https://login.microsoftonline.com' }  # GCC uses commercial Azure AD
        'GCCHigh'    { 'https://login.microsoftonline.us' }   # GCC High uses government Azure AD
    }
}

function Get-ExoResource {
    param([string]$Cloud)
    # GCC uses commercial EXO endpoints; GCC High uses government EXO endpoints
    switch ($Cloud) {
        'Commercial' { 'https://outlook.office365.com/.default' }
        'GCC'        { 'https://outlook.office365.com/.default' }  # GCC uses commercial EXO
        'GCCHigh'    { 'https://outlook.office365.us/.default' }   # GCC High uses government EXO
    }
}

# Detect hosts that typically fail WAM parent-window requirement (e.g., ISE)
function Test-UnsafeHost {
    $hostName = $host.Name
    # ISE, Azure Automation, and certain remoting scenarios have WAM issues
    $unsafePatterns = @('ISE', 'ServerRemoteHost', 'Default Host')
    foreach ($pattern in $unsafePatterns) {
        if ($hostName -match $pattern) { return $true }
    }
    return $false
}

# Check if EXO module exposes a parameter
function Test-EXOParameter {
    param([string]$ParamName)
    try {
        $cmd = Get-Command Connect-ExchangeOnline -ErrorAction Stop
        return $cmd.Parameters.ContainsKey($ParamName)
    } catch { return $false }
}

# Get EXO module version
function Get-EXOModuleVersion {
    $module = Get-Module -ListAvailable -Name ExchangeOnlineManagement | 
              Sort-Object Version -Descending | Select-Object -First 1
    if ($module) { return $module.Version }
    return $null
}

# Get friendly cloud display name
function Get-CloudDisplayName {
    param([string]$Cloud)
    switch ($Cloud) {
        'Commercial' { 'Commercial (Global/Worldwide)' }
        'GCC'        { 'GCC (Government Community Cloud)' }
        'GCCHigh'    { 'GCC High (Government Community Cloud High)' }
    }
}

# ========================
# INTERACTIVE PROMPTS
# ========================

Write-Host "`n=== M365 Copilot Chat Usage Export ===" -ForegroundColor Cyan

# Cloud selection
if (-not $Cloud) {
    Write-Host "`nSelect target environment:" -ForegroundColor Yellow
    Write-Host "  [1] Commercial (Global/Worldwide)" -ForegroundColor White
    Write-Host "  [2] GCC (Government Community Cloud)" -ForegroundColor White
    Write-Host "  [3] GCC High (Government Community Cloud High)" -ForegroundColor White
    $cloudChoice = Read-Host "Enter choice (1, 2, or 3)"
    switch ($cloudChoice) {
        '1' { $Cloud = 'Commercial' }
        '2' { $Cloud = 'GCC' }
        '3' { $Cloud = 'GCCHigh' }
        default { 
            Write-Host "Invalid selection. Defaulting to Commercial." -ForegroundColor Yellow
            $Cloud = 'Commercial' 
        }
    }
}

# StartDate prompt
if (-not $StartDate) {
    Write-Host "`nEnter start date for audit search:" -ForegroundColor Yellow
    Write-Host "  Examples: '2025-01-01', '30' (days ago), 'Enter' for 30 days ago" -ForegroundColor Gray
    $startInput = Read-Host "Start date"
    if ([string]::IsNullOrWhiteSpace($startInput)) {
        $StartDate = (Get-Date).AddDays(-30)
    } elseif ($startInput -match '^\d+$') {
        $StartDate = (Get-Date).AddDays(-[int]$startInput)
    } else {
        try {
            $StartDate = [DateTime]::Parse($startInput)
        } catch {
            Write-Host "Invalid date. Defaulting to 30 days ago." -ForegroundColor Yellow
            $StartDate = (Get-Date).AddDays(-30)
        }
    }
}

# OutputPath prompt
if (-not $OutputPath) {
    $defaultPath = Join-Path $env:USERPROFILE "Documents\CopilotChatExports"
    Write-Host "`nEnter output folder path (Enter for default):" -ForegroundColor Yellow
    Write-Host "  Default: $defaultPath" -ForegroundColor Gray
    $pathInput = Read-Host "Output path"
    if ([string]::IsNullOrWhiteSpace($pathInput)) {
        $OutputPath = $defaultPath
    } else {
        $OutputPath = $pathInput
    }
}

# CsvBaseName prompt
if (-not $CsvBaseName) {
    $defaultName = "CopilotChat_$Cloud"
    Write-Host "`nEnter CSV base filename (Enter for default):" -ForegroundColor Yellow
    Write-Host "  Default: $defaultName" -ForegroundColor Gray
    $nameInput = Read-Host "Base filename"
    if ([string]::IsNullOrWhiteSpace($nameInput)) {
        $CsvBaseName = $defaultName
    } else {
        $CsvBaseName = $nameInput
    }
}

# AutoDetectSkus default to true if no SKUs provided
if (-not $AutoDetectSkus -and $CopilotSkuIds.Count -eq 0) {
    $AutoDetectSkus = $true
    Write-Host "`nNo Copilot SKUs specified. Auto-detection enabled." -ForegroundColor Gray
}

# ========================
# VALIDATION
# ========================

Write-Host "`n--- Configuration ---" -ForegroundColor Cyan
Write-Host "Cloud: $Cloud | AuthMode: $AuthMode | UserTypeFilter: $UserTypeFilter" -ForegroundColor Cyan
Write-Host "Host: $($host.Name)" -ForegroundColor Cyan

# Check for ISE and warn
$unsafeHost = Test-UnsafeHost
if ($unsafeHost) {
    Write-Warning "Running in ISE or unsupported host. Authentication may fail."
    Write-Warning "Recommendation: Run in Windows Terminal, PowerShell console, or VS Code."
    if ($AuthMode -eq 'Interactive') {
        Write-Warning "Forcing DeviceCode mode for ISE compatibility."
        $AuthMode = 'DeviceCode'
    }
}

# Validate modules
$modulesOk = $true
if (-not (Test-ModuleAvailable -Name 'ExchangeOnlineManagement' -MinVersion '3.0.0')) { $modulesOk = $false }
if (-not (Test-ModuleAvailable -Name 'Microsoft.Graph.Authentication' -MinVersion '2.0.0')) { $modulesOk = $false }
if (-not (Test-ModuleAvailable -Name 'Microsoft.Graph.Users' -MinVersion '2.0.0')) { $modulesOk = $false }

if (-not $modulesOk) {
    Write-Error "Required modules missing or outdated. Install/update and retry."
    exit 1
}

# Import modules
Import-Module ExchangeOnlineManagement -MinimumVersion 3.0.0 -ErrorAction Stop
Import-Module Microsoft.Graph.Authentication -MinimumVersion 2.0.0 -ErrorAction Stop
Import-Module Microsoft.Graph.Users -MinimumVersion 2.0.0 -ErrorAction Stop

# Validate AppOnly parameters
if ($AuthMode -eq 'AppOnly') {
    if (-not $TenantId -or -not $ClientId) {
        Write-Error "AppOnly requires -TenantId and -ClientId parameters."
        exit 1
    }
    if (-not $CertThumbprint -and -not $ClientSecret) {
        Write-Error "AppOnly requires either -CertThumbprint or -ClientSecret."
        exit 1
    }
}

# Create output folder
if (-not (Test-Path -Path $OutputPath)) { 
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null 
    Write-Host "Created output folder: $OutputPath" -ForegroundColor Gray
}

# ========================
# AUTHENTICATION - GRAPH
# ========================

Write-Host "`nConnecting to Microsoft Graph..." -ForegroundColor Cyan
$graphEnv = Get-GraphEnvironment -Cloud $Cloud
$cloudDisplayName = Get-CloudDisplayName -Cloud $Cloud
Write-Host "  Environment: $cloudDisplayName" -ForegroundColor Gray
Write-Host "  Graph endpoint: $(if ($graphEnv -eq 'USGov') { 'graph.microsoft.us' } else { 'graph.microsoft.com' })" -ForegroundColor Gray

try {
    if ($AuthMode -eq 'AppOnly') {
        if ($CertThumbprint) {
            Connect-MgGraph -Environment $graphEnv -TenantId $TenantId -ClientId $ClientId `
                -CertificateThumbprint $CertThumbprint -NoWelcome -ErrorAction Stop
        } else {
            # Client secret flow for Graph SDK v2+
            $secSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
            $clientCred = New-Object System.Management.Automation.PSCredential($ClientId, $secSecret)
            
            # Graph SDK v2 uses -ClientSecretCredential differently - need to use credential object
            # with TenantId specified
            $body = @{
                grant_type    = "client_credentials"
                client_id     = $ClientId
                client_secret = $ClientSecret
                scope         = "https://graph.microsoft.com/.default"
            }
            $tokenUrl = "$(Get-TokenBaseUrl -Cloud $Cloud)/$TenantId/oauth2/v2.0/token"
            $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
            
            Connect-MgGraph -Environment $graphEnv -AccessToken (ConvertTo-SecureString $tokenResponse.access_token -AsPlainText -Force) -NoWelcome -ErrorAction Stop
        }
    } else {
        # DeviceCode or Interactive
        $scopes = @("User.Read.All", "Directory.Read.All")
        if ($AuthMode -eq 'DeviceCode' -or $unsafeHost) {
            Write-Host "Using Device Code authentication..." -ForegroundColor Yellow
            Connect-MgGraph -Environment $graphEnv -Scopes $scopes -UseDeviceCode -NoWelcome -ErrorAction Stop
        } else {
            Connect-MgGraph -Environment $graphEnv -Scopes $scopes -NoWelcome -ErrorAction Stop
        }
    }
    Write-Host "Connected to Microsoft Graph ($graphEnv)" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Microsoft Graph: $_"
    exit 1
}

# ========================
# AUTHENTICATION - EXO
# ========================

Write-Host "`nConnecting to Exchange Online..." -ForegroundColor Cyan
$exoEnv = Get-EXOEnvironmentName -Cloud $Cloud
$eoxVersion = Get-EXOModuleVersion
$hasDeviceParam = Test-EXOParameter -ParamName 'Device'
$hasUserPrincipalName = Test-EXOParameter -ParamName 'UserPrincipalName'

Write-Host "  EXO Environment: $(if ($exoEnv) { $exoEnv } else { 'Default (Commercial)' })" -ForegroundColor Gray
Write-Host "  EXO Endpoint: $(if ($Cloud -eq 'GCCHigh') { 'outlook.office365.us' } else { 'outlook.office365.com' })" -ForegroundColor Gray
Write-Host "  Module Version: $eoxVersion | -Device available: $hasDeviceParam" -ForegroundColor Gray

try {
    $exoParams = @{
        ShowProgress = $false
        ShowBanner   = $false
    }
    
    # Add environment for GCC
    if ($exoEnv) {
        $exoParams['ExchangeEnvironmentName'] = $exoEnv
    }
    
    if ($AuthMode -eq 'AppOnly') {
        if ($CertThumbprint) {
            # Certificate-based app-only
            $exoParams['AppId'] = $ClientId
            $exoParams['CertificateThumbprint'] = $CertThumbprint
            $exoParams['Organization'] = $TenantId
            Connect-ExchangeOnline @exoParams
        } else {
            # Client secret - need to acquire token manually for EXO v3+
            Write-Host "Acquiring EXO access token..." -ForegroundColor Gray
            $tokenBase = Get-TokenBaseUrl -Cloud $Cloud
            $exoResource = Get-ExoResource -Cloud $Cloud
            
            $body = @{
                client_id     = $ClientId
                client_secret = $ClientSecret
                grant_type    = "client_credentials"
                scope         = $exoResource
            }
            
            $tokenUrl = "$tokenBase/$TenantId/oauth2/v2.0/token"
            $tokenResult = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
            
            # EXO v3+ requires SecureString for AccessToken
            $secToken = ConvertTo-SecureString $tokenResult.access_token -AsPlainText -Force
            $exoParams['AccessToken'] = $secToken
            $exoParams['Organization'] = "$TenantId.onmicrosoft.com"
            
            Connect-ExchangeOnline @exoParams
        }
    }
    elseif ($AuthMode -eq 'DeviceCode' -or $unsafeHost) {
        if ($hasDeviceParam) {
            Write-Host "Using Device Code authentication for EXO..." -ForegroundColor Yellow
            $exoParams['Device'] = $true
            Connect-ExchangeOnline @exoParams
        } else {
            Write-Warning "-Device parameter not available. Attempting standard auth (may fail in ISE)."
            try {
                Connect-ExchangeOnline @exoParams
            } catch {
                Write-Error "EXO connection failed. Please run in Windows Terminal/PowerShell console, or use -AuthMode AppOnly."
                throw
            }
        }
    }
    else {
        # Interactive
        Connect-ExchangeOnline @exoParams
    }
    Write-Host "Connected to Exchange Online" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to Exchange Online: $_"
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    exit 1
}

# ========================
# VERIFY AUDIT LOG STATUS
# ========================
Write-Host "`nVerifying Unified Audit Log status..." -ForegroundColor Cyan
try {
    $auditConfig = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($auditConfig.UnifiedAuditLogIngestionEnabled) {
        Write-Host "  [OK] Unified Audit Log ingestion is enabled" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Unified Audit Log ingestion is DISABLED" -ForegroundColor Red
        Write-Host "  Enable with: Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled `$true" -ForegroundColor Yellow
        Write-Host "  Continuing anyway - you may get no results..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [INFO] Could not verify audit config (may lack permissions): $_" -ForegroundColor Gray
}

# ========================
# LICENSE RESOLUTION
# ========================

Write-Host "`nResolving Copilot SKU(s) and user license assignments..." -ForegroundColor Cyan
$resolvedCopilotSkuIds = [System.Collections.Generic.HashSet[string]]::new()

if ($AutoDetectSkus) {
    try {
        # Get-MgSubscribedSku doesn't require ConsistencyLevel
        $skus = Get-MgSubscribedSku -All
        foreach ($sku in $skus) {
            # Check SKU name and service plans for Copilot indicators
            $isCopilot = $sku.SkuPartNumber -match 'COPILOT'
            if (-not $isCopilot -and $sku.ServicePlans) {
                $isCopilot = ($sku.ServicePlans | Where-Object { 
                    $_.ServicePlanName -match 'COPILOT' -or $_.ServicePlanName -match 'MCOCOPILOT' 
                }) -ne $null
            }
            if ($isCopilot) { 
                [void]$resolvedCopilotSkuIds.Add($sku.SkuId.ToString())
                Write-Host "  Found Copilot SKU: $($sku.SkuPartNumber) ($($sku.SkuId))" -ForegroundColor Gray
            }
        }
        Write-Host "Detected $($resolvedCopilotSkuIds.Count) Copilot SKU(s)" -ForegroundColor Green
    } catch { 
        Write-Warning "Auto-detect SKUs failed: $_" 
    }
}

# Add any explicitly provided SKU IDs
foreach ($id in $CopilotSkuIds) { 
    [void]$resolvedCopilotSkuIds.Add($id) 
}

if ($resolvedCopilotSkuIds.Count -eq 0) { 
    Write-Warning "No Copilot SKU GUIDs resolved. All users will show as unlicensed."
    Write-Warning "Use -CopilotSkuIds to specify SKU GUIDs, or ensure -AutoDetectSkus finds valid SKUs."
}

# Pull users and flag license status (filtered by UserType)
Write-Host "Fetching user directory (UserType: $UserTypeFilter)..." -ForegroundColor Cyan
$licensedUsers = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$allUsers = @()
$memberUPNs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

try {
    # Graph SDK v2 with proper paging
    $userProps = @("id", "userPrincipalName", "displayName", "department", "jobTitle", "assignedLicenses", "userType")
    
    # Apply userType filter unless 'All' selected
    if ($UserTypeFilter -eq 'All') {
        $users = Get-MgUser -All -Property $userProps -ErrorAction Stop
    } else {
        $users = Get-MgUser -All -Property $userProps -Filter "userType eq '$UserTypeFilter'" -ErrorAction Stop
    }
    
    foreach ($u in $users) {
        $allUsers += $u
        [void]$memberUPNs.Add($u.UserPrincipalName)
        
        if ($resolvedCopilotSkuIds.Count -gt 0 -and $u.AssignedLicenses) {
            foreach ($license in $u.AssignedLicenses) {
                if ($resolvedCopilotSkuIds.Contains($license.SkuId.ToString())) {
                    [void]$licensedUsers.Add($u.UserPrincipalName)
                    break
                }
            }
        }
    }
    Write-Host "Users fetched: $($allUsers.Count) | Copilot-licensed: $($licensedUsers.Count)" -ForegroundColor Green
} catch {
    Write-Warning "Failed to fetch users: $_"
    Write-Warning "Continuing without license enrichment..."
}

# ========================
# AUDIT QUERY (BATCHED)
# ========================

# Define all known Copilot-related operations to search for
$copilotOperations = @(
    "CopilotInteraction",
    "Copilot",
    "MicrosoftCopilot",
    "CopilotMessage"
)

function Get-CopilotAuditBatch {
    param(
        [DateTime]$BatchStart, 
        [DateTime]$BatchEnd,
        [string[]]$Operations
    )
    
    $events = @()
    $attempt = 0
    $maxAttempts = 3
    
    do {
        $attempt++
        try {
            # Search for each operation type
            foreach ($operation in $Operations) {
                $results = Search-UnifiedAuditLog `
                    -StartDate $BatchStart.ToUniversalTime() `
                    -EndDate $BatchEnd.ToUniversalTime() `
                    -Operations $operation `
                    -ResultSize 5000 `
                    -ErrorAction SilentlyContinue
                
                if ($results) {
                    foreach ($r in $results) {
                        $auditData = $null
                        $appHost = $null
                        try { 
                            $auditData = $r.AuditData | ConvertFrom-Json 
                            if ($auditData.CopilotEventData) {
                                $appHost = $auditData.CopilotEventData.AppHost
                            }
                        } catch {}
                        
                        $events += [PSCustomObject]@{
                            TimeGeneratedUtc  = $r.CreationDate.ToUniversalTime()
                            UserPrincipalName = $r.UserIds
                            UserType          = $r.UserType
                            Operation         = $r.Operations
                            Workload          = $auditData.Workload
                            AppHost           = $appHost
                            Application       = $auditData.Application
                            AccessedResources = if ($auditData.AccessedResources) { ($auditData.AccessedResources | ConvertTo-Json -Compress) } else { $null }
                            ClientIP          = $auditData.ClientIP
                            CorrelationId     = $auditData.CorrelationId
                            ResultStatus      = $auditData.ResultStatus
                            RecordType        = $r.RecordType
                            EventId           = $r.Identity
                        }
                    }
                }
            }
            
            # Also try RecordType-based search for CopilotInteraction (261)
            try {
                $rtResults = Search-UnifiedAuditLog `
                    -StartDate $BatchStart.ToUniversalTime() `
                    -EndDate $BatchEnd.ToUniversalTime() `
                    -RecordType "CopilotInteraction" `
                    -ResultSize 5000 `
                    -ErrorAction SilentlyContinue
                    
                if ($rtResults) {
                    foreach ($r in $rtResults) {
                        # Avoid duplicates by checking EventId
                        $existingIds = $events | ForEach-Object { $_.EventId }
                        if ($r.Identity -notin $existingIds) {
                            $auditData = $null
                            $appHost = $null
                            try { 
                                $auditData = $r.AuditData | ConvertFrom-Json 
                                if ($auditData.CopilotEventData) {
                                    $appHost = $auditData.CopilotEventData.AppHost
                                }
                            } catch {}
                            
                            $events += [PSCustomObject]@{
                                TimeGeneratedUtc  = $r.CreationDate.ToUniversalTime()
                                UserPrincipalName = $r.UserIds
                                UserType          = $r.UserType
                                Operation         = $r.Operations
                                Workload          = $auditData.Workload
                                AppHost           = $appHost
                                Application       = $auditData.Application
                                AccessedResources = if ($auditData.AccessedResources) { ($auditData.AccessedResources | ConvertTo-Json -Compress) } else { $null }
                                ClientIP          = $auditData.ClientIP
                                CorrelationId     = $auditData.CorrelationId
                                ResultStatus      = $auditData.ResultStatus
                                RecordType        = $r.RecordType
                                EventId           = $r.Identity
                            }
                        }
                    }
                }
            } catch {
                # RecordType search may not be available in all environments
            }
            
            return $events
        } catch {
            Write-Warning "Audit search attempt $attempt failed: $_"
            if ($attempt -lt $maxAttempts) {
                Start-Sleep -Seconds (5 * $attempt)
            }
        }
    } while ($attempt -lt $maxAttempts)
    
    return $events
}

Write-Host "`nQuerying Purview Audit for Copilot events..." -ForegroundColor Cyan
Write-Host "Operations: $($copilotOperations -join ', ')" -ForegroundColor Gray
Write-Host "Date range: $($StartDate.ToString('yyyy-MM-dd HH:mm')) to $($EndDate.ToString('yyyy-MM-dd HH:mm')) UTC" -ForegroundColor Gray

$cursor = $StartDate.ToUniversalTime()
$final = $EndDate.ToUniversalTime()
$allEvents = @()

while ($cursor -lt $final) {
    $batchStart = $cursor
    $batchEnd = [DateTime]::SpecifyKind($cursor.AddDays($BatchSizeDays), [DateTimeKind]::Utc)
    if ($batchEnd -gt $final) { $batchEnd = $final }
    
    Write-Host "  Batch: $($batchStart.ToString('yyyy-MM-dd')) -> $($batchEnd.ToString('yyyy-MM-dd'))" -ForegroundColor DarkCyan
    
    $batchEvents = Get-CopilotAuditBatch -BatchStart $batchStart -BatchEnd $batchEnd -Operations $copilotOperations
    if ($batchEvents) { 
        $allEvents += $batchEvents 
        Write-Host "    Found $($batchEvents.Count) events" -ForegroundColor Gray
    }
    $cursor = $batchEnd
}

Write-Host "Total Copilot events: $($allEvents.Count)" -ForegroundColor Green

# Show breakdown by operation if events found
if ($allEvents.Count -gt 0) {
    $byOperation = $allEvents | Group-Object Operation
    Write-Host "Events by operation:" -ForegroundColor Gray
    foreach ($grp in $byOperation) {
        Write-Host "  - $($grp.Name): $($grp.Count)" -ForegroundColor Gray
    }
    
    # Show breakdown by AppHost (which app generated the events)
    $byAppHost = $allEvents | Where-Object { $_.AppHost } | Group-Object AppHost | Sort-Object Count -Descending
    if ($byAppHost) {
        Write-Host "Events by Application (AppHost):" -ForegroundColor Gray
        foreach ($grp in $byAppHost) {
            Write-Host "  - $($grp.Name): $($grp.Count)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "`n[!] No Copilot events found. Possible causes:" -ForegroundColor Yellow
    Write-Host "    1. Audit logging not enabled - Check: Get-AdminAuditLogConfig" -ForegroundColor Gray
    Write-Host "    2. Copilot not actively used in date range (Word, Excel, PPT, Teams)" -ForegroundColor Gray
    Write-Host "    3. Audit latency - Events can take 30-60 min (up to 24 hrs) to appear" -ForegroundColor Gray
    Write-Host "    4. OUTLOOK DOES NOT LOG COPILOT - This is a known limitation" -ForegroundColor Yellow
    Write-Host "    5. Microsoft Copilot (free/Bing) may not log to Unified Audit" -ForegroundColor Gray
    Write-Host "`n    Run Test-CopilotAuditDiagnostics.ps1 for detailed troubleshooting" -ForegroundColor Cyan
}

# ========================
# ENRICH AND EXPORT
# ========================

Write-Host "`nEnriching events with directory data..." -ForegroundColor Cyan

# Build lookup table
$dirLookup = @{}
foreach ($u in $allUsers) {
    $dirLookup[$u.UserPrincipalName] = [PSCustomObject]@{
        DisplayName = $u.DisplayName
        Department  = $u.Department
        JobTitle    = $u.JobTitle
        UserType    = $u.UserType
    }
}

# Enrich events and filter by UserType
$enriched = @()
$filteredOutCount = 0

foreach ($e in $allEvents) {
    $meta = $dirLookup[$e.UserPrincipalName]
    
    # Filter: Skip if UserTypeFilter is not 'All' and user is not in our filtered set
    if ($UserTypeFilter -ne 'All' -and $memberUPNs.Count -gt 0) {
        if (-not $memberUPNs.Contains($e.UserPrincipalName)) {
            $filteredOutCount++
            continue
        }
    }
    
    $isLicensed = $licensedUsers.Contains($e.UserPrincipalName)
    
    $enriched += [PSCustomObject]@{
        TimeGeneratedUtc  = $e.TimeGeneratedUtc
        UserPrincipalName = $e.UserPrincipalName
        DisplayName       = $meta.DisplayName
        Department        = $meta.Department
        JobTitle          = $meta.JobTitle
        UserType          = if ($meta.UserType) { $meta.UserType } else { "Unknown" }
        IsCopilotLicensed = $isLicensed
        AppHost           = $e.AppHost
        Workload          = $e.Workload
        Application       = $e.Application
        Operation         = $e.Operation
        AccessedResources = $e.AccessedResources
        ClientIP          = $e.ClientIP
        CorrelationId     = $e.CorrelationId
        ResultStatus      = $e.ResultStatus
        RecordType        = $e.RecordType
        EventId           = $e.EventId
        Cloud             = $Cloud
    }
}

if ($filteredOutCount -gt 0) {
    Write-Host "Filtered out $filteredOutCount events from non-$UserTypeFilter users" -ForegroundColor Gray
}

# Split by license status
$licensedOnly = $enriched | Where-Object { $_.IsCopilotLicensed -eq $true }
$unlicensedOnly = $enriched | Where-Object { $_.IsCopilotLicensed -eq $false }

# Export to CSV
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$allPath = Join-Path $OutputPath ($CsvBaseName + "_All_" + $timestamp + ".csv")
$licPath = Join-Path $OutputPath ($CsvBaseName + "_Licensed_" + $timestamp + ".csv")
$unlicPath = Join-Path $OutputPath ($CsvBaseName + "_Unlicensed_" + $timestamp + ".csv")

Write-Host "`nExporting CSV files..." -ForegroundColor Cyan

if ($enriched.Count -gt 0) {
    $enriched | Export-Csv -Path $allPath -NoTypeInformation -Encoding UTF8
    Write-Host "  All events ($($enriched.Count)): $allPath" -ForegroundColor Gray
} else {
    Write-Warning "No events to export."
}

if ($licensedOnly.Count -gt 0) {
    $licensedOnly | Export-Csv -Path $licPath -NoTypeInformation -Encoding UTF8
    Write-Host "  Licensed ($($licensedOnly.Count)): $licPath" -ForegroundColor Gray
} else {
    Write-Host "  Licensed: No events" -ForegroundColor Gray
}

if ($unlicensedOnly.Count -gt 0) {
    $unlicensedOnly | Export-Csv -Path $unlicPath -NoTypeInformation -Encoding UTF8
    Write-Host "  Unlicensed ($($unlicensedOnly.Count)): $unlicPath" -ForegroundColor Gray
} else {
    Write-Host "  Unlicensed: No events" -ForegroundColor Gray
}

# ========================
# CLEANUP
# ========================

Write-Host "`nDisconnecting..." -ForegroundColor Cyan
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
Disconnect-MgGraph -ErrorAction SilentlyContinue

Write-Host "`n=== Export Complete ===" -ForegroundColor Green

# Summary
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Cloud environment: $Cloud" -ForegroundColor White
Write-Host "  User filter: $UserTypeFilter only" -ForegroundColor White
Write-Host "  Date range: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
Write-Host "  Total events (after filter): $($enriched.Count)" -ForegroundColor White
Write-Host "  Licensed user events: $($licensedOnly.Count)" -ForegroundColor White
Write-Host "  Unlicensed user events: $($unlicensedOnly.Count)" -ForegroundColor White
Write-Host "  Output folder: $OutputPath" -ForegroundColor White
