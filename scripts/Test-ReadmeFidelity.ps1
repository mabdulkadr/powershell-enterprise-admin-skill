<#
.TITLE
    Test-ReadmeFidelity

.SYNOPSIS
    Verifies a generated README.md structurally matches its skill variant template.

.DESCRIPTION
    Scope:
    Closes the verification gap that let delivered READMEs drift from the
    canonical variant templates (leaked meta-instruction lines, missing footer
    elements, wrong section order). Compares the README against
    templates/readme-<variant>.template.md and reports PASS/WARN/FAIL per check:
      - Hero div opens the file and closes before the first body section
      - At least five shields.io badges inside the hero div
      - Variant-specific badges (GUI requires UI + Theme, Intune pair requires Intune)
      - Heading sequence fidelity: order and level must match the template,
        emoji-insensitive, with conditional sections (Screenshots) skipped
      - No unfilled template placeholders ([Tool Name], [Your Name], ...)
      - No leaked meta-instruction lines copied from the template body
      - Canonical Disclaimer wording present verbatim
      - Footer star line and Built-with signature line present
    Safety guarantees:
    Strictly read-only. Never modifies anything on disk.
    Output contract:
    One [PASS]/[WARN]/[FAIL] line per check plus a RESULT summary. Exit code
    0 when zero FAIL lines were produced, otherwise 1 - suitable for CI gates.

.TAGS
    Verification,QualityGate,README,Documentation

.PLATFORM
    Windows

.MINROLE
    None (standalone tool)

.PERMISSIONS
    Standard user (no elevation required)

.AUTHOR
    AI Generated

.VERSION
    1.1.0

.CHANGELOG
    1.1.0 (2026-08-25)
    - Heading check upgraded from strict equality to ORDERED SUBSEQUENCE: the
      template's mandatory sections must appear in order at matching levels,
      while project-specific extension sections (Troubleshooting, FAQ,
      Changelog, ...) are permitted between them per the SKILL.md rule that
      templates are "the floor, not the ceiling".
    1.0.0 (2026-08-25)
    - Initial release: created after a delivered GUI README drifted from the
      variant template (leaked instruction line, incomplete footer) because no
      automated fidelity gate existed.

.LASTUPDATE
    2026-08-25

.EXAMPLE
    .\Test-ReadmeFidelity.ps1 -ReadmePath C:\Tools\README.md -Variant gui
    Verifies a WPF GUI project README against the GUI variant template.

.EXAMPLE
    .\Test-ReadmeFidelity.ps1 -ReadmePath C:\Pairs\README.md -Variant intune
    Verifies an Intune remediation pair README against its variant.

.NOTES
    - Exit codes: 0 = faithful (no FAIL), 1 = at least one FAIL.
    - WARN lines need human judgment; they do not fail the gate.
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ReadmePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('gui', 'cli', 'intune', 'basic')]
    [string]$Variant = 'gui',

    # Resolved after param block: $PSScriptRoot is unreliable inside param
    # default-value expressions on Windows PowerShell 5.1.
    [Parameter(Mandatory = $false)]
    [string]$TemplateDir = ''
)

$ErrorActionPreference = 'Stop'

if (-not $TemplateDir) {
    $scriptBase = if ($PSScriptRoot) { $PSScriptRoot }
        elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath }
        elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path }
        else { (Get-Location).Path }
    $TemplateDir = Join-Path (Split-Path -Parent $scriptBase) 'templates'
}

$script:FailCount = 0
$script:WarnCount = 0

function Write-Check {
    param(
        [ValidateSet('PASS', 'WARN', 'FAIL', 'SKIP')][string]$Status,
        [string]$Name,
        [string]$Detail = ''
    )
    switch ($Status) {
        'PASS' { Write-Host ("  [PASS] {0}" -f $Name) -ForegroundColor Green }
        'WARN' { Write-Host ("  [WARN] {0}{1}" -f $Name, $(if ($Detail) { " -> $Detail" })) -ForegroundColor Yellow; $script:WarnCount++ }
        'FAIL' { Write-Host ("  [FAIL] {0}{1}" -f $Name, $(if ($Detail) { " -> $Detail" })) -ForegroundColor Red;   $script:FailCount++ }
        'SKIP' { Write-Host ("  [SKIP] {0}" -f $Name) -ForegroundColor DarkGray }
    }
}

Write-Host ""
Write-Host ("=== README Fidelity: {0} (variant: {1}) ===" -f (Split-Path $ReadmePath -Leaf), $Variant) -ForegroundColor White

if (-not (Test-Path -LiteralPath $ReadmePath)) {
    Write-Check -Status 'FAIL' -Name 'README exists' -Detail $ReadmePath
    exit 1
}
$readme = Get-Content -LiteralPath $ReadmePath -Raw -Encoding UTF8

$templateFile = Join-Path $TemplateDir ("readme-{0}.template.md" -f $Variant)
if (-not (Test-Path -LiteralPath $templateFile)) {
    Write-Check -Status 'FAIL' -Name 'Variant template found' -Detail $templateFile
    exit 1
}
$template = Get-Content -LiteralPath $templateFile -Raw -Encoding UTF8

# --- Check 1: hero div opens the file and closes before the first body section ---
$heroOk = $readme.TrimStart().StartsWith('<div align="center">')
$firstClose = $readme.IndexOf('</div>')
$bodyStart = if ($readme -match '(?m)^#\s+[^\r\n]*overview') { $readme.IndexOf($Matches[0]) } else { -1 }
if ($heroOk -and $firstClose -ge 0 -and ($bodyStart -lt 0 -or $firstClose -lt $bodyStart)) {
    Write-Check -Status 'PASS' -Name 'Hero div opens file, closes before body'
} else {
    Write-Check -Status 'FAIL' -Name 'Hero div opens file, closes before body' -Detail 'README must open with <div align="center"> and close it before # Overview'
}

# --- Check 2: shields.io badge count inside hero ---
$heroSlice = if ($firstClose -gt 0) { $readme.Substring(0, $firstClose) } else { $readme }
$badgeCount = [regex]::Matches($heroSlice, 'img\.shields\.io').Count
if ($badgeCount -ge 5) {
    Write-Check -Status 'PASS' -Name ("shields.io badges inside hero ({0})" -f $badgeCount)
} else {
    Write-Check -Status 'FAIL' -Name 'shields.io badges inside hero' -Detail ("found {0}, expected >= 5" -f $badgeCount)
}

# --- Check 3: core badges ---
foreach ($coreBadge in @('license-MIT', 'powershell-5\.1%2B', 'Windows(-10|%2010)')) {
    if ($heroSlice -match $coreBadge) {
        Write-Check -Status 'PASS' -Name ("core badge: {0}" -f ($coreBadge -replace '\\', ''))
    } else {
        Write-Check -Status 'WARN' -Name ("core badge: {0}" -f ($coreBadge -replace '\\', '')) -Detail 'Expected in every variant hero'
    }
}

# --- Check 4: variant-specific badges ---
switch ($Variant) {
    'gui' {
        if ($heroSlice -match 'UI-' -and $heroSlice -match 'Theme-') {
            Write-Check -Status 'PASS' -Name 'GUI variant badges (UI + Theme)'
        } else {
            Write-Check -Status 'FAIL' -Name 'GUI variant badges (UI + Theme)'
        }
    }
    'intune' {
        if ($heroSlice -match 'Intune') {
            Write-Check -Status 'PASS' -Name 'Intune variant badge'
        } else {
            Write-Check -Status 'FAIL' -Name 'Intune variant badge'
        }
    }
    default { Write-Check -Status 'SKIP' -Name ("variant-specific badge ({0})" -f $Variant) }
}

# --- Check 5: heading sequence fidelity (ordered subsequence, emoji-insensitive) ---
function Get-StructuralHeadings {
    param([string]$Text, [bool]$IsTemplate)
    $out = @()
    foreach ($line in ($Text -split "`r?`n")) {
        if ($line -notmatch '^(#{1,2})\s+(.+)$') { continue }
        $level = $Matches[1].Length
        $text = ($Matches[2] -replace '[^\x00-\x7F]', '' -replace '[\[\]\(\)]', '' -replace '\s+', ' ').Trim().ToLower()
        if ($IsTemplate) {
            # Skip template-only placeholder rows and conditional sections
            if ($text -match 'feature \d|detail \d|screenshot|tool \d') { continue }
        } else {
            # Screenshots is conditional: omit silently when images do not exist
            if ($text -match 'screenshot') { continue }
        }
        $text = $text -replace 'tool name|solution name|script name|suite name', 'X'
        $out += [PSCustomObject]@{ Level = $level; Text = $text }
    }
    return $out
}
$tplHeads = Get-StructuralHeadings -Text $template -IsTemplate $true
$rdmHeads = Get-StructuralHeadings -Text $readme  -IsTemplate $false

# Two-pointer subsequence match: every mandatory template section must appear in
# order at the same level; extra project-specific sections between them are allowed.
$tplIdx = 0; $missing = @(); $extras = 0
for ($j = 0; $j -lt $rdmHeads.Count -and $tplIdx -lt $tplHeads.Count; $j++) {
    $t = $tplHeads[$tplIdx]
    $m = $rdmHeads[$j]
    # Template title placeholder ('X') matches any project title at the same level
    $isTitleWildcard = ($t.Level -eq $m.Level -and $t.Text -eq 'x')
    if ($isTitleWildcard) { $tplIdx++; continue }
    if ($t.Level -eq $m.Level -and $t.Text -eq $m.Text) { $tplIdx++; continue }
    $extras++
}
while ($tplIdx -lt $tplHeads.Count) { $missing += ('{0}|{1}' -f $tplHeads[$tplIdx].Level, $tplHeads[$tplIdx].Text); $tplIdx++ }

if ($missing.Count -eq 0) {
    Write-Check -Status 'PASS' -Name ("heading sequence fidelity ({0} mandatory + {1} extension)" -f $tplHeads.Count, $extras)
} else {
    Write-Check -Status 'FAIL' -Name 'Heading sequence fidelity' -Detail ("mandatory section(s) missing or out of order: {0}" -f ($missing -join ', '))
}

# --- Check 6: unfilled template placeholders ---
$placeholderWords = @('tool name', 'your name', 'your-handle', 'caption', 'explain the purpose', 'describe the interface', 'important note')
$unfilled = @()
foreach ($word in $placeholderWords) {
    if ($readme -match ('\[[^\]]*' + [regex]::Escape($word) + '[^\]]*\]')) { $unfilled += $word }
}
if ($unfilled.Count -eq 0) {
    Write-Check -Status 'PASS' -Name 'No unfilled template placeholders'
} else {
    Write-Check -Status 'FAIL' -Name 'No unfilled template placeholders' -Detail ($unfilled -join ', ')
}

# --- Check 7: no leaked meta-instruction lines from the template body ---
$metaPatterns = @(
    'This section exists ONLY',
    'never in CLI or Intune',
    'The template is the floor, not the ceiling',
    'Pick the matching variant',
    'Copy verbatim'
)
$leaked = @()
foreach ($p in $metaPatterns) {
    foreach ($line in ($readme -split "`r?`n")) {
        if ($line -match [regex]::Escape($p)) { $leaked += $p; break }
    }
}
if ($leaked.Count -eq 0) {
    Write-Check -Status 'PASS' -Name 'No leaked meta-instruction lines'
} else {
    Write-Check -Status 'FAIL' -Name 'No leaked meta-instruction lines' -Detail ($leaked -join '; ')
}

# --- Check 8: canonical Disclaimer wording verbatim ---
$disclaimer = 'provided as-is with no warranty of any kind. Test generated tools in a staging environment before deploying to production. The authors assume no liability for any damage or data loss resulting from their use.'
if ($readme.Contains($disclaimer)) {
    Write-Check -Status 'PASS' -Name 'Canonical Disclaimer wording verbatim'
} else {
    Write-Check -Status 'FAIL' -Name 'Canonical Disclaimer wording verbatim'
}

# --- Check 9: footer star line + signature ---
if ($readme -match 'star the repo') {
    Write-Check -Status 'PASS' -Name 'Footer star line'
} else {
    Write-Check -Status 'FAIL' -Name 'Footer star line'
}
if ($readme -match [regex]::Escape('Built with [**PowerShell Enterprise Admin**](https://github.com/mabdulkadr/powershell-enterprise-admin-skill)')) {
    Write-Check -Status 'PASS' -Name 'Footer Built-with signature'
} else {
    Write-Check -Status 'FAIL' -Name 'Footer Built-with signature'
}

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------

Write-Host ""
if ($script:FailCount -eq 0) {
    Write-Host ("RESULT: FAITHFUL TO TEMPLATE ({0} warning(s))" -f $script:WarnCount) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("RESULT: DRIFT DETECTED - {0} FAIL, {1} WARN" -f $script:FailCount, $script:WarnCount) -ForegroundColor Red
    exit 1
}
