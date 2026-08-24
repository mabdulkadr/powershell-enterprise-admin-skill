<#
.TITLE
    [ToolName] - [Brief Purpose]

.SYNOPSIS
    [One-line summary of what the tool does.]

.DESCRIPTION
    [What it targets, thresholds and parameters, what gets skipped without
    elevation, and how results are reported.]

    Scope & safety:
    - [State exactly what the tool changes and what it never touches.]
    Degradation behavior:
    - Without elevation only user-level targets are processed; system-level
      targets are logged as WARNING and skipped (never hard-fail).
    Output contract:
    - Sectioned console report; optional export; exit code 0 = success,
      1 = failure.

.TAGS
    Operational,[Subcategory]

.PLATFORM
    Windows

.PERMISSIONS
    Standard user for base functionality; elevation extends coverage to
    [system-level targets].

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
    .\[ToolName].ps1
    Runs with defaults and prints the console report.

.EXAMPLE
    .\[ToolName].ps1 -WhatIf
    Preview every action without changing anything.

.NOTES
    - Exit codes: 0 = success, 1 = failure.
    - Log: C:\ProgramData\[ToolName]\Logs\
    - Elevation is detected at runtime (Test-IsElevated) and degrades gracefully.
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # HelpMessage MUST be a named argument INSIDE [Parameter()]. A standalone
    # [HelpMessage('...')] attribute parses on pwsh 7 but crashes Windows
    # PowerShell 5.1 at runtime with CustomAttributeTypeNotFound.
    [Parameter(Mandatory = $false, HelpMessage = 'Describe what this parameter does for Get-Help.')]
    [string[]]$TargetName,

    [Parameter(Mandatory = $false, HelpMessage = 'Describe this switch mode for Get-Help.')]
    [switch]$ExtraMode

    # TODO: replace the sample parameters above with the tool's real parameters.
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# ============================================================================
# CONFIGURATION + LOGGING BLOCK (canonical: scripts/Write-Log.ps1 - verbatim)
# Single source of truth: scripts/Write-Log.ps1 (Initialize-Log / Write-Banner /
# Write-Log / Finish-Script). The helper functions are dot-sourced below — never
# re-type them here or they will drift from the canonical implementation.
# ============================================================================

# Resolve the canonical Write-Log.ps1 path relative to this template file.
$_scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$_canonicalLogging = Join-Path (Split-Path -Parent $_scriptRoot) 'scripts/Write-Log.ps1'
if (-not (Test-Path -LiteralPath $_canonicalLogging)) {
    throw "Canonical logging module not found at: $_canonicalLogging (copy scripts/Write-Log.ps1 from the skill before running this template)."
}
. (Get-Item -LiteralPath $_canonicalLogging).FullName

$SolutionName   = '[ToolName]'
$ScriptMode     = 'Run'
# NOTE: $script:SystemDrive / $script:LogRoot / $script:LogFile / $script:LogReady are
# initialized by scripts/Write-Log.ps1 (dot-sourced above). Do not redeclare them here.

# ============================================================================
# ELEVATION (graceful runtime degradation - hard elevation requirements banned)
# ============================================================================

# True only when elevated; callers degrade gracefully instead of hard-failing.
function Test-IsElevated {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================================
# WORK FUNCTIONS (structured per-target results)
# Every action returns ONE PSCustomObject so MAIN aggregates counts uniformly.
# ============================================================================

function Invoke-TargetAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$TargetName
    )
    # Return ONE result object per target so MAIN can aggregate with Measure-Object.
    try {
        if (-not $PSCmdlet.ShouldProcess($TargetName, '[describe action]')) {
            return [PSCustomObject]@{ Target = $TargetName; Success = $true; Skipped = $true }
        }
        # TODO: real action here (-ErrorAction Stop inside try)
        return [PSCustomObject]@{ Target = $TargetName; Success = $true; Skipped = $false }
    }
    catch {
        return [PSCustomObject]@{ Target = $TargetName; Success = $false; Skipped = $false;
                                  Error = $_.Exception.Message }
    }
}

# ============================================================================
# MAIN
# Flow: init log -> elevation check -> snapshot -> per-target actions ->
#       aggregate applied/skipped/failed -> verify -> single Finish-Script exit.
# ============================================================================

try {
    $null = Initialize-Log -SolutionName $SolutionName -ScriptMode $ScriptMode -Type 'General'
    Write-Banner
    if ($script:LogReady) {
        Write-Log -Message "Log file ready: $($script:LogFile)" -Level 'DEBUG'
    }

    $isElevated = Test-IsElevated
    Write-Log -Message "Elevated: $isElevated" -Level 'INFO'

    # TODO: build target list; process each with Invoke-TargetAction; aggregate:
    #   $results = @($targets | ForEach-Object { Invoke-TargetAction -TargetName $_ })
    #   $ok  = @($results | Where-Object { $_.Success }).Count
    #   $bad = @($results | Where-Object { -not $_.Success }).Count
    #   Write-Log "Completed: $ok succeeded, $bad failed" $(if ($bad -gt 0) { 'WARNING' } else { 'SUCCESS' })

    Finish-Script -ExitCode 0 -Message "[ToolName] completed successfully" -Level 'SUCCESS'
}
catch {
    Finish-Script -ExitCode 1 -Message "Script execution error: $($_.Exception.Message)" -Level 'ERROR'
}
