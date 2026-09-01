<#
.TITLE
    Invoke-GraphBatchRequest

.SYNOPSIS
    Canonical Microsoft Graph $batch helper for bulk requests.

.DESCRIPTION
    Sends up to 20 Graph sub-requests per POST /$batch, auto-chunking larger sets,
    and retries only the sub-requests that failed with 429/5xx using exponential backoff.
    Returns a List of per-request response objects for caller correlation.

.TAGS
    Graph,Batch,BulkOperations

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
    Maximum retry attempts for throttled/failed sub-requests. Default is 3.

.PARAMETER ApiVersion
    Graph API version to use ('beta' or 'v1.0'). Default is 'beta'.

.PARAMETER Requests
    Array of sub-request objects/hashtables. Each must contain 'id', 'method', and 'url'.

.EXAMPLE
    $requests = @(
    @{ id = "1"; method = "GET"; url = "/deviceManagement/managedDevices('dev-1')" },
    @{ id = "2"; method = "GET"; url = "/deviceManagement/managedDevices('dev-2')" }
    )
    $responses = Invoke-GraphBatchRequest -Requests $requests
.NOTES
    - Batch helper — respects 20-request limit per _graph-canonical.md.

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
function Invoke-GraphBatchRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Requests,
        [ValidateSet('beta', 'v1.0')]
        [string]$ApiVersion = 'beta',
        [int]$MaxRetries = 3
    )

    $allResponses = [System.Collections.Generic.List[PSCustomObject]]::new()
    $chunkSize = 20
    $batchUrl = "https://graph.microsoft.com/$ApiVersion/`$batch"

    for ($i = 0; $i -lt $Requests.Count; $i += $chunkSize) {
        $end = [Math]::Min($i + $chunkSize, $Requests.Count) - 1
        $chunk = $Requests[$i..$end]

        $batchBody = @{ requests = @($chunk) } | ConvertTo-Json -Depth 10
        $batchResponse = Invoke-GraphRequestWithRetry -Uri $batchUrl -Method POST -Body $batchBody -ContentType 'application/json'

        if (-not $batchResponse.responses) { continue }

        # Split responses: successful now vs retryable (429 or 5xx)
        $retryable = @($batchResponse.responses | Where-Object { $_.status -eq 429 -or ($_.status -ge 500 -and $_.status -lt 600) })
        $retryableIds = if ($retryable) { @($retryable | ForEach-Object { "$($_.id)" }) } else { @() }

        foreach ($resp in $batchResponse.responses) {
            if ("$($resp.id)" -notin $retryableIds) {
                $allResponses.Add($resp)
            }
        }

        # Retry only the failed sub-requests, matched back by id
        $retryAttempt = 0
        while ($retryable.Count -gt 0 -and $retryAttempt -lt $MaxRetries) {
            $retryAttempt++
            $delay = 2 * [Math]::Pow(2, $retryAttempt - 1)
            $logMsg = "Batch: retrying $($retryable.Count) sub-request(s) (attempt $retryAttempt/$MaxRetries, delay ${delay}s)"
            if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                Write-Log -Message $logMsg -Level 'WARNING'
            } else {
                Write-Warning $logMsg
            }
            Start-Sleep -Seconds $delay

            $currentRetryIds = @($retryable | ForEach-Object { "$($_.id)" })
            $retryRequests = @($chunk | Where-Object { "$($_.id)" -in $currentRetryIds })
            $retryBody = @{ requests = @($retryRequests) } | ConvertTo-Json -Depth 10
            $retryResponse = Invoke-GraphRequestWithRetry -Uri $batchUrl -Method POST -Body $retryBody -ContentType 'application/json'

            if ($retryResponse.responses) {
                $retryable = @($retryResponse.responses | Where-Object { $_.status -eq 429 -or ($_.status -ge 500 -and $_.status -lt 600) })
                $newRetryableIds = if ($retryable) { @($retryable | ForEach-Object { "$($_.id)" }) } else { @() }

                foreach ($resp in $retryResponse.responses) {
                    if ("$($resp.id)" -notin $newRetryableIds) {
                        $allResponses.Add($resp)
                    }
                }
            } else {
                break
            }
        }

        # Still retryable after max attempts — add them so caller can inspect individual failures
        if ($retryable) {
            foreach ($failed in $retryable) {
                $allResponses.Add($failed)
            }
        }
    }

    return $allResponses
}