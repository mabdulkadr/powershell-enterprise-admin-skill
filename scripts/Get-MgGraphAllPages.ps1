<#
.TITLE
    Get-MgGraphAllPages

.SYNOPSIS
    Canonical Microsoft Graph pagination helper.

.DESCRIPTION
    Retrieves all pages from a Microsoft Graph API endpoint automatically following @odata.nextLink.
    Uses List[PSCustomObject] for O(1) appending performance and handles rate limiting with bounded retries.

.PARAMETER Headers
    Hashtable of optional HTTP headers (e.g. ConsistencyLevel = 'eventual').

.PARAMETER Max429Retries
    Maximum consecutive retries when encountering HTTP 429 throttling. Default is 3.

.PARAMETER Uri
    Initial Microsoft Graph endpoint URI.

.PARAMETER DelayMs
    Delay in milliseconds between page requests to avoid hitting rate limits. Default is 100.

.TAGS
    Graph,Pagination

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

.EXAMPLE
    $devices = Get-MgGraphAllPages -Uri "https://graph.microsoft.com/v1.0/devices?`$select=id,displayName"
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function Get-MgGraphAllPages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [int]$DelayMs = 100,
        [hashtable]$Headers = @{},
        [int]$Max429Retries = 3
    )

    [System.Collections.Generic.List[PSCustomObject]]$allResults = [System.Collections.Generic.List[PSCustomObject]]::new()
    $nextLink = $Uri
    $requestCount = 0
    $consecutive429 = 0

    do {
        try {
            if ($requestCount -gt 0 -and $DelayMs -gt 0) {
                Start-Sleep -Milliseconds $DelayMs
            }

            $params = @{
                Uri         = $nextLink
                Method      = 'GET'
                Headers     = $Headers
                ErrorAction = 'Stop'
            }

            $response = Invoke-MgGraphRequest @params
            $requestCount++
            $consecutive429 = 0 # Reset throttle counter on success

            if ($null -ne $response.value) {
                foreach ($item in $response.value) {
                    $allResults.Add($item)
                }
            }
            else {
                $allResults.Add($response)
            }

            $nextLink = $response.'@odata.nextLink'

            if ($requestCount % 10 -eq 0) {
                Write-Verbose "Processed $requestCount API pages, retrieved $($allResults.Count) items..."
            }
        }
        catch {
            $is429 = ($_.Exception.Message -like '*429*') -or ($_.Exception.Message -like '*throttled*')
            if ($is429) {
                $consecutive429++
                if ($consecutive429 -gt $Max429Retries) {
                    throw "Rate limit exceeded (HTTP 429). Maximum retries ($Max429Retries) reached for $nextLink"
                }
                # Honor Retry-After header if present, else exponential backoff capped at 60s
                $retryAfter = $null
                try { $retryAfter = $_.Exception.Response.Headers['Retry-After'] } catch {}
                if (-not $retryAfter) { try { $retryAfter = $_.Exception.Response.Headers['retry-after'] } catch {} }
                $delaySec = if ($retryAfter -and [int]::TryParse($retryAfter.ToString().Split(',')[0], [ref]$null)) { [int]$retryAfter.ToString().Split(',')[0] } else { [Math]::Min(60, [Math]::Pow(2, $consecutive429) * 5) }
                Write-Warning "Rate limit hit (attempt $consecutive429/$Max429Retries), waiting $delaySec seconds..."
                Start-Sleep -Seconds $delaySec
                continue
            }
            throw "Error fetching data from $nextLink : $($_.Exception.Message)"
        }
    } while ($nextLink)

    return $allResults
}