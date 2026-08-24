<#
.TITLE
    Notification - [What It Monitors]

.SYNOPSIS
    [One-line summary: monitors X and emails an HTML alert when thresholds are exceeded.]

.DESCRIPTION
    Azure Automation runbook that queries [data source] via Microsoft Graph,
    evaluates alert rules, and sends a responsive HTML email report through the
    Graph Mail API. Designed for Managed Identity authentication in runbooks and
    interactive sign-in when tested locally.

    Exit contract:
    Exit 0 = run completed (alert sent or nothing to report)
    Exit 2 = script error

.TAGS
    Notification,Monitoring

.EXECUTION
    RunbookOnly

.OUTPUT
    Email

.SCHEDULE
    Daily

.CATEGORY
    Notification

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    [DeviceManagementManagedDevices.Read.All],Mail.Send

.AUTHOR
    AI Generated

.VERSION
    1.0.0

.CHANGELOG
    1.0.0 ([YYYY-MM-DD])
    - Initial release

.LASTUPDATE
    [YYYY-MM-DD]

.EXAMPLE
    .\notify-[name].ps1
    Run inside Azure Automation with Managed Identity enabled.

.EXAMPLE
    .\notify-[name].ps1 -MailRecipient "it-alerts@contoso.com" -MailSender "notifications@contoso.com"
    Local test run with explicit recipient and sender (prompts for interactive Graph sign-in).

.NOTES
    - Declare boolean parameters as [string] and normalize with ValidateSet -
      Azure Automation passes everything as strings.
    - saveToSentItems is ALWAYS $false: the Managed Identity has no mailbox.
    - Pagination uses Get-MgGraphAllPages - never manual while-loops.
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$MailRecipient = '[it-alerts@yourdomain.com]',
    [Parameter(Mandatory = $false)]
    [string]$MailSender   = '[notifications@yourdomain.com]'
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# MODULE VALIDATION (fail before half-doing the work)
# ============================================================================

$RequiredModules = @('Microsoft.Graph.Authentication')
foreach ($module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Error "$module module is required. Install it using: Install-Module $module -Scope CurrentUser"
        exit 2
    }
}
Import-Module Microsoft.Graph.Authentication -Force -ErrorAction Stop

# ============================================================================
# CONTEXT DETECTION
# ============================================================================

$IsAzureAutomation = $null -ne $PSPrivateMetadata.JobId.Guid

# ============================================================================
# ============================================================================
# GRAPH HELPERS (canonical: scripts/Get-MgGraphAllPages.ps1)
# ============================================================================

# Dot-source the canonical Graph helpers so this template stays in sync with
# the canonical implementation (handles 429 retry, throttling, etc.).
$_scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$_canonicalGraph = Join-Path (Split-Path -Parent $_scriptRoot) 'scripts/Get-MgGraphAllPages.ps1'
if (-not (Test-Path -LiteralPath $_canonicalGraph)) {
    throw "Canonical Graph helpers not found at: $_canonicalGraph"
}
. (Get-Item -LiteralPath $_canonicalGraph).FullName

# Sends HTML mail via Graph sendMail with saveToSentItems set to false.
# Canonical implementation: scripts/Send-EmailNotification.ps1 — copy it verbatim or dot-source.
# Dot-source so the template stays in sync with the canonical implementation.
$_scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$_canonicalSend = Join-Path (Split-Path -Parent $_scriptRoot) 'scripts/Send-EmailNotification.ps1'
if (-not (Test-Path -LiteralPath $_canonicalSend)) {
    throw "Canonical Send-EmailNotification not found at: $_canonicalSend"
}
. (Get-Item -LiteralPath $_canonicalSend).FullName
# ============================================================================
# ALERT LOGIC (customize threshold + data source)
# ============================================================================

# Computes alert metrics against thresholds - customize data source here.
function Get-AlertAnalysis {
    # TODO: query your data source, evaluate rules, return:
    #   [PSCustomObject]@{ AlertCount = N; Findings = @( ...rows... ); Summary = 'text' }
    return [PSCustomObject]@{ AlertCount = 0; Findings = @(); Summary = 'No findings' }
}

# Builds the HTML email body from the analysis result object.
function New-EmailBody {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Analysis)

    $rows = ($Analysis.Findings | ForEach-Object {
        "<tr><td>$([System.Net.WebUtility]::HtmlEncode([string]$_))</td></tr>"
    }) -join "`n"

    return @"
<!DOCTYPE html>
<html><body style="font-family:'Segoe UI',Arial,sans-serif;background:#F1F5F9;padding:24px;">
<div style="max-width:900px;margin:auto;background:#FFFFFF;border:1px solid #E2E8F0;border-radius:12px;padding:20px;">
<h2 style="color:#0F172A;">[$(if ($Analysis.AlertCount -gt 0) { 'ALERT' } else { 'OK' })] [Report Title]</h2>
<p style="color:#64748B;font-size:13px;">Generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC</p>
<p style="color:#334155;font-size:13px;">$([System.Net.WebUtility]::HtmlEncode($Analysis.Summary))</p>
$(if ($rows) { "<table style='border-collapse:collapse;width:100%;font-size:13px;'><thead><tr><th style='text-align:left;background:#F1F5F9;padding:8px;'>Finding</th></tr></thead><tbody>$rows</tbody></table>" })
</div></body></html>
"@
}

# ============================================================================
# MAIN
# ============================================================================
# Flow: module check -> context detect -> connect Graph -> analyze -> build HTML -> send.

try {
    if ($IsAzureAutomation) {
        Connect-MgGraph -Identity -NoWelcome -ErrorAction Stop
        Write-Output "Authenticated with Managed Identity"
    }
    else {
        $scopes = @('[DeviceManagementManagedDevices.Read.All]', 'Mail.Send')
        Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop
        Write-Output "Authenticated interactively"
    }

    $analysis = Get-AlertAnalysis
    Write-Output "Findings: $($analysis.AlertCount)"

    $html  = New-EmailBody -Analysis $analysis
    $subject = "[Intune Alert] [Title] - $($analysis.AlertCount) finding(s)"

    Send-EmailNotification -To $MailRecipient -Subject $subject -HtmlBody $html -FromUserId $MailSender
    Write-Output "Notification sent to $MailRecipient"

    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    exit 0
}
catch {
    Write-Error "Notification run failed: $($_.Exception.Message)"
    try { Disconnect-MgGraph -ErrorAction SilentlyContinue } catch { Write-Verbose 'Graph disconnect already closed' }
    exit 2
}
