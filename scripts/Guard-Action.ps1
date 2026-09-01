<#
.TITLE
    Guard-Action

.SYNOPSIS
    Canonical busy-state concurrency guard for WPF tools (Pattern H).

.DESCRIPTION
    The single source of truth for the Guard-Action / Release-Action pattern pair.
    Prevents concurrent and re-entrant button click handlers from racing each other
    and corrupting UI/background state.

.TAGS
    WPF,Concurrency,PatternH

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.1.1

.CHANGELOG
    1.1.1 (2026-08-30)
    - Fixed typo: $.LASTUPDATE was `$12026-08-20` (missing dot prefix on field
      keyword) - now parses correctly as a comment-based help field.
    1.1.0 (2026-08-20)
    - Canonical rich header upgrade to Enterprise Standards field order
    1.0.0 - Initial release

.LASTUPDATE
    2026-08-30

.PARAMETER ActionName
    Description of the action attempting to execute.

.EXAMPLE
    if (-not (Guard-Action 'Export CSV')) { return }
    try {
    # do work
    } finally {
    Release-Action
    }
.NOTES
    - Pattern H — dot-source from templates; never re-declare inline.

#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$script:isBusy = $false

function Guard-Action {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ActionName = 'Action'
    )

    if ($script:isBusy) {
        $msg = "Operation in progress - please wait: $ActionName"
        if (Get-Command Add-LogLine -ErrorAction SilentlyContinue) {
            Add-LogLine -Message $msg -Level 'WARNING'
        } else {
            Write-Warning $msg
        }
        return $false
    }
    $script:isBusy = $true
    return $true
}

function Release-Action {
    [CmdletBinding()]
    param()

    $script:isBusy = $false
}