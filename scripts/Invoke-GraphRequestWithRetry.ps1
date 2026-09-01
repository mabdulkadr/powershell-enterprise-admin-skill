<#
.TITLE
    Invoke-GraphRequestWithRetry

.SYNOPSIS
    Canonical Microsoft Graph API retry wrapper.

.DESCRIPTION
    The single source of truth for resilient Graph API calls in enterprise PowerShell tools.
    Handles transient network errors, HTTP 429 throttling (with exponential or Retry-After backoff),
    HTTP 5xx server errors, and maps HTTP 403 errors to actionable missing-role guidance.

.TAGS
    Graph,Resilience,Retry

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.1.0

.CHANGELOG
    1.1.0 (2026-08-20)
    - Canonical rich header upgrade to Enterprise Standards field order
    1.0.0 - Initial release

.LASTUPDATE
    2026-08-20

.PARAMETER MaxRetries
    Maximum retry attempts for transient errors (429, 5xx). Default is 3.

.PARAMETER Headers
    Hashtable of custom headers to include with the request.

.PARAMETER Service
    Target service name for 403 error message mapping ('EntraID', 'Intune', 'Autopilot', 'Exchange', 'Defender', 'Teams', 'SharePoint').

.PARAMETER BaseDelaySeconds
    Base delay interval in seconds for backoff. Default is 2.

.PARAMETER Method
    HTTP method (GET, POST, PATCH, PUT, DELETE). Default is GET.

.PARAMETER Uri
    The Microsoft Graph API URI to call.

.PARAMETER ContentType
    Content type for the request body. Default is 'application/json'.

.PARAMETER Body
    Request body payload.

.EXAMPLE
    Invoke-GraphRequestWithRetry -Uri 'https://graph.microsoft.com/v1.0/devices' -Service 'EntraID'
.NOTES
    - Retry helper — exponential backoff capped at 60s per _graph-canonical.md.

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function Invoke-GraphRequestWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')]
        [string]$Method = 'GET',
        [object]$Body,
        [string]$ContentType = 'application/json',
        [hashtable]$Headers = @{},
        [int]$MaxRetries = 3,
        [int]$BaseDelaySeconds = 2,
        [ValidateSet('EntraID', 'Intune', 'Autopilot', 'Exchange', 'Defender', 'Teams', 'SharePoint')]
        [string]$Service
    )

    $attempt = 0
    do {
        $attempt++
        try {
            $params = @{
                Uri         = $Uri
                Method      = $Method
                Headers     = $Headers
                ErrorAction = 'Stop'
            }
            if ($PSBoundParameters.ContainsKey('Body')) {
                $params.Body = $Body
                $params.ContentType = $ContentType
            }
            return Invoke-MgGraphRequest @params
        }
        catch {
            $status = $null
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $status = [int]$_.Exception.Response.StatusCode
            }
            elseif ($_.Exception.Message -match '(?:Graph error|HTTP)\s+(\d{3})\b') {
                $status = [int]$Matches[1]
            }

            if ($status -eq 403 -and $PSBoundParameters.ContainsKey('Service')) {
                $msg = if (Get-Command Get-Graph403Message -ErrorAction SilentlyContinue) {
                    Get-Graph403Message -Service $Service
                } else {
                    "Missing administrative permissions for service: $Service"
                }
                throw "Permission denied (HTTP 403): $msg"
            }

            # Retry only on transient errors: HTTP 429 or 5xx server errors
            $isTransient = ($status -eq 429) -or ($status -ge 500 -and $status -lt 600)
            if ($isTransient) {
                if ($attempt -gt $MaxRetries) {
                    throw
                }
                # Honor Retry-After header for 429, else exponential backoff
                $retryAfter = $null
                try {
                    if ($_.Exception.Response -and $_.Exception.Response.Headers) {
                        $retryAfter = $_.Exception.Response.Headers['Retry-After']
                        if (-not $retryAfter) { $retryAfter = $_.Exception.Response.Headers['retry-after'] }
                    }
                } catch [System.Exception] {
                    $retryAfter = $null
                }
                $delay = if ($retryAfter -and [int]::TryParse($retryAfter.ToString().Split(',')[0], [ref]$null)) { [int]$retryAfter.ToString().Split(',')[0] } else { if ($status -eq 429) { [Math]::Min(60, $BaseDelaySeconds * [Math]::Pow(2, $attempt - 1)) } else { $BaseDelaySeconds * [Math]::Pow(2, $attempt - 1) } }
                Write-Warning "Graph request throttled or transient error (HTTP $status), retrying in $delay seconds (attempt $attempt/$MaxRetries)..."
                Start-Sleep -Seconds $delay
                continue
            }

            throw
        }
    } while ($true)
}