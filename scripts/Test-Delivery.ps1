<#
.TITLE
    Test-Delivery - One-shot delivery verifier

.SYNOPSIS
    Runs parser check, compliance gate, and optional PS 5.1 smoke test in a single call.

.DESCRIPTION
    Speed path for delivering tools: replaces three chained verification commands.
    Stage 1 parses the target with the PowerShell language parser (0 errors required).
    Stage 2 invokes scripts/Test-ToolCompliance.ps1 in a clean subprocess so
    execution policy can never block it (zero FAIL lines required).
    Stage 3 (-SmokeTest) executes the tool under Windows PowerShell 5.1 with
    -WhatIf to catch pwsh-only syntax such as standalone [HelpMessage()]
    attributes, ternaries, and ?? operators that crash 5.1 at runtime.

.TAGS
    Verification,QualityGate,Delivery

.PLATFORM
    Windows

.PERMISSIONS
    Standard user (no elevation required)

.AUTHOR
    AI Generated

.VERSION
    1.0.0

.CHANGELOG
    1.0.0 (2026-08-23)
    - Initial release: created after a delivered CLI tool passed pwsh checks but
      crashed PS 5.1 on a standalone [HelpMessage()] attribute; consolidates the
      delivery loop into one command.

.LASTUPDATE
    2026-08-23

.EXAMPLE
    .\Test-Delivery.ps1 -ScriptPath C:\Tools\Disable-IPv6.ps1 -ReadmePath C:\Tools\docs\README.md -SmokeTest
    Full delivery gate: parser, compliance + README contract, and a PS 5.1 WhatIf run.

.NOTES
    - Exit codes: 0 = all stages passed, 1 = any stage failed.
    - Smoke test treats exit codes 0-2 as valid CLI outcomes; anything else fails.
    - Strictly read-only apart from the target tool's own WhatIf-safe execution.
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = 'Path to the generated tool .ps1')]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false, HelpMessage = 'Optional README path for the compliance contract')]
    [string]$ReadmePath,

    [Parameter(Mandatory = $false, HelpMessage = 'Run the tool under Windows PowerShell 5.1 with -WhatIf')]
    [switch]$SmokeTest
)

$ErrorActionPreference = 'Stop'
$script:Failures = 0

function Write-Stage {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=== {0} ===" -f $Text) -ForegroundColor White
}

function Add-Failure {
    param([string]$Text)
    Write-Host ("  [FAIL] {0}" -f $Text) -ForegroundColor Red
    $script:Failures++
}

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    Add-Failure "Script not found: $ScriptPath"
    exit 1
}

# --- Stage 1: parser ---------------------------------------------------------

Write-Stage "Parser: $(Split-Path $ScriptPath -Leaf)"
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$parseErrors)
if ($parseErrors -and $parseErrors.Count -gt 0) {
    foreach ($parseError in $parseErrors) {
        Add-Failure ("Line {0}: {1}" -f $parseError.Extent.StartLineNumber, $parseError.Message)
    }
}
else {
    Write-Host "  [PASS] 0 parse errors" -ForegroundColor Green
}

# --- Stage 2: compliance gate (subprocess defeats execution policy blocks) ---

Write-Stage "Compliance gate"
$hostExecutable = try { (Get-Process -Id $PID).Path } catch { 'powershell.exe' }
$gateArguments = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
    (Join-Path $PSScriptRoot 'Test-ToolCompliance.ps1'),
    '-ToolPath', $ScriptPath
)
if ($ReadmePath) { $gateArguments += @('-ReadmePath', $ReadmePath) }
& $hostExecutable @gateArguments
if ($LASTEXITCODE -ne 0) { $script:Failures++ }

# --- Stage 3: PS 5.1 smoke test ----------------------------------------------

if ($SmokeTest) {
    Write-Stage "PS 5.1 smoke test (-WhatIf)"
    $smokeOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". '$ScriptPath' -WhatIf" 2>&1
    $smokeExitCode = $LASTEXITCODE
    foreach ($line in @($smokeOutput | Select-Object -Last 4)) {
        Write-Host ("  | {0}" -f $line) -ForegroundColor DarkGray
    }
    if ($null -eq $smokeExitCode -or $smokeExitCode -gt 2) {
        Add-Failure "PS 5.1 exited with $smokeExitCode - pwsh-only syntax suspected (standalone [HelpMessage()], ternary, ?? operator, etc.)"
    }
    else {
        Write-Host ("  [PASS] PS 5.1 ran to completion (exit {0})" -f $smokeExitCode) -ForegroundColor Green
    }
}

Write-Host ""
if ($script:Failures -eq 0) {
    Write-Host "RESULT: DELIVERY OK" -ForegroundColor Green
    exit 0
}
Write-Host ("RESULT: DELIVERY BLOCKED - {0} failure(s)" -f $script:Failures) -ForegroundColor Red
exit 1
