<#
.TITLE
    Write-Log

.SYNOPSIS
    Canonical CLI logging functions for enterprise PowerShell tools.

.DESCRIPTION
    The single source of truth for CLI script logging (Intune remediation/detection, AD, WinRM, event logs).
    Provides Initialize-Log, Write-Banner, Write-Log, and Finish-Script helpers with standardized formatting.
    Write-Banner reads $SolutionName and $ScriptMode from the caller's scope (set by every template before dot-sourcing).

.PARAMETER ExitCode
    Process exit code to terminate with (0=success/compliant, 1=failure/non-compliant, 2=script error).

.PARAMETER NoExit
    If specified in Finish-Script, logs the final line but does not call exit (safe for interactive/testing).

.PARAMETER Message
    The message to log.

.PARAMETER Level
    Log level ('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG'). Default is 'INFO'.

.TAGS
    Logging,CLI,Intune

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
    2026-08-22

.EXAMPLE
    $script:LogReady = Initialize-Log -SolutionName 'BitLockerRemediation' -ScriptMode 'detect'
    Write-Banner
    Write-Log -Message 'Starting detection' -Level 'INFO'
    Finish-Script -ExitCode 0 -Message 'Compliant' -Level 'SUCCESS'
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
# --- Logging (CLI Configuration) --------------------------------------------
$script:SystemDrive = if ($env:SystemDrive) { $env:SystemDrive.TrimEnd('\') } else {
    [System.IO.Path]::GetPathRoot($env:SystemRoot).TrimEnd('\')
}
$script:LogRoot  = $null
$script:LogFile  = $null
$script:LogReady = $false

function Initialize-Log {
    [CmdletBinding()]
    param(
        [string]$SolutionName = 'EnterpriseAdminTool',
        [string]$ScriptMode = 'run',
        [ValidateSet('Intune', 'General')]
        [string]$Type = 'General'
    )

    try {
        if ($Type -eq 'Intune') {
            $script:LogRoot = Join-Path $script:SystemDrive "IntuneLogs\$SolutionName"
            $script:LogFile = Join-Path $script:LogRoot "$SolutionName-$ScriptMode.txt"
        } else {
            $script:LogRoot = Join-Path $env:ProgramData "$SolutionName\Logs"
            $script:LogFile = Join-Path $script:LogRoot "$SolutionName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        }

        if (-not (Test-Path -LiteralPath $script:LogRoot)) {
            $null = [System.IO.Directory]::CreateDirectory($script:LogRoot)
        }
        if (-not (Test-Path -LiteralPath $script:LogFile)) {
            $null = [System.IO.File]::Create($script:LogFile).Dispose()
        }

        $script:LogReady = $true
        return $true
    }
    catch {
        Write-Host "Log initialization failed: $($_.Exception.Message)" -ForegroundColor Red
        $script:LogReady = $false
        return $false
    }
}

function Write-Banner {
    [CmdletBinding()]
    [Alias('Show-Banner')]
    param()

    $title      = '{0} | {1}' -f $SolutionName, $ScriptMode
    $bannerLine = '=' * 78
    $lines      = @('', $bannerLine, $title, $bannerLine)

    foreach ($line in $lines) {
        if ($line -eq $title) {
            Write-Host $line -ForegroundColor White
        } else {
            Write-Host $line -ForegroundColor DarkGray
        }

        if ($script:LogReady -and $script:LogFile) {
            Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue -WhatIf:$false
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    $color = switch ($Level) {
        "DEBUG"   { "DarkGray" }
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
    }
    Write-Host $logLine -ForegroundColor $color

    if ($script:LogReady -and $script:LogFile) {
        Add-Content -LiteralPath $script:LogFile -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue -WhatIf:$false
    }
}

function Finish-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ExitCode,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [switch]$NoExit
    )

    Write-Log -Message $Message -Level $Level
    if (-not $NoExit) {
        exit $ExitCode
    }
}