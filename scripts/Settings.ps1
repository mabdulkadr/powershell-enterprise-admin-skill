<#
.TITLE
    Settings

.SYNOPSIS
    Canonical settings persistence for WPF GUI tools (Pattern Q).

.DESCRIPTION
    The single source of truth for WPF tool settings persistence (Type 1).
    Stores and retrieves application preferences (theme state, last filters,
    Tenant/Client ID) as JSON in %LOCALAPPDATA%\<ToolName>\settings.json
    without storing secrets. Never include passwords or client secrets in
    $Settings. Wrappers Load-UserSettings / Save-UserSettings are kept for
    template back-compat (wpf-gui-tool.template.ps1).

.PARAMETER ToolNameOverride
    Override tool name for settings path. Defaults to $ToolName, $script:ToolName,
    or the caller script file name (without .template suffix).

.PARAMETER Settings
    Hashtable of settings to persist.

.TAGS
    Settings,GUI,WPF,PatternQ

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution)

.AUTHOR
    AI Generated

.VERSION
    1.0.0

.CHANGELOG
    1.0.0 (2026-08-24)
    - Initial release (extracted from wpf-gui-tool.template.ps1, Pattern Q)

.LASTUPDATE
    2026-08-24

.EXAMPLE
    $s = Get-AppSettings
    if ($s.Theme -eq 'Dark') { Set-Theme -IsDark $true }

.EXAMPLE
    Set-AppSettings -Settings @{ Theme = 'Dark' }

.NOTES
    - Security: never persist secrets; file is plain JSON.
    - Placeholder [ToolName] is treated as unset and falls back to PSCommandPath.
#>

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

function Get-AppSettings {
    [CmdletBinding()]
    param([string]$ToolNameOverride)
    $raw = if ($ToolNameOverride) { $ToolNameOverride } elseif ($ToolName -and $ToolName -ne '[ToolName]') { $ToolName } elseif ($script:ToolName -and $script:ToolName -ne '[ToolName]') { $script:ToolName } elseif ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { 'PowerShellApp' }
    if ($raw -like '*.template') { $raw = $raw.Substring(0, $raw.Length - 9) }
    if ([string]::IsNullOrWhiteSpace($raw) -or $raw -eq '[ToolName]') { $raw = 'PowerShellApp' }
    $effectiveName = $raw
    $path = Join-Path $env:LOCALAPPDATA "$effectiveName\settings.json"
    if (Test-Path -LiteralPath $path) {
        try { return (Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop) } catch { return [PSCustomObject]@{} }
    }
    return [PSCustomObject]@{}
}

function Set-AppSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][hashtable]$Settings,
        [string]$ToolNameOverride
    )
    $raw = if ($ToolNameOverride) { $ToolNameOverride } elseif ($ToolName -and $ToolName -ne '[ToolName]') { $ToolName } elseif ($script:ToolName -and $script:ToolName -ne '[ToolName]') { $script:ToolName } elseif ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { 'PowerShellApp' }
    if ($raw -like '*.template') { $raw = $raw.Substring(0, $raw.Length - 9) }
    if ([string]::IsNullOrWhiteSpace($raw) -or $raw -eq '[ToolName]') { $raw = 'PowerShellApp' }
    $effectiveName = $raw
    $dir = Join-Path $env:LOCALAPPDATA $effectiveName
    if (-not (Test-Path -LiteralPath $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue }
    $path = Join-Path $dir 'settings.json'
    try { $Settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding UTF8 -Force -ErrorAction Stop } catch { Write-Warning "Save settings failed: $($_.Exception.Message)" }
}

function Load-UserSettings {
    [CmdletBinding()] param([string]$ToolNameOverride)
    if ($PSBoundParameters.ContainsKey('ToolNameOverride')) { return Get-AppSettings -ToolNameOverride $ToolNameOverride }
    return Get-AppSettings
}

function Save-UserSettings {
    [CmdletBinding()] param([Parameter(Mandatory = $true)][hashtable]$Settings, [string]$ToolNameOverride)
    if ($PSBoundParameters.ContainsKey('ToolNameOverride')) { Set-AppSettings -Settings $Settings -ToolNameOverride $ToolNameOverride } else { Set-AppSettings -Settings $Settings }
}
