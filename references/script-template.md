# PowerShell Script Template and Coding Conventions

> **Canonical header: see `_header-canonical.md` (single source). Canonical logging: `_logging-canonical.md`. This file extends with examples and quality bars — do not duplicate field order here.**

Standard script structure, header format, and coding conventions for enterprise PowerShell tools.

---

## Table of Contents

1. [Script Header](#script-header)
2. [Standard Script Structure](#standard-script-structure)
3. [Naming Conventions](#naming-conventions)
4. [Code Formatting](#code-formatting)
5. [Error Handling](#error-handling)
6. [Logging](#logging)
7. [Parameters](#parameters)
8. [Output Patterns](#output-patterns)
9. [String Formatting](#string-formatting)
10. [Module Patterns](#module-patterns)
11. [CmdletBinding and Advanced Functions](#cmdletbinding-and-advanced-functions)
12. [ShouldProcess — -WhatIf and -Confirm Support](#shouldprocess--whatif-and--confirm-support)
13. [Splatting for Readability](#splatting-for-readability)
14. [Pipeline Support](#pipeline-support)
15. [Environment Detection](#environment-detection)
16. [PS5.1 Compatibility Checklist](#ps51-compatibility-checklist)
17. [Description & Comment Writing Standards](#description--comment-writing-standards)

---

## Script Header

Every script starts with this canonical header:

```powershell
<#
.TITLE
    [Tool Name - Brief descriptive name]

.SYNOPSIS
    [One-line description of what the script does]

.DESCRIPTION
    [Detailed description of what this tool does, why it exists,
    and what problem it solves for the IT admin].

.TAGS
    [Category], [Subcategory]

.PLATFORM
    Windows

.MINROLE
    [Minimum role required to run this script, e.g., Intune Administrator]

.PERMISSIONS
    [Graph API permissions required, e.g., DeviceManagementManagedDevices.Read.All]

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 (YYYY-MM-DD)
    - Initial release
    - [Feature 1]
    - [Feature 2]

.EXAMPLE
    .\toolname.ps1 -ParameterName "Value"
    [Description of what this example does]

.NOTES
    [Additional notes, requirements, caveats]
    - [Any special requirements or dependencies]
    - [Performance considerations]
    - [Known limitations]
#>
```

### Header Rules

- **One canonical header for ALL script types** (Enterprise standard). Field order:
  `.TITLE` → `.SYNOPSIS` → `.DESCRIPTION` → `.TAGS` → `[.REMEDIATIONTYPE]` → `[.PAIRSCRIPT]` → `.PLATFORM` → `[.MINROLE]` → `.PERMISSIONS` → `.AUTHOR` → `.VERSION` → `.CHANGELOG` → `.LASTUPDATE` → `.EXAMPLE`(s) → `.NOTES`
  Full template: `references/intune-patterns.md` ("Script Header Format")
- `.TITLE` follows the pattern `ToolName Mode - Brief purpose` (e.g., `WinTempSweep Detection - Stale Temp Data Compliance Check`)
- `.SYNOPSIS` is one line, under 100 characters
- `.DESCRIPTION` explains the "why", not just the "what" — targets, thresholds, what gets skipped, how results are reported
- `.PLATFORM` is required — `Windows` or `macOS`
- `.PERMISSIONS` lists exact Graph API permission names (or `None (local SYSTEM context)`)
- `.AUTHOR` is `AI Generated` for generated tools; `.LASTUPDATE` is today's date (YYYY-MM-DD)
- `.CHANGELOG` is newest-first and documents FIXES with their cause, not just features (e.g., "1.1 - Fixed invalid return statement in Get-FolderSize that caused folder sizes to always report 0 bytes")
- `.NOTES` always covers: execution context/elevation behavior, exit codes, log path, skip/locked-file behavior
- **File order:** the help block is ALWAYS the first thing in the file; `#Requires -Version 5.1` goes immediately after it — never before, never elsewhere
- **Never write `#Requires -RunAsAdministrator`.** Detect elevation at runtime with `Test-IsElevated` and degrade gracefully (see Description & Comment Writing Standards)
- Detect/remediate pairs additionally carry `.REMEDIATIONTYPE` + `.PAIRSCRIPT` right after `.TAGS`; notification runbooks add `.EXECUTION` + `.OUTPUT`

---

## Standard Script Structure

### CLI Script (No GUI)

```powershell
<#
.TITLE
    MyTool - Brief purpose statement

.SYNOPSIS
    One-line summary of what the tool does.

.DESCRIPTION
    What it targets, thresholds and parameters, what gets skipped, and how
    results are reported.

.TAGS
    Operational

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution) or the required Graph scopes

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.LASTUPDATE
    YYYY-MM-DD

.EXAMPLE
    .\MyTool.ps1 -ComputerName "PC01"
    What this example does.

.NOTES
    - Execution context and elevation behavior.
    - Exit codes: 0 = success, 1 = failure.
    - Log: C:\ProgramData\MyTool\Logs\
#>

#Requires -Version 5.1

# ============================================================
# CONFIGURATION
# ============================================================

$ErrorActionPreference = 'Stop'

# Dot-source safety: when dot-sourced ($PSScriptRoot is ''), param default already falls back via
# $PSCommandPath / $MyInvocation.MyCommand.Path. If user did NOT explicitly pass -OutputPath,
# force Reports to be beside the original script (never in caller's Get-Location).
if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
    $scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
    $OutputPath = Join-Path $scriptBase "Reports"
}

$ToolName = "MyTool"
$Version = "1.0"

# Logging helpers (canonical: scripts/Write-Log.ps1 — Initialize-Log, Write-Log, Finish-Script)
# Log path is created by Initialize-Log under C:\ProgramData\$ToolName\Logs\

# ============================================================
# FUNCTIONS
# ============================================================

function Write-Log { param([string]$Message, [ValidateSet('INFO','SUCCESS','WARNING','ERROR','DEBUG')][string]$Level = 'INFO') }

function Write-Banner { }   # canonical: references/intune-patterns.md - prints "<ToolName> | <Mode>" between '=' separators to console + log

function Finish-Script { param([int]$ExitCode, [string]$Message, [ValidateSet('INFO','SUCCESS','WARNING','ERROR')][string]$Level = 'INFO') }   # logs then exits - use for EVERY terminal path

function Get-Input {
    # ... input handling ...
}

function Invoke-MainOperation {
    # ... core logic ...
}

function Export-Results {
    # ... output handling ...
}

# ============================================================
# MAIN
# ============================================================

try {
    Initialize-Log -SolutionName $ToolName -Type General
    Write-Banner
    Write-Log "Log file ready: $LogFile" "DEBUG"
    Write-Log "Starting $ToolName v$Version" "INFO"

    $input = Get-Input
    $results = Invoke-MainOperation -Input $input
    Export-Results -Results $results

    Write-Log "Completed successfully" "SUCCESS"
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    exit 1
}
```

**CLI scripts use `Write-Log`, never the GUI `Add-LogLine`.** For Intune remediation CLI scripts, use the enhanced helpers from `references/intune-patterns.md`: `Write-Banner`, `Finish-Script`, `Initialize-Log`, and config-driven command execution.

### WPF GUI Script (Tier 1 Bootstrap)

For WPF GUI applications (Type 1), the single source of truth for full bootstrap scaffolding, assembly loading, design tokens, and XAML initialization is **[`references/file-architecture.md`](file-architecture.md)**.

Key GUI components required:
- standard `<# ... #>` comment-based help first, then `#Requires -Version 5.1`
- STA check & auto-restart
- `Add-LogLine` (`scripts/Add-LogLine.ps1`) for thread-safe UI + file logging
- `Guard-Action` / `Release-Action` (`scripts/Guard-Action.ps1`) on every button handler
- Tailwind Slate theme dictionary + 19 required XAML styles in `Window.Resources`
- Dual-parser XAML validation (`scripts/Test-XamlFile.ps1`) before `ShowDialog()`


---

## Naming Conventions

### Functions

```powershell
# PascalCase with hyphens (PowerShell standard)
Add-LogLine
Set-Busy
Guard-Action
Get-DeviceInventory
Invoke-MainOperation
Export-Results
Test-ADConnectivity
```

### Variables

```powershell
# Script-scoped state
$script:IsBusy = $false
$script:LogWriter = $null

# Centralized state (newer pattern)
$Script:AppState = @{
    LogLines = [System.Collections.Generic.HashSet[string]]::new()
    Runspace = $null
    Timer    = $null
}

# Local variables
$computerName = $env:COMPUTERNAME
$logDir = "C:\ProgramData\$ToolName\Logs"
$exitCode = 0

# Parameters
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [ValidateSet('Small','Medium','Large')]
    [string]$Size = 'Medium',

    [int]$Timeout = 30
)
```

### XAML Controls

```powershell
# Short, descriptive names
$SrcFolderTxt     # TextBox for source folder
$CreateBtn        # Button for create action
$dgResults        # DataGrid for results
$rtb              # RichTextBox for message center
$dgStatus         # DataGrid for status
$btnRun           # Button for run action
$txtCustom        # TextBox for custom input
$PkgNameTxt       # TextBox for package name
$SessionMachineTxt # TextBox for session machine
```

---

## Code Formatting

### Indentation

- 2 spaces consistently
- No tabs

### Region Markers

```powershell
#region -------------------- Configuration --------------------

$ToolName = "MyTool"

#endregion

#region -------------------- Functions ------------------------

function Write-Log { }   # canonical: scripts/Write-Log.ps1

#endregion
```

### Line Length

- Keep lines under 120 characters when possible
- Use splatting for long parameter lists:

```powershell
$params = @{
    Identity  = $computerName
    Properties = @('Name', 'OperatingSystem', 'LastLogonDate')
    ErrorAction = 'SilentlyContinue'
}
Get-ADComputer @params
```

---

## Error Handling

### Basic Pattern

```powershell
try {
    # Operation
}
catch {
    $msg = $_.Exception.Message
    Write-Log "Failed: $msg" "ERROR"
}
```

### Classified Remote Errors

```powershell
catch {
    $msg = $_.Exception.Message
    if ($msg -match 'Access is denied') {
        Write-Log "ACCESS DENIED -- Run as Administrator" "ERROR"
    }
    elseif ($msg -match 'WinRM cannot') {
        Write-Log "WINRM NOT ENABLED -- Run: Enable-PSRemoting -Force" "ERROR"
    }
    elseif ($msg -match 'timeout') {
        Write-Log "TIMEOUT -- Device unreachable or firewall blocking" "ERROR"
    }
    elseif ($msg -match 'The RPC server is unavailable') {
        Write-Log "RPC UNAVAILABLE -- Check WinRM/Firewall settings" "ERROR"
    }
    else {
        Write-Log "FAILED: $msg" "ERROR"
    }
    $exitCode = 1
}
```

### Non-Critical Operations

```powershell
# Empty catch for operations that can safely fail
try { Stop-Process -Name "notepad" -ErrorAction SilentlyContinue } catch { }

# Or with ErrorAction preference
$ErrorActionPreference = 'SilentlyContinue'
Remove-Item -Path $tempFile -Force
```

### Never Throw in Production

```powershell
# BAD
throw "Something went wrong"

# GOOD
Write-Log "Something went wrong" "ERROR"
$exitCode = 1
```

---

## Logging

**There is exactly one canonical logger per context — copy it verbatim, never retype:**
- **WPF GUI tools:** `scripts/Add-LogLine.ps1` (consecutive-duplicate guard via `$script:lastLogKey` + file + console + status bar + GUI Message Center colors)
- **CLI scripts (incl. Intune):** `scripts/Write-Log.ps1` (with `Initialize-Log` / `Finish-Script`)

The level set is `INFO, SUCCESS, WARNING, ERROR, DEBUG` — **there is no `DIVIDER` level** (older drafts invented it; use `DEBUG` or a plain INFO line instead). The console/Message Center colors are fixed (Tailwind Slate):

| Level | Console color | Hex |
|-------|---------------|-----|
| `DEBUG` | DarkGray | `#94A3B8` |
| `INFO` | Cyan | `#3B82F6` |
| `SUCCESS` | Green | `#10B981` |
| `WARNING` | Yellow | `#F59E0B` |
| `ERROR` | Red | `#EF4444` |

```powershell
# Canonical usage (GUI):
Add-LogLine -Message "Backup complete" -Level 'SUCCESS'
# Canonical usage (CLI):
Write-Log "Backup complete" 'SUCCESS'
```

---

## Parameters

```powershell
# Mandatory with validation
param(
    [Parameter(Mandatory)]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$CSVPath,

    [ValidateSet('Small','Medium','Large')]
    [string]$Size = 'Medium',

    [ValidateRange(1, 100)]
    [int]$Timeout = 30,

    [switch]$Force,

    # Reports must be beside the original script (dot-source safe). Never use ".\Results" or Get-Location alone.
    [string]$OutputPath = $( $scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }; Join-Path $scriptBase "Reports" )
)
```

---

## Output Patterns

### Structured Output

```powershell
# Use [pscustomobject] for structured output
$results = foreach ($item in $items) {
    [pscustomobject]@{
        Name   = $item.Name
        Status = $item.Status
        Count  = $item.Count
    }
}

# Pipe to Format-Table or Export-Csv
$results | Format-Table -AutoSize
$results | Export-Csv -Path $outputPath -NoTypeInformation
```

### Progress Indication

```powershell
$total = $items.Count
$current = 0

foreach ($item in $items) {
    $current++
    $percent = [math]::Round(($current / $total) * 100)
    Write-Progress -Activity "Processing" -Status "$current of $total" -PercentComplete $percent
    # ... process item ...
}
Write-Progress -Activity "Processing" -Completed
```

---

## String Formatting

```powershell
# Use -f operator (preferred for consistency)
Write-Host ("Processing: {0}" -f $computerName)
Write-Host ("{0} of {1} completed" -f $current, $total)

# For simple cases, string interpolation is fine
Write-Host "Processing $computerName"

# For multi-line strings
$message = @"
Device: $computerName
Status: $status
Details: $details
"@
```

---

## Module Patterns

### Check and Install Required Modules (Enterprise Standard)

Always validate required modules exist before importing. This prevents cryptic errors halfway through execution:

```powershell
# Required modules for this script
$RequiredModules = @(
    "Microsoft.Graph.Authentication"
)

foreach ($Module in $RequiredModules) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Error "$Module module is required. Install it using: Install-Module $Module -Scope CurrentUser"
        exit 1
    }
}

# Import required modules
foreach ($Module in $RequiredModules) {
    Import-Module $Module -Force
}
```

### Environment-Aware Module Initialization

For scripts that may run in different contexts (local, scheduled task, CI/CD):

```powershell
function Initialize-RequiredModule {
    param(
        [string[]]$ModuleNames,
        [bool]$ForceInstall = $false
    )

    foreach ($ModuleName in $ModuleNames) {
        $module = Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1

        if (-not $module) {
            Write-Information "Module '$ModuleName' not found. Attempting to install..." -InformationAction Continue

            if (-not $ForceInstall) {
                $response = Read-Host "Install module '$ModuleName'? (Y/N)"
                if ($response -notmatch '^[Yy]') {
                    throw "Module '$ModuleName' is required but installation was declined."
                }
            }

            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
            $scope = if ($isAdmin) { 'AllUsers' } else { 'CurrentUser' }

            Install-Module -Name $ModuleName -Scope $scope -Force -AllowClobber -Repository PSGallery
            Write-Information "Successfully installed '$ModuleName'" -InformationAction Continue
        }

        Import-Module -Name $ModuleName -Force -ErrorAction Stop
    }
}
```

### Minimal Dependencies

Always check if the module is available before importing:

```powershell
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory
    $hasAD = $true
} else {
    Write-Log "ActiveDirectory module not available" "WARNING"
    $hasAD = $false
}
```

---

## CmdletBinding and Advanced Functions

`[CmdletBinding()]` turns a function into an *advanced function* — it gets common parameters (`-Verbose`, `-Debug`, `-ErrorAction`, `-WarningAction`, `-WhatIf`, `-Confirm`), strict parameter binding, and discoverable help via `Get-Help`. Without it, `-Verbose` silently does nothing.

### Basic CmdletBinding

```powershell
function Get-StaleComputers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$InactiveDays,

        [Parameter()]
        [string]$SearchBase
    )

    Write-Verbose "Searching for computers inactive for $InactiveDays days"

    # ... implementation ...

    Write-Verbose "Search complete"
}
```

Run with verbose output:

```powershell
Get-StaleComputers -InactiveDays 90 -Verbose
```

### Parameter Sets (Mutually Exclusive Modes)

Use parameter sets when a function does different work depending on which parameter was provided:

```powershell
function Get-DeviceInfo {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Position = 0)]
        [string]$DeviceName,

        [Parameter(ParameterSetName = 'ById', Position = 0)]
        [string]$DeviceId,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    switch ($PSCmdlet.ParameterSetName) {
        'ByName' { Get-DeviceByName $DeviceName }
        'ById'   { Get-DeviceById $DeviceId }
        'All'    { Get-AllDevices }
    }
}
```

Now PowerShell will reject calls like `Get-DeviceInfo -DeviceName 'X' -DeviceId 'Y'` because they're in different parameter sets. This catches operator mistakes before they reach the remote call.

---

## ShouldProcess — -WhatIf and -Confirm Support

For any function that **changes state** (deletes objects, modifies settings, restarts services), support `-WhatIf` and `-Confirm`. This is the difference between a script that requires you to read the code carefully and a script you can safely hand to helpdesk:

```powershell
function Remove-StaleComputer {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [switch]$Force
    )

    # ConfirmImpact 'High' means PowerShell will prompt for confirmation
    # unless -Force or -Confirm:$false is supplied.

    if ($PSCmdlet.ShouldProcess($ComputerName, 'Remove from Active Directory')) {
        try {
            Remove-ADComputer -Identity $ComputerName -Confirm:$false -ErrorAction Stop
            Write-Output "Removed $ComputerName"
        }
        catch {
            Write-Error "Failed to remove ${ComputerName}: $($_.Exception.Message)"
        }
    }
}
```

Now operators can run:

```powershell
# See what would happen without doing it
Remove-StaleComputer -ComputerName "OLDPC01" -WhatIf

# Run with confirmation prompt
Remove-StaleComputer -ComputerName "OLDPC01"

# Run silently (e.g., from a scheduled task)
Remove-StaleComputer -ComputerName "OLDPC01" -Force
```

**When to use `ConfirmImpact`:**

| Impact | Prompts Confirmed By Default For | Examples |
|--------|--------------------------------|----------|
| `Low` | No prompt | Read-only operations |
| `Medium` | Interactive sessions only | Modifying non-critical settings |
| `High` | Always (unless `-Force`) | Deletes, restarts, disables accounts |

For bulk operations, prefer `Medium` (no prompt by default in scheduled jobs) but with `-WhatIf` support.

---

## Splatting for Readability

When a cmdlet has more than three parameters, splatting makes the call readable and easy to modify. It also lets you build parameter sets conditionally:

```powershell
# Without splatting — ugly and hard to read
Get-ADUser -Filter "Department -eq 'IT'" -Properties 'Title', 'Manager', 'LastLogonDate' -SearchBase "OU=Staff,DC=contoso,DC=com" -Server "dc01.contoso.com" -ResultPageSize 1000 -ResultSetSize 5000

# With splatting — readable and reusable
$params = @{
    Filter         = "Department -eq 'IT'"
    Properties     = 'Title', 'Manager', 'LastLogonDate'
    SearchBase     = "OU=Staff,DC=contoso,DC=com"
    Server         = "dc01.contoso.com"
    ResultPageSize = 1000
    ResultSetSize  = 5000
}
Get-ADUser @params
```

### Conditional Splatting (Build Parameters Based on Context)

```powershell
$invokeParams = @{
    ComputerName = $Computer
    ScriptBlock  = { Get-Service -Name $ServiceName }
    ErrorAction  = 'Stop'
}

# Add credential only if supplied (optional secure pattern)
if ($Credential) {
    $invokeParams.Credential = $Credential
}

# Add throttle limit only for fan-out operations
if ($Computer.Count -gt 1) {
    $invokeParams.ThrottleLimit = 10
}

Invoke-Command @invokeParams
```

This avoids the messy pattern of nested `if` statements each adding a parameter:

```powershell
# BAD
if ($Computer.Count -gt 1) {
    if ($Credential) {
        Invoke-Command -ComputerName $Computer -ScriptBlock { ... } -Credential $Credential -ThrottleLimit 10 -ErrorAction Stop
    } else {
        Invoke-Command -ComputerName $Computer -ScriptBlock { ... } -ThrottleLimit 10 -ErrorAction Stop
    }
} else {
    if ($Credential) {
        Invoke-Command -ComputerName $Computer -ScriptBlock { ... } -Credential $Credential -ErrorAction Stop
    } else {
        Invoke-Command -ComputerName $Computer -ScriptBlock { ... } -ErrorAction Stop
    }
}
```

---

## Pipeline Support

Functions that process a list of items should accept pipeline input. This lets you chain operations naturally:

```powershell
function Restart-ServiceOnDevice {
    [CmdletBinding()]
    param(
        # Accept either an array or pipeline input
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [Parameter()]
        [string]$ServiceName = 'WinRM'
    )

    process {
        # 'process' runs once per pipeline item, not once for the whole array.
        foreach ($computer in $ComputerName) {
            try {
                Invoke-Command -ComputerName $computer -ScriptBlock {
                    Restart-Service -Name $using:ServiceName -Force
                } -ErrorAction Stop
                Write-Output "Restarted $ServiceName on $computer"
            }
            catch {
                Write-Warning "Failed on $computer`: $($_.Exception.Message)"
            }
        }
    }
}
```

Now operators can use either form:

```powershell
# Direct call with array
Restart-ServiceOnDevice -ComputerName "PC01", "PC02", "PC03"

# Pipeline form
Get-ADComputer -Filter 'OperatingSystem -like "*Windows 10*"' |
    Select-Object -ExpandProperty Name |
    Restart-ServiceOnDevice -ServiceName 'Spooler'

# From CSV
Import-Csv "C:\Lists\Computers.csv" |
    Restart-ServiceOnDevice -ServiceName 'Spooler'
```

**Why `process { }` block?** Without it, the function receives all pipeline items as one batch. The `process` block runs once per item — which is what enables `Get-ADComputer | Restart-ServiceOnDevice` to actually stream.

---

## Environment Detection

Scripts that run both locally and in Azure Automation need to detect which environment they're in:

```powershell
# Azure Automation sets $PSPrivateMetadata.JobId.Guid when running inside a runbook.
if ($PSPrivateMetadata.JobId.Guid) {
    $IsAzureAutomation = $true
}
else {
    $IsAzureAutomation = $false
}

# Pick the right authentication / behavior based on environment.
if ($IsAzureAutomation) {
    Connect-MgGraph -Identity -NoWelcome
}
else {
    Connect-MgGraphCommunity -Scopes @('DeviceManagementManagedDevices.Read.All') -NoWelcome
}
```

For scripts that need more granular detection (CI/CD, scheduled tasks, manual runs):

```powershell
function Get-ScriptEnvironment {
    if ($PSPrivateMetadata.JobId.Guid) { return 'AzureAutomation' }
    if ($env:GITHUB_ACTIONS)            { return 'GitHubActions' }
    if ($env:JENKINS_URL)               { return 'Jenkins' }
    if ($Host.Name -eq 'ServerRemoteHost') { return 'PowerShellRemoting' }
    return 'Local'
}
```

---

## PS5.1 Compatibility Checklist

PowerShell 7 introduced many syntax features that don't work in PS5.1. Since enterprise environments often still run PS5.1, avoid these unless you explicitly target PS7+:

| Feature | PS7+ | PS5.1 | Alternative for PS5.1 |
|---------|------|-------|------------------------|
| `??` null-coalescing | ✅ | ❌ | `if ($x -eq $null) { ... }` |
| `?:` ternary | ✅ | ❌ | `if ($cond) { $a } else { $b }` |
| `?.` null-conditional | ✅ | ❌ | `if ($obj) { $obj.Property }` |
| `&&` pipeline chain | ✅ | ❌ | `if ($x) { ... }` |
| `\|\|` pipeline chain | ✅ | ❌ | `if (-not $x) { ... }` |
| `ConvertFrom-Json -AsHashtable` | ✅ | ❌ | `($json | ConvertFrom-Json) -as [hashtable]` |
| `ForEach-Object -Parallel` | ✅ | ❌ | Use runspace pool |
| `[ordered]@{ }` | ✅ | ⚠️ | Always works in PS5.1 actually — but the literal form may differ |
| `class` / `enum` keyword | ✅ | ✅ | Works in both, but syntax differs in edge cases |
| `-NoEnumerate` with pipelines | ✅ | ✅ | Works in both — no issue |
| `PSStyle.OutputRendering` | ✅ | ❌ | Don't rely on ANSI colors in PS5.1 |

### Detection in Scripts

Add this directly after the help block in any script that might run on PS5.1 (the help block always opens the file):

```powershell
#Requires -Version 5.1
```

This causes PowerShell to refuse to run on older versions instead of failing with cryptic syntax errors halfway through.

---

## Description & Comment Writing Standards

The header and comments are the tool's contract with the next operator. These standards were distilled from production scripts (the Enterprise Standards `TempFileCleaner` pattern), adopting what exceeded our baseline and rejecting what violated the Canonical Conventions table in `SKILL.md`.

### .DESCRIPTION Quality Bar

A compliant `.DESCRIPTION` answers four questions, in order:

1. **Scope** — exactly which targets/objects it touches (e.g., "%TEMP%, plus C:\Windows\Temp when elevated").
2. **Safety guarantees** — what it will NOT do (e.g., "files locked by running processes are skipped", "only deletes files older than N days"). Operators approve deployment based on these lines.
3. **Degradation behavior** — what changes without elevation, prerequisites, or modules.
4. **Output contract** — what it reports back (per-target totals, freed space) and whether it supports `-WhatIf`.

```powershell
.DESCRIPTION
    Scans the per-user Temp folder (%TEMP%) and, when running elevated, the
    system-wide Temp folder (C:\Windows\Temp) and deletes files and empty
    subfolders that were not modified within the retention window
    (-OlderThanDays, default 7). Files locked by running processes are skipped
    and reported. Produces per-target totals for items deleted, disk space
    freed, and failures. Supports -WhatIf for a safe dry run.
```

### Parameter HelpMessage

Every non-obvious parameter carries a `HelpMessage`. This is what interactive users see from parameter prompts — one line, action-oriented:

```powershell
[Parameter(Mandatory = $false, HelpMessage = "Minimum file age in days before deletion")]
[ValidateRange(0, 365)]
[int]$OlderThanDays = 7,

[Parameter(Mandatory = $false, HelpMessage = "Also clean Windows Update cache")]
[switch]$CleanUpdateCache
```

### Examples With Intent Labels

Each `.EXAMPLE` is followed by a plain-language line describing the effect, not restating the syntax. Cover at minimum: default run, dry run, and the most aggressive/custom path:

```powershell
.EXAMPLE
    .\Clear-TempFiles.ps1 -WhatIf
    Dry run: reports what would be deleted without deleting anything.

.EXAMPLE
    .\Clear-TempFiles.ps1 -OlderThanDays 3 -CleanUpdateCache
    Aggressive pass: 3-day retention plus Windows Update cache cleanup.
```

### Graceful Elevation Degradation (Type 3 Tools)

`#Requires -RunAsAdministrator` is banned outright — it hard-fails before the tool can log anything or do partial work. For dual-context CLI tools, always degrade at runtime: clean what the current context allows, log a WARNING for what was skipped, and document the split in `.NOTES`.

```powershell
function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isElevated = Test-IsElevated
Write-Log "Elevated: $isElevated" 'INFO'

# Always available
Clean-TargetFolder -Path $env:TEMP

if ($isElevated) {
    Clean-TargetFolder -Path (Join-Path $env:SystemRoot 'Temp')
}
else {
    Write-Log "Skipping system temp (requires elevation)" 'WARNING'
}
```

`.NOTES` must state the split explicitly:
```
- Without elevation only the current user's %TEMP% is cleaned;
  C:\Windows\Temp and the update cache require an elevated session.
```

### Structured Per-Target Results

Functions return one result object per target; MAIN aggregates with `Measure-Object` so the summary is computed, not accumulated by hand. This keeps per-target detail available for logging AND makes the totals testable:

```powershell
function Clean-TargetFolder {
    param([string]$Path, [int]$OlderThanDays)
    # ... cleanup ...
    return @{
        Path      = $Path
        Deleted   = $successCount
        Failed    = $failureCount
        SizeFreed = $totalSize
    }
}

$results += Clean-TargetFolder -Path $env:TEMP -OlderThanDays $OlderThanDays

$totalDeleted = ($results | Measure-Object -Property Deleted -Sum).Sum
$totalFreed   = ($results | Measure-Object -Property SizeFreed -Sum).Sum
```

### Inline Comment Standards

* **Section banners** (`# ===== CONFIGURATION =====`) mark the fixed regions: Configuration / Logging / Functions / Main.
* **WHY-comments** on non-obvious decisions only — e.g., why directories are sorted deepest-first before removal, why a catch suppresses silently.
* **Skip reasons get DEBUG logs**, not silence: `"Skipped locked or protected file: $($file.Name)"` tells the operator months later why the file survived.
* Defensive completeness in switches: a `default { "White" }` color fallback beats an unhandled level.
* Keep `ValidateSet` consistent across helpers — if `Write-Log` accepts `DEBUG`, `Finish-Script` accepts it too.

### Anti-Patterns Rejected From the Source Pattern

The reference script also contained violations that must NOT propagate:

* **Invented Graph permissions.** It declared `.PERMISSIONS DeviceManagementManagedDevices.ReadWrite.All` while making zero Graph API calls. Per the Canonical Conventions table: local-only scripts declare `None (local SYSTEM context)` — never invent scopes to look complete.
* **`$PSCmdlet.ShouldProcess('dummy')` probes** and manual `-WhatIf:` flag threading. See `references/pitfalls.md` → CLI Script Traps.
* **Mixed file+folder enumeration** (double-delete phantom failures). See `references/pitfalls.md` → CLI Script Traps.
* **Header opening `<#.` instead of `<#`** — use the canonical `<# ... #>` structured header for Type 2 scripts.

### Testing for Cross-Version Compatibility

```powershell
# Run this in BOTH PS5.1 and PS7 to verify behavior
$test = $null
$x = $test ?? 'default'  # PS7 only — fails to parse on PS5.1
```

