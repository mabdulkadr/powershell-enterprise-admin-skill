<#
.TITLE
    Remediation - [What It Fixes]

.SYNOPSIS
    [One-line summary of the fix applied when detection reports non-compliance.]

.DESCRIPTION
    Paired remediation for [Solution-Name]. Runs only when detect-[solution-name].ps1
    returns exit 1. Performs: (1) pre-remediation validation, (2) remediation actions
    with per-target failure tracking, (3) post-remediation verification, (4) structured
    JSON result output for Intune diagnostics.

    Exit contract:
    Exit 0 = success (fix applied and verified)
    Exit 1 = failure (verification failed after applying)
    Exit 2 = script error

.TAGS
    Remediation,Action,Compliance

.REMEDIATIONTYPE
    Remediation

.PAIRSCRIPT
    detect-[solution-name].ps1

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    None (local SYSTEM context) - [state what it actually does locally]

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
    .\remediate-[solution-name].ps1
    Applies the fix and verifies it; exits 0 on verified success.

.EXAMPLE
    .\remediate-[solution-name].ps1
    Exits 1 if verification fails, exit 2 on unexpected script error.

.NOTES
    - Runs in SYSTEM context via Intune Proactive Remediations.
    - Idempotent: safe to run repeatedly; verify-before-and-after.
    - Partial success allowed: only ALL targets failing marks exit 1.
    - Logs: <SystemDrive>\IntuneLogs\[Solution-Name]\remediate-[solution-name].txt
#>

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION
# ============================================================================

$SolutionName = '[Solution-Name]'
$ScriptMode   = 'Remediation'
# NOTE: $script:SystemDrive / $script:LogRoot / $script:LogFile / $script:LogReady are
# initialized by scripts/Write-Log.ps1 (dot-sourced below) inside Initialize-Log. Do not
# redeclare them here.

$remediationResult = @{
    Status             = "Unknown"
    PreCheckStatus     = @()
    RemediationActions = @()
    PostCheckStatus    = @()
    Timestamp          = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ComputerName       = $env:COMPUTERNAME
}

# ============================================================================
# LOGGING BLOCK (canonical: dot-source scripts/Write-Log.ps1 - never re-type)
# Single source of truth: scripts/Write-Log.ps1 (Initialize-Log / Write-Banner /
# Write-Log / Finish-Script). Dot-sourcing prevents drift when the canonical is fixed.
# ============================================================================

# Resolve the canonical Write-Log.ps1 path relative to this template file.
# templates/*.template.ps1 → ../scripts/Write-Log.ps1
$_scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
$_canonicalLogging = Join-Path (Split-Path -Parent $_scriptRoot) 'scripts/Write-Log.ps1'
if (-not (Test-Path -LiteralPath $_canonicalLogging)) {
    throw "Canonical logging module not found at: $_canonicalLogging (copy scripts/Write-Log.ps1 from the skill before running this template)."
}
. (Get-Item -LiteralPath $_canonicalLogging).FullName

# Appends structured per-target remediation entries to the audit trail.
function Write-RemediationLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')][string]$Level = 'Info'
    )
    # Console/file via canonical Write-Log + structured record for JSON output.
    $mapped = switch ($Level) { 'Warning' { 'WARNING' } 'Error' { 'ERROR' } default { 'INFO' } }
    Write-Log -Message $Message -Level $mapped
    $script:remediationResult.RemediationActions += @{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Level     = $Level
        Message   = $Message
    }
}

# ============================================================================
# PRE-REMEDIATION VALIDATION
# ============================================================================

# Gate check before any mutation - failures must not touch target state.
function Test-RemediationPrerequisites {
    try {
        # Validate everything the fix depends on BEFORE touching anything.
        # Example: writable folder, service reachable, module present.
        $script:remediationResult.PreCheckStatus += "Pre-remediation validation completed successfully"
        return $true
    }
    catch {
        Write-RemediationLog "Pre-remediation validation error: $($_.Exception.Message)" -Level 'Error'
        return $false
    }
}

# ============================================================================
# REMEDIATION ACTION (per-target pattern)
# ============================================================================

# Applies the fix to ONE target and returns a structured success/failure object.
function Invoke-FixTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$TargetName,
        [Parameter(Mandatory = $true)][scriptblock]$Fix
    )
    # Returns $true when the fix was applied AND verified for this target.
    try {
        & $Fix
        return $true
    }
    catch {
        $script:failedCount++
        Write-RemediationLog "Target FAILED: $TargetName - $($_.Exception.Message)" -Level 'Warning'
        return $false
    }
}

# ============================================================================
# POST-REMEDIATION VERIFICATION
# ============================================================================

# Post-fix verification - trust-but-verify before declaring exit 0.
function Test-FixApplied {
    # Re-check the same condition(s) the detector used. Return $true only
    # when the observed state now matches the compliant definition.
    return $true   # TODO: replace with real verification
}

# ============================================================================
# MAIN
# ============================================================================
# Flow: init -> pre-checks -> per-target fix -> post-verify -> exit 0 / 1 / 2.

try {
    $null = Initialize-Log -SolutionName $SolutionName -ScriptMode $ScriptMode -Type 'Intune'
    Write-Banner
    if ($script:LogReady) {
        Write-Log -Message "Log file ready: $($script:LogFile)" -Level 'DEBUG'
    }
    Write-RemediationLog "Starting remediation..." -Level 'Info'

    # --- Pre-checks ---
    Write-RemediationLog "Performing pre-remediation checks..." -Level 'Info'
    if (-not (Test-RemediationPrerequisites)) {
        throw "Pre-remediation validation failed - aborting before any change."
    }

    # --- Fix (per-target failure tracking) ---
    $script:failedCount = 0
    $targetCount        = 0

    Write-RemediationLog "Executing remediation actions..." -Level 'Info'
    # TODO: replace with real per-target fixes, e.g.:
    #   $targetCount++
    #   Invoke-FixTarget -TargetName 'Service WSearch' -Fix { Start-Service WSearch -ErrorAction Stop }

    # --- Verify ---
    Write-RemediationLog "Performing post-remediation verification..." -Level 'Info'
    $verificationPassed = Test-FixApplied

    if ($targetCount -gt 0 -and $failedCount -ge $targetCount) {
        $verificationPassed = $false
    }

    # --- Report ---
    if ($verificationPassed) {
        $script:remediationResult.Status = "Success"
        $script:remediationResult.PostCheckStatus += "Verification passed after remediation"

        Write-Output "Remediation completed successfully"
        Write-Output "Targets processed: $targetCount (failed: $failedCount)"
        Write-Output ($remediationResult | ConvertTo-Json -Depth 6 -Compress)

        Finish-Script -ExitCode 0 -Message "Remediation completed successfully" -Level 'SUCCESS'
    }
    else {
        $script:remediationResult.Status = "Failed"
        Write-Output "Remediation finished but verification failed"
        Write-Output ($remediationResult | ConvertTo-Json -Depth 6 -Compress)
        Finish-Script -ExitCode 1 -Message "Post-remediation verification failed" -Level 'ERROR'
    }
}
catch {
    $script:remediationResult.Status = "Error"
    $script:remediationResult.Error = @{
        Message    = $_.Exception.Message
        Type       = $_.Exception.GetType().FullName
        StackTrace = $_.ScriptStackTrace
    }
    Write-Output ($remediationResult | ConvertTo-Json -Depth 6 -Compress)
    Finish-Script -ExitCode 2 -Message "Script execution error: $($_.Exception.Message)" -Level 'ERROR'
}
finally {
    Write-Log -Message "Cleanup complete." -Level 'DEBUG'
}
