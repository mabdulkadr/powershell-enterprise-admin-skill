<#
.TITLE
    Detection - [What It Checks]

.SYNOPSIS
    [One-line summary of the compliance condition being checked.]

.DESCRIPTION
    [What state this detection evaluates, why it matters, and what happens on
    each exit code. State explicitly that this script NEVER modifies the system.]

    Exit contract:
    Exit 0 = compliant (no remediation needed)
    Exit 1 = non-compliant (Intune runs the paired remediation)
    Exit 2 = script error (Intune must NOT treat a crash as non-compliance)

.TAGS
    Remediation,Detection

.REMEDIATIONTYPE
    Detection

.PAIRSCRIPT
    remediate-[solution-name].ps1

.PLATFORM
    Windows

.MINROLE
    Intune Service Administrator

.PERMISSIONS
    None (local SYSTEM context) - [state what it actually does locally]
    Only list real Graph scopes if this script calls Graph API.

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
    .\detect-[solution-name].ps1
    Returns exit 0 when compliant; exit 1 when the paired remediation must run.

.EXAMPLE
    .\detect-[solution-name].ps1
    Returns exit 2 when an unexpected error prevents evaluation.

.NOTES
    - Runs in SYSTEM context via Intune Proactive Remediations.
    - Keep detection under 30 seconds: metadata reads only, no heavy enumeration.
    - Idempotent and read-only by definition.
    - Logs: <SystemDrive>\IntuneLogs\[Solution-Name]\detect-[solution-name].txt
#>

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION
# ============================================================================

$SolutionName = '[Solution-Name]'
$ScriptMode   = 'Detection'
# NOTE: $script:SystemDrive / $script:LogRoot / $script:LogFile / $script:LogReady are
# initialized by scripts/Write-Log.ps1 (dot-sourced below) inside Initialize-Log. Do not
# redeclare them here.

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

# ============================================================================
# DETECTION LOGIC
# Return a list of reason strings so operators see every failure at once.
# Empty list = compliant. Never modify the system here.
# ============================================================================

# Returns a reason string per unmet condition; empty output = compliant.
function Test-ComplianceState {
    $reasons = [System.Collections.Generic.List[string]]::new()

    # --- CHECK 1 ------------------------------------------------------------
    # Example pattern (replace):
    #   if (-not (Test-Path -LiteralPath $somePath -PathType Leaf)) {
    #       $reasons.Add("Missing artifact: $somePath")
    #   }
    # Wrap probes of ACL-protected paths in their own try/catch:
    #   catch [System.UnauthorizedAccessException] { ... }

    # --- CHECK 2 ------------------------------------------------------------

    return @($reasons)
}

# ============================================================================
# MAIN
# ============================================================================
# Flow: init -> banner -> compliance checks -> exit 0 compliant / 1 non-compliant / 2 error.

try {
    $null = Initialize-Log -SolutionName $SolutionName -ScriptMode $ScriptMode -Type 'Intune'
    Write-Banner
    if ($script:LogReady) {
        Write-Log -Message "Log file ready: $($script:LogFile)" -Level 'DEBUG'
    }
    Write-Log -Message "Detection started" -Level 'INFO'

    $reasons = Test-ComplianceState

    if ($reasons.Count -eq 0) {
        Finish-Script -ExitCode 0 -Message "Compliant - no remediation needed" -Level 'SUCCESS'
    }

    foreach ($reason in $reasons) {
        Write-Output $reason
        Write-Log -Message "Non-compliant: $reason" -Level 'WARNING'
    }
    Finish-Script -ExitCode 1 -Message "Non-compliant - $($reasons.Count) condition(s) found" -Level 'WARNING'
}
catch {
    Write-Output "Detection error: $($_.Exception.Message)"
    Finish-Script -ExitCode 2 -Message "Detection script error: $($_.Exception.Message)" -Level 'ERROR'
}
