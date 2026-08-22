# Intune Notification Script Patterns

Patterns for building automated Intune monitoring scripts that send email alerts via Microsoft Graph Mail API.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Script Header Format (Notification-Specific)](#script-header-format-notification-specific)
3. [Azure Automation Context Detection](#azure-automation-context-detection)
4. [Authentication Patterns](#authentication-patterns)
5. [Email Notification Pattern](#email-notification-pattern)
6. [HTML Email Template](#html-email-template)
7. [Alert Classification Pattern](#alert-classification-pattern)
8. [Monitoring Data Pattern](#monitoring-data-pattern)
9. [Complete Notification Script Template](#complete-notification-script-template)
10. [Common Notification Scenarios](#common-notification-scenarios)

---

## Architecture

Notification scripts follow a different pattern than remediation scripts. They run on a schedule (typically via Azure Automation) and send alerts when conditions are met.

```
notification-script-name/
├── notify-<name>.ps1      # Main notification script
├── README.md              # Description, requirements, version
└── screenshot.png         # Example email (optional)
```

### Notification → Remediation Flow

```
Notification Script runs on schedule
  ├── Gather monitoring data from Graph API
  ├── Analyze data against thresholds
  ├── If issues found → Send email notification
  └── If no issues → Exit silently
```

### Key Differences from Remediation Scripts

| Aspect | Remediation | Notification |
|--------|-------------|--------------|
| **Trigger** | Health condition (exit code) | Schedule (time-based) |
| **Action** | Fix the issue | Alert about the issue |
| **Output** | Exit code + JSON | Email via Graph API |
| **Context** | SYSTEM (Intune) | Managed Identity (Azure Automation) |
| **Scope** | Single device | Fleet-wide monitoring |

---

## Script Header Format (Notification-Specific)

Notification scripts use extended header fields to indicate they're designed for Azure Automation runbooks:

```powershell
<#
.TITLE
    [Notification Script Title - Brief descriptive name]

.SYNOPSIS
    Automated runbook to monitor [specific Intune aspect] and send email alerts.

.DESCRIPTION
    This script is designed to run as a scheduled Azure Automation runbook that monitors
    [specific functionality] in Microsoft Intune and identifies [specific conditions].
    It sends email notifications to administrators with detailed reports.

    Key Features:
    - Monitors [specific aspect] across [scope]
    - Configurable thresholds
    - Email notifications with HTML formatted reports
    - Supports both Azure Automation and local execution

.TAGS
    Notification,[Category],RunbookOnly,Email,Monitoring

.PLATFORM
    Windows

.MINROLE
    Intune Administrator

.PERMISSIONS
    DeviceManagementManagedDevices.Read.All,Mail.Send

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.EXECUTION
    RunbookOnly

.OUTPUT
    Email

.SCHEDULE
    Daily

.CATEGORY
    Notification

.EXAMPLE
    .\notify-compliance-alert.ps1 -Threshold 85 -EmailRecipients "admin@company.com"
    Sends compliance alert if compliance rate drops below 85%

.EXAMPLE
    .\notify-compliance-alert.ps1 -Threshold 90 -EmailRecipients "admin@company.com,security@company.com"
    Sends compliance alert to multiple recipients

.NOTES
    - Requires Microsoft.Graph.Authentication and Microsoft.Graph.Mail modules
    - For Azure Automation, configure Managed Identity with required permissions
    - Email notifications are sent via Microsoft Graph Mail API
#>
```

### Notification-Specific Header Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `.EXECUTION` | Yes | `RunbookOnly` — indicates this runs in Azure Automation |
| `.OUTPUT` | Yes | `Email` — indicates the primary output is email |
| `.SCHEDULE` | Yes | `Daily`, `Weekly`, `Hourly` — expected run frequency |
| `.CATEGORY` | Yes | `Notification` — script category for discoverability |

**Why these fields matter:** `.EXECUTION` tells reviewers this script requires Azure Automation. `.OUTPUT` indicates it sends email (needs `Mail.Send` permission). `.SCHEDULE` helps operators plan runbook frequency.

---

## Azure Automation Context Detection

Detect whether the script is running in Azure Automation or locally. This determines the authentication method:

```powershell
$RunningInAzureAutomation = $null -ne $env:AUTOMATION_ASSET_ACCOUNTID
```

**Why this matters:** Azure Automation Runbooks use Managed Identity (no user interaction). Local execution requires interactive sign-in. The same script should support both contexts.

---

## Authentication Patterns

**The canonical auth matrix is `scripts/Connect-GraphAuth.ps1`** (Managed Identity / Interactive / MgGraphCommunity / Client Credentials, plus the combined pattern). The snippets below show the notification-specific scopes; for full code copy the canonical file.

### Managed Identity (Azure Automation)

```powershell
try {
    Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
    Write-Output "Connected to Microsoft Graph using Managed Identity"
}
catch {
    Write-Error "Failed to connect using Managed Identity: $($_.Exception.Message)"
    exit 2
}
```

### Interactive (Local Execution)

```powershell
try {
    $Scopes = @(
        'DeviceManagementManagedDevices.Read.All'
        'DeviceManagementConfiguration.Read.All'
        'Mail.Send'
    )
    Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
    Write-Output "Connected to Microsoft Graph with interactive authentication"
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 2
}
```

### Combined Pattern (Recommended)

```powershell
try {
    if ($RunningInAzureAutomation) {
        Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
        Write-Output "Connected using Managed Identity"
    } else {
        $Scopes = @(
            'DeviceManagementManagedDevices.Read.All'
            'Mail.Send'
        )
        Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
        Write-Output "Connected with interactive authentication"
    }
}
catch {
    Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 2
}
```

**Why the combined pattern?** It lets you test the script locally (interactive) before deploying to Azure Automation (Managed Identity). Same script, zero changes.

---

## Email Notification Pattern

### Send Email via Graph Mail API

```powershell
function Send-EmailNotification {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Body,
        [Parameter(Mandatory = $true)]
        [array]$Recipients,
        [Parameter(Mandatory = $true)]
        [string]$Subject,
        [ValidateSet("Low", "Normal", "High")]
        [string]$Priority = "Normal"
    )

    try {
        $ToRecipients = @()
        foreach ($Recipient in $Recipients) {
            $ToRecipients += @{
                emailAddress = @{
                    address = $Recipient.Trim()
                }
            }
        }

        $Message = @{
            subject = $Subject
            body = @{
                contentType = "HTML"
                content = $Body
            }
            toRecipients = $ToRecipients
            importance = $Priority.ToLower()
        }

        $RequestBody = @{
            message = $Message
            saveToSentItems = $false
        } | ConvertTo-Json -Depth 10

        $Uri = "https://graph.microsoft.com/v1.0/me/sendMail"
        Invoke-MgGraphRequest -Uri $Uri -Method POST -Body $RequestBody -ContentType "application/json"

        Write-Output "Email sent to: $($Recipients -join ', ')"
        return $true
    }
    catch {
        Write-Error "Failed to send email: $($_.Exception.Message)"
        return $false
    }
}
```

**Why `saveToSentItems = $false`?** Managed Identity doesn't have a mailbox. Setting this to `$true` would cause an error.

**Why `-Depth 10` on `ConvertTo-Json`?** Nested hashtable structures (like `toRecipients`) get truncated at the default depth of 2.

---

## HTML Email Template

Notification emails should use responsive HTML with clear visual hierarchy. Here's the canonical template:

### Template Structure

```powershell
function New-EmailBody {
    param(
        [Parameter(Mandatory = $true)]
        [array]$AlertData,
        [Parameter(Mandatory = $true)]
        [hashtable]$Summary
    )

    # Determine alert level
    $AlertLevel = if ($Summary.CriticalCount -gt 0) { "Critical" }
                  elseif ($Summary.WarningCount -gt 0) { "Warning" }
                  else { "Info" }

    $AlertColor = switch ($AlertLevel) {
        "Critical" { "#dc3545" }
        "Warning" { "#ffc107" }
        "Info" { "#28a745" }
    }

    $EmailBody = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; border-radius: 8px; overflow: hidden; }
        .header { background: linear-gradient(135deg, $AlertColor 0%, #6c5ce7 100%); color: white; padding: 30px; text-align: center; }
        .content { padding: 30px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .summary-card { background: #f8f9fa; border-left: 4px solid $AlertColor; padding: 20px; border-radius: 4px; }
        .summary-card h3 { margin: 0 0 10px 0; color: #2c3e50; font-size: 14px; text-transform: uppercase; }
        .summary-card .value { font-size: 32px; font-weight: bold; color: $AlertColor; margin: 0; }
        .alert-item { background: #fff; border: 1px solid #dee2e6; border-radius: 6px; padding: 15px; margin: 10px 0; }
        .alert-item.critical { border-left: 4px solid #dc3545; }
        .alert-item.warning { border-left: 4px solid #ffc107; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Alert: [Alert Type]</h1>
            <div class="subtitle">Proactive monitoring detected conditions requiring attention</div>
        </div>
        <div class="content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Alert Level</h3>
                    <div class="value">$AlertLevel</div>
                </div>
                <div class="summary-card">
                    <h3>Critical</h3>
                    <div class="value">$($Summary.CriticalCount)</div>
                </div>
                <div class="summary-card">
                    <h3>Warning</h3>
                    <div class="value">$($Summary.WarningCount)</div>
                </div>
                <div class="summary-card">
                    <h3>Total Checked</h3>
                    <div class="value">$($Summary.TotalCount)</div>
                </div>
            </div>
            <!-- Alert items go here -->
        </div>
        <div class="footer">
            Automated notification from Intune monitoring system<br>
            Report generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        </div>
    </div>
</body>
</html>
"@

    return $EmailBody
}
```

### Why HTML Email?

- **Visual hierarchy**: Alert level, summary cards, and item lists are immediately scannable
- **Responsive**: Grid layout adapts to mobile/email clients
- **Professional**: Matches enterprise communication standards
- **Actionable**: Clear distinction between critical and warning items

---

## Alert Classification Pattern

Classify monitoring results into alert levels:

```powershell
function Get-AlertAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [array]$MonitoringData,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $AlertData = @()
    $Summary = @{
        TotalCount = $MonitoringData.Count
        CriticalCount = 0
        WarningCount = 0
        HealthyCount = 0
    }

    foreach ($Item in $MonitoringData) {
        $Level = "Info"
        $ShouldAlert = $false

        if ($Item.Status -eq "Critical") {
            $Level = "Critical"
            $ShouldAlert = $true
            $Summary.CriticalCount++
        }
        elseif ($Item.Status -eq "Warning") {
            $Level = "Warning"
            $ShouldAlert = $true
            $Summary.WarningCount++
        }
        else {
            $Summary.HealthyCount++
        }

        if ($ShouldAlert) {
            $AlertData += [PSCustomObject]@{
                Title = "Alert: $($Item.Name)"
                Details = "Status: $($Item.Status) | Value: $($Item.Value)"
                Level = $Level
            }
        }
    }

    return @{
        AlertData = $AlertData
        Summary = $Summary
    }
}
```

---

## Monitoring Data Pattern

The monitoring function is where you implement your specific logic. Here's the structure:

```powershell
function Get-MonitoringData {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    try {
        Write-Output "Gathering monitoring data..."

        # Your monitoring logic here
        # Examples:
        # - Query Graph API for device compliance
        # - Check certificate expiration dates
        # - Monitor app deployment status
        # - Track license usage

        $Results = @()

        # Example: Get all managed devices
        # $devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"

        Write-Output "Retrieved $($Results.Count) items"
        return $Results
    }
    catch {
        Write-Error "Failed to gather monitoring data: $($_.Exception.Message)"
        return @()
    }
}
```

---

## Complete Notification Script Template

Putting it all together:

```powershell
<#
.TITLE
    Notification - Compliance Alert

.SYNOPSIS
    Monitors device compliance and sends email alerts.

.DESCRIPTION
    This script monitors device compliance rates across the Intune tenant
    and sends email alerts when compliance drops below the configured threshold.

.TAGS
    Notification,Compliance,RunbookOnly,Email,Monitoring

.PLATFORM
    Windows

.MINROLE
    Intune Administrator

.PERMISSIONS
    DeviceManagementManagedDevices.Read.All,Mail.Send

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.EXECUTION
    RunbookOnly

.OUTPUT
    Email

.SCHEDULE
    Daily

.CATEGORY
    Notification

.EXAMPLE
    .\notify-compliance-alert.ps1 -Threshold 85 -EmailRecipients "admin@company.com"
    Sends alert if compliance rate drops below 85%

.NOTES
    - Requires Microsoft.Graph.Authentication and Microsoft.Graph.Mail modules
    - For Azure Automation, configure Managed Identity with required permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Compliance threshold percentage (0-100)")]
    [ValidateRange(1, 100)]
    [int]$Threshold,

    [Parameter(Mandatory = $true, HelpMessage = "Comma-separated email recipients")]
    [string]$EmailRecipients
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$SolutionName = "ComplianceAlert"
$EmailConfig = @{
    Subject = "[ALERT] Device Compliance Below $Threshold% - $(Get-Date -Format 'yyyy-MM-dd')"
    Priority = "High"
}

# ============================================================================
# MODULES AND AUTHENTICATION
# ============================================================================
# Canonical auth matrix (Managed Identity / Interactive / Client Credentials):
#   scripts/Connect-GraphAuth.ps1
$RunningInAzureAutomation = $null -ne $env:AUTOMATION_ASSET_ACCOUNTID

$RequiredModules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Mail"
)

foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Error "$Module module is required. Install using: Install-Module $Module -Scope CurrentUser"
        exit 2  # Missing module = script error
    }
    Import-Module $Module -Force
}

try {
    if ($RunningInAzureAutomation) {
        Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
    } else {
        $Scopes = @('DeviceManagementManagedDevices.Read.All', 'Mail.Send')
        Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
    }
    Write-Output "Connected to Microsoft Graph"
}
catch {
    Write-Error "Failed to connect: $($_.Exception.Message)"
    exit 2  # Script error
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
# Canonical helpers — copy verbatim from these sources, never retype:
#   - Get-MgGraphAllPages      → scripts/Get-MgGraphAllPages.ps1
#   - Send-EmailNotification   → "Send Email via Graph Mail API" section above
#   - New-EmailBody            → "HTML Email Template" section above
#   - Get-AlertAnalysis        → "Alert Classification Pattern" section above
# Only Get-MonitoringData is scenario-specific — implement it per use case:

function Get-MonitoringData {
    # Implement your monitoring logic here
    # Return array of objects with: Name, Status (Critical/Warning/OK), Value, Details
    @()
}

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

try {
    Write-Output "Starting compliance monitoring..."

    $MonitoringData = Get-MonitoringData
    if ($MonitoringData.Count -eq 0) {
        Write-Output "No data found. Exiting."
        exit 0
    }

    $Analysis = Get-AlertAnalysis -Data $MonitoringData -Threshold $Threshold
    $ShouldNotify = $Analysis.Summary.CriticalCount -gt 0 -or $Analysis.Summary.WarningCount -gt 0

    if (-not $ShouldNotify) {
        Write-Output "All compliant. No notification needed."
        exit 0
    }

    $EmailBody = New-EmailBody -AlertData $Analysis.AlertData -Summary $Analysis.Summary
    $Recipients = $EmailRecipients -split ',' | ForEach-Object { $_.Trim() }

    Send-EmailNotification -Body $EmailBody -Recipients $Recipients -Subject $EmailConfig.Subject
    Write-Output "Monitoring completed successfully"
}
catch {
    Write-Error "Script failed: $($_.Exception.Message)"
    exit 2  # Script error
}
finally {
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { }
}
```

---

## Common Notification Scenarios

### Certificate Expiration Alert

```powershell
# Monitor certificates expiring within 30 days
$certs = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations"
$expiringCerts = $certs | Where-Object {
    $_.certificateExpirationDate -lt (Get-Date).AddDays(30)
}
```

### Compliance Drift Alert

```powershell
# Monitor compliance rate dropping below threshold
$devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
$complianceRate = ($devices | Where-Object { $_.complianceState -eq "compliant" }).Count / $devices.Count * 100
if ($complianceRate -lt $Threshold) { /* alert */ }
```

### App Deployment Failure Alert

```powershell
# Monitor app deployment failures
$apps = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps"
$failedApps = $apps | Where-Object { $_.installSummary.installedCount -eq 0 }
```

### License Usage Alert

```powershell
# Monitor license usage approaching limit
$subscriptions = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/subscribedSkus"
$nearLimit = $subscriptions | Where-Object {
    ($_.consumedUnits / $_.prepaidUnits.enabled) * 100 -gt 90
}
```

---

## Reference

- **Enterprise Standards Reference**: internal skill canonical headers (`references/_header-canonical.md`)
- **Notification Template Guide**: internal notification patterns (`references/notification-patterns.md`)
- **Microsoft Graph Mail API**: https://learn.microsoft.com/en-us/graph/api/user-sendmail
