# Event Log Patterns

Patterns for querying, filtering, and analyzing Windows Event Logs for troubleshooting and monitoring.

---

## Table of Contents

1. [Why event logs matter](#why-event-logs-matter)
2. [Basic event log queries](#basic-event-log-queries)
3. [Filter syntax: Hashtable vs XPath vs XML](#filter-syntax-hashtable-vs-xpath-vs-xml)
4. [Common log channels](#common-log-channels)
5. [Performance and large-log handling](#performance-and-large-log-handling)
6. [Remote event log access](#remote-event-log-access)
7. [Export to CSV / HTML](#export-to-csv--html)
8. [Dashboard with Chart.js](#dashboard-with-chartjs)
9. [Custom event log writing](#custom-event-log-writing)

---

## Why event logs matter

Windows Event Logs are the authoritative record of what happened on a machine. They capture:

- Application crashes and restarts
- Service failures and recoveries
- Logon events (security audits)
- Driver and hardware errors
- PowerShell script block logging (ScriptBlockLogging)
- Intune / SCCM agent activity

For an enterprise admin, event logs are usually the first place to look when:
- A user reports a problem
- A service keeps failing
- You need to prove what happened during a security incident
- You're monitoring fleet health at scale (failed services across 1000 machines)

The key challenge: logs are large, noisy, and full of irrelevant noise. You need to filter precisely.

---

## Basic event log queries

### Get Recent Errors from a Single Log

```powershell
$events = Get-WinEvent -LogName "System" -MaxEvents 100 |
    Where-Object { $_.LevelDisplayName -eq "Error" }

$events | Select-Object TimeCreated, Id, ProviderName, Message |
    Format-Table -AutoSize -Wrap
```

### Get Events from the Last 24 Hours

```powershell
$startTime = (Get-Date).AddHours(-24)
$events = Get-WinEvent -LogName "Application" -FilterHashtable @{
    StartTime = $startTime
    Level     = 1, 2, 3   # Critical=1, Error=2, Warning=3
}
```

### Get Events by Event ID

```powershell
# Find all Event ID 1074 (unexpected shutdown)
$events = Get-WinEvent -LogName "System" -FilterHashtable @{
    Id        = 1074
    StartTime = (Get-Date).AddDays(-7)
}
```

### Get the Most Recent N Events from Multiple Logs

```powershell
$logs = "System", "Application"
$events = foreach ($log in $logs) {
    Get-WinEvent -LogName $log -MaxEvents 50 -ErrorAction SilentlyContinue
} | Sort-Object TimeCreated -Descending | Select-Object -First 50
```

---

## Filter syntax: Hashtable vs XPath vs XML

There are three filter mechanisms. Use them in this order of preference:

### 1. `-FilterHashtable` (Recommended — fastest, type-safe)

```powershell
Get-WinEvent -LogName "System" -FilterHashtable @{
    ProviderName = "Service Control Manager"
    Id           = 7034, 7035, 7036
    Level        = 1, 2, 3
    StartTime    = (Get-Date).AddDays(-1)
}
```

Supported keys: `LogName`, `ProviderName`, `Path`, `Id`, `Level`, `Keywords`, `UserID`, `Data`, `StartTime`, `EndTime`, `SuppressHashFilter`.

**Level values:**
| Value | Meaning |
|-------|---------|
| 1 | Critical |
| 2 | Error |
| 3 | Warning |
| 4 | Information |
| 5 | Verbose |

### 2. `-FilterXml` (Use when you need complex queries)

```powershell
$xml = @"
<QueryList>
  <Query Id="0">
    <Select Path="System">*[System[Provider[@Name='Service Control Manager'] and (Level=1 or Level=2 or Level=3) and TimeCreated[@SystemTime &gt;= '2024-01-01T00:00:00']]]</Select>
  </Query>
</QueryList>
"@

Get-WinEvent -FilterXml $xml
```

Use `-FilterXml` when:
- You need to combine filters across multiple logs in one call
- You need boolean logic the hashtable doesn't support
- You're reading queries from Event Viewer saved XML

### 3. `-FilterXPath` (Avoid — limited and slow)

```powershell
Get-WinEvent -LogName "System" -FilterXPath "*[System[Provider[@Name='Service Control Manager'] and Level=2]]"
```

Less common than the other two. Only use if you have an existing XPath query.

### When NOT to use `Get-EventLog`

`Get-EventLog` is **deprecated since Windows PowerShell 5.1** and only works against the classic event logs (Application, System, Security). It cannot query modern logs like `Microsoft-Windows-PowerShell/Operational`. Always use `Get-WinEvent`.

---

## Common log channels

```powershell
# System and Application
"System"
"Application"

# Security (requires special privileges)
"Security"

# PowerShell logging (if enabled via GPO)
"Microsoft-Windows-PowerShell/Operational"
"Microsoft-Windows-PowerShell/Admin"

# Modern apps and services
"Microsoft-Windows-AppLocker/EXE and DLL"
"Microsoft-Windows-BitLocker/BitLocker Operational"
"Microsoft-Windows-DNS-Client/Operational"
"Microsoft-Windows-DriverFrameworks-UserMode/Operational"
"Microsoft-Windows-Fault-Tolerant-Heap/Operational"
"Microsoft-Windows-Kernel-Power/Diagnostic"
"Microsoft-Windows-Kernel-WHEA/Errors"
"Microsoft-Windows-PrintService/Operational"
"Microsoft-Windows-Storage-ClassPnP/Operational"
"Microsoft-Windows-TaskScheduler/Operational"
"Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
"Microsoft-Windows-Windows Defender/Operational"
"Microsoft-Windows-WindowsUpdateClient/Operational"

# Intune
"Microsoft Intune Agent/Operational"
```

**Tip:** List all available log names on a machine:

```powershell
Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } |
    Select-Object LogName, RecordCount |
    Sort-Object RecordCount -Descending
```

---

## Performance and large-log handling

### Streaming Approach (for very large logs)

When a log has 100K+ records, `-FilterHashtable` may still load too much into memory. Use `-Oldest` to stream from the beginning:

```powershell
Get-WinEvent -LogName "Security" -FilterHashtable @{ Id = 4624 } -MaxEvents 1000 -Oldest
```

### Chunked Time-Window Scans

```powershell
function Get-EventsInChunks {
    param(
        [string]$LogName,
        [hashtable]$Filter,
        [int]$ChunkHours = 6
    )

    $endTime = Get-Date
    $startTime = $endTime.AddHours(-$ChunkHours)
    $allEvents = @()

    # Walk backwards in time
    while ($startTime -gt (Get-Date).AddYears(-1)) {
        $chunkFilter = $Filter.Clone()
        $chunkFilter.StartTime = $startTime
        $chunkFilter.EndTime = $endTime

        $events = Get-WinEvent -LogName $LogName -FilterHashtable $chunkFilter -ErrorAction SilentlyContinue
        $allEvents += $events

        $endTime = $startTime
        $startTime = $startTime.AddHours(-$ChunkHours)
    }

    return $allEvents
}
```

### Memory-Efficient Aggregation

Don't keep the full event objects — project to what you need early:

```powershell
$summary = Get-WinEvent -LogName "System" -MaxEvents 10000 |
    Group-Object Id |
    Select-Object @{
        Name = 'EventId'; Expression = { $_.Name }
    }, @{
        Name = 'Count'; Expression = { $_.Count }
    } |
    Sort-Object Count -Descending

$summary | Format-Table -AutoSize
```

### Export Large Queries via File-Backed Pagination

```powershell
$tempFile = Join-Path $env:TEMP "events_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

Get-WinEvent -LogName "System" -FilterHashtable @{
    Level = 1, 2
    StartTime = (Get-Date).AddDays(-30)
} | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message |
    Export-Csv -Path $tempFile -NoTypeInformation -Encoding UTF8

Write-Output "Exported to $tempFile"
```

---

## Remote event log access

```powershell
# Single remote machine
$events = Invoke-Command -ComputerName "SERVER01" -ScriptBlock {
    Get-WinEvent -LogName "System" -FilterHashtable @{
        Level = 1, 2
        StartTime = (Get-Date).AddDays(-1)
    }
} -ErrorAction Stop

# Multiple machines: use the canonical runspace pool pattern from `winrm-patterns.md` (Pattern 2)
# Swap the inner Invoke-Command ScriptBlock for:
$scriptBlock = {
    Get-WinEvent -LogName "System" -FilterHashtable @{
        Level     = 1, 2
        StartTime = (Get-Date).AddDays(-1)
    } -ErrorAction Stop
}

# and build the per-computer result as:
# [pscustomobject]@{ Computer = $Computer; Status = 'Success'; Count = $events.Count; Events = $events }
# (failure branch: Status = 'Failed', Count = 0, Error = $_.Exception.Message)
```

Read `winrm-patterns.md` for the full multi-device remote execution pattern.

---

## Export to CSV / HTML

### CSV Export (Standard)

```powershell
$events = Get-WinEvent -LogName "System" -MaxEvents 1000 -ErrorAction SilentlyContinue

$events | Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, @{
    Name = 'Computer'
    Expression = { $env:COMPUTERNAME }
}, Message |
    Export-Csv -Path "C:\Reports\Events_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" `
        -NoTypeInformation -Encoding UTF8
```

### HTML Export with Inline CSS

```powershell
function Export-EventsToHTML {
    param(
        [object[]]$Events,
        [string]$Title = "Event Log Report",
        [string]$OutputPath
    )

    $css = @"
    body { font-family: 'Segoe UI', sans-serif; margin: 16px; background: #f6f8fb; }
    h1 { color: #1f2d3a; }
    table { border-collapse: collapse; width: 100%; background: white; margin-top: 12px; }
    th { background: #e6ebf4; padding: 10px; text-align: left; }
    td { padding: 8px; border-bottom: 1px solid #e6ebf4; font-size: 12px; }
    .critical { background: #f7c4c4; color: #1f2d3a; font-weight: 600; }
    .error    { background: #fbe6c5; color: #1f2d3a; }
    .warning  { background: #fff8e1; color: #1f2d3a; }
"@

    $rows = foreach ($e in $Events) {
        $levelClass = switch ($e.LevelDisplayName) {
            "Critical" { "critical" }
            "Error"    { "error" }
            "Warning"  { "warning" }
            default    { "" }
        }
        "<tr class='$levelClass'><td>$($e.TimeCreated)</td><td>$($e.ProviderName)</td><td>$($e.Id)</td><td>$($e.LevelDisplayName)</td><td>$([string]$e.Message -replace '<','&lt;' -replace '>','&gt;' | ForEach-Object { $_.Substring(0, [Math]::Min(200, $_.Length)) })</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html><head><title>$Title</title><style>$css</style></head>
<body>
<h1>$Title</h1>
<p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
<p>Total events: $($Events.Count)</p>
<table>
<thead><tr><th>Time</th><th>Provider</th><th>ID</th><th>Level</th><th>Message</th></tr></thead>
<tbody>
$($rows -join "`n")
</tbody>
</table>
</body></html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
    Write-Output "Report saved to $OutputPath"
}
```

---

## Dashboard with Chart.js

For a self-contained HTML dashboard with no server required, embed Chart.js via CDN:

```powershell
function Export-EventsDashboard {
    param(
        [object[]]$Events,
        [string]$OutputPath
    )

    # Aggregate by Level
    $byLevel = $Events | Group-Object LevelDisplayName |
        Select-Object @{
            Name = 'Level'; Expression = { $_.Name }
        }, @{
            Name = 'Count'; Expression = { $_.Count }
        }

    # Aggregate by Provider (top 10)
    $byProvider = $Events | Group-Object ProviderName |
        Sort-Object Count -Descending |
        Select-Object -First 10 |
        ForEach-Object {
            [pscustomobject]@{ Provider = $_.Name; Count = $_.Count }
        }

    $levelData = ($byLevel | ForEach-Object { "{name:'{0}',y:{1}}" -f $_.Level, $_.Count }) -join ','
    $providerLabels = ($byProvider | ForEach-Object { "'{0}'" -f $_.Provider }) -join ','
    $providerData = ($byProvider | ForEach-Object { $_.Count }) -join ','

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Event Log Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
    <style>
        body { font-family: 'Segoe UI'; margin: 0; background: #f6f8fb; }
        .header { background: white; padding: 20px 32px; border-bottom: 1px solid #e6ebf4; }
        .header h1 { margin: 0; color: #1f2d3a; }
        .header p { margin: 4px 0 0; color: #5f6b7a; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; padding: 24px; }
        .card { background: white; border: 1px solid #e6ebf4; border-radius: 8px; padding: 16px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Event Log Dashboard</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Total: $($Events.Count) events</p>
    </div>
    <div class="grid">
        <div class="card"><h3>By Level</h3><canvas id="levelChart"></canvas></div>
        <div class="card"><h3>Top Providers</h3><canvas id="providerChart"></canvas></div>
    </div>
    <script>
        new Chart(document.getElementById('levelChart'), {
            type: 'doughnut',
            data: {
                labels: [$(($byLevel | ForEach-Object { "'{0}'" -f $_.Level }) -join ',')],
                datasets: [{ data: [$($($byLevel | ForEach-Object { $_.Count }) -join ',')] }]
            }
        });
        new Chart(document.getElementById('providerChart'), {
            type: 'bar',
            data: {
                labels: [$providerLabels],
                datasets: [{ data: [$providerData] }]
            },
            options: { indexAxis: 'y' }
        });
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
    Write-Output "Dashboard saved to $OutputPath"
}
```

The dashboard opens in any browser, requires no server, and works offline once the user has visited it once (CDN cached). For air-gapped environments, download Chart.js once and embed the file with `-replace 'src="https://..."', 'src="chart.umd.js"'`.

---

## Custom event log writing

Write your own events to the Windows Event Log so tools can integrate with log monitoring:

```powershell
# Register the event source once (requires Administrator)
New-EventLog -LogName "Application" -Source "MyAdminTool" -ErrorAction SilentlyContinue

# Write events
Write-EventLog -LogName "Application" -Source "MyAdminTool" `
    -EventId 1000 -EntryType Information `
    -Message "Completed inventory of 245 devices"

# For modern logs (PS5.1+)
# Custom log creation requires registry editing - use existing Application log
```

**EntryType values:** `Error`, `Warning`, `Information`, `SuccessAudit`, `FailureAudit`.

**Why use the Event Log?** Other monitoring tools (SCOM, Splunk, Datadog) automatically pick up events from the Application log. Writing to a file works locally, but writing to the Event Log integrates with enterprise monitoring at no extra cost.
