<#
.TITLE
    Test-Skill - Canonical skill verification runner

.SYNOPSIS
    Validates the powershell-enterprise-admin skill itself: AST parse, header order, XAML checks, Get-Help smoke test, and style lints.

.DESCRIPTION
    Runs automated checks that previously required manual grep: AST parse for all scripts/*.ps1, header field order, #Requires placement, DynamicResource vs hardcoded hex, Add_Closing count, ValidateSet unification, file:// leak, Get-Help smoke test, TOC validation, and template integrity. Designed to be run from skill root or any child directory.

.TAGS
    Testing,Verification,SelfTest

.PLATFORM
    Windows

.PERMISSIONS
    None (local SYSTEM context)

.AUTHOR
    AI Generated

.VERSION
    1.2.0

.CHANGELOG
    1.2.0 (2026-09-01)
    - Add Hardcoded Rules count check (>=28), Export-CarbonHtml absence check, and evals.json count check (>=28).
    1.1.0 (2026-09-01)
    - Add Get-Help smoke test across all canonical scripts in scripts/.
    - Add SKILL.md TOC anchor validation check.
    - Add README structure map verification check.
    1.0.1 (2026-08-22)
    - Portable skill-root fallback: resolves any installed skill containing SKILL.md + scripts/Test-Skill.ps1; no hardcoded install path (rename-safe).
    1.0.0 (2026-08-21)
    - Initial release: replaces manual grep checks from README.md:296.

.LASTUPDATE
    2026-09-01

.EXAMPLE
    .\scripts\Test-Skill.ps1 -Verbose
    Shows per-file details.

.EXAMPLE
    .\scripts\Test-Skill.ps1
    Runs all checks from skill root and prints PASS/FAIL per check.

.NOTES
    - Execution context: runs locally, no elevation required
    - Exit codes: 0 = all checks passed, 1 = one or more failures
    - Log: no log file, console only
#>

#Requires -Version 5.1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$failed = 0
$passed = 0

function Write-Result {
  param([string]$Check, [bool]$Ok, [string]$Detail = "")
  if ($Ok) {
    Write-Host "PASS: $Check $Detail" -ForegroundColor Green
    $script:passed++
  } else {
    Write-Host "FAIL: $Check $Detail" -ForegroundColor Red
    $script:failed++
  }
}

# Resolve skill root (parent of scripts/)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$skillRoot = Split-Path -Parent $scriptDir
if (-not (Test-Path -LiteralPath (Join-Path $skillRoot "SKILL.md"))) {
  # Portable fallback: try PWD, then any installed skill that ships this self-test.
  $candidates = @($PWD.Path)
  $skillsBase = Join-Path $env:USERPROFILE ".config\opencode\skills"
  if (Test-Path -LiteralPath $skillsBase) {
    $candidates += @(Get-ChildItem -LiteralPath $skillsBase -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
  }
  foreach ($candidate in $candidates) {
    if ((Test-Path -LiteralPath (Join-Path $candidate "SKILL.md")) -and (Test-Path -LiteralPath (Join-Path $candidate "scripts\Test-Skill.ps1"))) {
      $skillRoot = $candidate
      break
    }
  }
}

Write-Host "Testing skill at: $skillRoot" -ForegroundColor Cyan

# 1. AST parse all scripts/*.ps1
Get-ChildItem -Path (Join-Path $skillRoot "scripts") -Filter "*.ps1" | ForEach-Object {
  $tokens = $null; $errors = $null
  $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
  Write-Result "AST $($_.Name)" ($errors.Count -eq 0) $(if ($errors.Count -gt 0) { $errors[0].Message } else { "" })
}

# 2. Header order: <# must be first non-empty line, #Requires immediately after #>
Get-ChildItem -Path (Join-Path $skillRoot "scripts") -Filter "*.ps1" | ForEach-Object {
  $first = (Get-Content -LiteralPath $_.FullName -TotalCount 1 -Encoding UTF8).Trim()
  $ok = $first -eq "<#"
  Write-Result "Header-first $($_.Name)" $ok "first line: $first"
  $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
  $hasRequiresAfterHeader = $content -match "(?s)<#.*?#>\s*\r?\n\s*#Requires -Version 5\.1"
  Write-Result "Requires-after-header $($_.Name)" $hasRequiresAfterHeader
}

# 3. No hardcoded file:// absolute paths in references/
$refs = Get-ChildItem -Path (Join-Path $skillRoot "references") -Filter "*.md"
$leak = $false
foreach ($f in $refs) {
  if (Select-String -LiteralPath $f.FullName -Pattern "file:///" -Quiet) { $leak = $true; Write-Host "  Leak in $($f.Name)" -ForegroundColor Yellow }
}
Write-Result "No file:/// leak in references/" (-not $leak)

# 4. No broken Opacity="=" in design-tokens.md
$dt = Join-Path $skillRoot "references/design-tokens.md"
$broken = Select-String -LiteralPath $dt -Pattern 'Opacity="="' -Quiet
Write-Result "Opacity fix in design-tokens.md" (-not $broken)

# 5. No stray "Level" string in event-log-patterns.md CSS block
$elp = Join-Path $skillRoot "references/event-log-patterns.md"
$stray = $false
if (Test-Path -LiteralPath $elp) {
  $lines = Get-Content -LiteralPath $elp -Encoding UTF8
  $stray = ($lines | Where-Object { $_ -match '^\s*"Level"\s*$' }).Count -gt 0
}
Write-Result "No stray Level in event-log-patterns.md" (-not $stray)

# 6. ValidateSet unification (7 values)
$invokeSet = (Select-String -LiteralPath (Join-Path $skillRoot "scripts/Invoke-GraphRequestWithRetry.ps1") -Pattern "ValidateSet.*EntraID").Line
$has7a = $invokeSet -match "Teams" -and $invokeSet -match "SharePoint"
Write-Result "ValidateSet 7 values in Invoke-GraphRequestWithRetry.ps1" $has7a $invokeSet.Trim()
$graphSet = (Select-String -LiteralPath (Join-Path $skillRoot "scripts/Get-Graph403Message.ps1") -Pattern "ValidateSet.*EntraID").Line
$has7b = $graphSet -match "Teams" -and $graphSet -match "SharePoint"
Write-Result "ValidateSet 7 values in Get-Graph403Message.ps1" $has7b $graphSet.Trim()

# 7. Write-Log default Type = General (allow single or double quotes, spaces)
$wl = Get-Content -LiteralPath (Join-Path $skillRoot "scripts/Write-Log.ps1") -Raw -Encoding UTF8
Write-Result "Write-Log default Type General" ($wl -match '\$Type\s*=\s*[''"]General[''"]')

# 7b. Canonical CLI Write-Summary helper present in Write-Log.ps1
Write-Result "Write-Log defines Write-Summary helper" ($wl -match 'function\s+Write-Summary')

# 8. Get-Content -Raw -Encoding UTF8 in Test-XamlFile.ps1
$tx = Get-Content -LiteralPath (Join-Path $skillRoot "scripts/Test-XamlFile.ps1") -Raw -Encoding UTF8
Write-Result "Test-XamlFile uses -Encoding UTF8" ($tx -match "Get-Content.*-Encoding UTF8")

# 9. Single canonical header note exists
Write-Result "_header-canonical.md exists" (Test-Path -LiteralPath (Join-Path $skillRoot "references/_header-canonical.md"))
Write-Result "_logging-canonical.md exists" (Test-Path -LiteralPath (Join-Path $skillRoot "references/_logging-canonical.md"))
Write-Result "_graph-canonical.md exists" (Test-Path -LiteralPath (Join-Path $skillRoot "references/_graph-canonical.md"))

# 10. SKILL.md lean check (target <900, ideal <500 — was 768 at v1.2; raised
#     for Empty-Message Spacer Rule in v1.3, CLI Write-Summary in 1.3.x,
#     and HTML Fidelity Rules 24-28 + Audit Protocol in v1.5.0 as
#     canonical content legitimately accumulates)
$skillLines = (Get-Content -LiteralPath (Join-Path $skillRoot "SKILL.md") -Encoding UTF8).Count
Write-Result "SKILL.md lean (<900 lines)" ($skillLines -lt 900) "$skillLines lines"

# 10b. Template library: every scaffold exists, parses, and obeys header order
$templatesDir = Join-Path $skillRoot "templates"
Write-Result "templates/ directory exists" (Test-Path -LiteralPath $templatesDir)
if (Test-Path -LiteralPath $templatesDir) {
  $expectedTemplates = @(
    "README.md",
    "cli-tool.template.ps1", "wpf-gui-tool.template.ps1",
    "intune-detect.template.ps1", "intune-remediate.template.ps1", "intune-notification.template.ps1",
    "macos-script.template.sh",
    "readme-cli.template.md", "readme-gui.template.md", "readme-intune-pair.template.md", "readme-suite.template.md"
  )
  foreach ($t in $expectedTemplates) {
    Write-Result "Template exists: $t" (Test-Path -LiteralPath (Join-Path $templatesDir $t))
  }
  Get-ChildItem -Path $templatesDir -Filter "*.template.ps1" | ForEach-Object {
    $tokens = $null; $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
    Write-Result "Template AST $($_.Name)" ($errors.Count -eq 0) $(if ($errors.Count -gt 0) { $errors[0].Message } else { "" })
    $first = (Get-Content -LiteralPath $_.FullName -TotalCount 1 -Encoding UTF8).Trim()
    Write-Result "Template header-first $($_.Name)" ($first -eq "<#")
    $tc = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    Write-Result "Template requires-after-header $($_.Name)" ($tc -match "(?s)<#.*?#>\s*\r?\n\s*#Requires -Version 5\.1")
    Write-Result "Template no RunAsAdmin $($_.Name)" (-not ($tc -match '#Requires\s+-RunAsAdministrator'))
  }
  $sh = Join-Path $templatesDir "macos-script.template.sh"
  if (Test-Path -LiteralPath $sh) {
    $shebang = (Get-Content -LiteralPath $sh -TotalCount 1).Trim()
    Write-Result "macOS template shebang" ($shebang -eq "#!/bin/bash")
  }
}

# 11. Get-Help smoke test for canonical scripts
Get-ChildItem -Path (Join-Path $skillRoot "scripts") -Filter "*.ps1" | ForEach-Object {
  $helpInfo = Get-Help $_.FullName -Full -ErrorAction SilentlyContinue
  $hasHelp = ($null -ne $helpInfo) -and ($helpInfo.description -or $helpInfo.Synopsis)
  Write-Result "Get-Help parse $($_.Name)" $hasHelp
}

# 12. SKILL.md TOC vs Headings check
$skillContent = Get-Content -LiteralPath (Join-Path $skillRoot "SKILL.md") -Raw -Encoding UTF8
$tocSectionMatch = [regex]::Match($skillContent, '(?s)##\s+Table of Contents.*?(?=\r?\n---|\r?\n## )')
$tocSection = if ($tocSectionMatch.Success) { $tocSectionMatch.Value } else { $skillContent }
$tocAnchors = [regex]::Matches($tocSection, '\[([^\]]+)\]\(#([a-z0-9-]+)\)')
$headings = [regex]::Matches($skillContent, '(?m)^##+\s+(.+)$')
$headingSlugs = @($headings | ForEach-Object {
    $_.Groups[1].Value.Trim().ToLower() -replace '[^\w\s-]', '' -replace '\s+', '-'
})
$orphanedTOC = 0
foreach ($match in $tocAnchors) {
    $anchor = $match.Groups[2].Value
    if ($headingSlugs -notcontains $anchor -and $anchor -ne 'table-of-contents') {
        $orphanedTOC++
    }
}
Write-Result "SKILL.md TOC anchors valid" ($orphanedTOC -eq 0) "$orphanedTOC orphaned anchor(s)"

# 13. README structure map present
$readmeContent = Get-Content -LiteralPath (Join-Path $skillRoot "README.md") -Raw -Encoding UTF8
$hasMap = $readmeContent -match 'scripts/' -and $readmeContent -match 'templates/' -and $readmeContent -match 'references/'
Write-Result "README structure map present" $hasMap

# 14. SKILL.md Hardcoded Rules count >= 28
$hardcodedSection = $skillContent.Substring($skillContent.IndexOf('## Hardcoded Rules'))
$hardcodedSection = $hardcodedSection.Substring(0, $hardcodedSection.IndexOf('## Lessons Learned'))
$ruleCount = ([regex]::Matches($hardcodedSection, '(?m)^\d+\.\s+\*\*')).Count
Write-Result "SKILL.md Hardcoded Rules >=28" ($ruleCount -ge 28) "$ruleCount rules"

# 15. Export-CarbonHtml must be absent as canonical helper (only allowed in "not X" explanatory text)
$skillRaw = Get-Content -LiteralPath (Join-Path $skillRoot "SKILL.md") -Raw -Encoding UTF8
$hasCarbonHtmlAsHelper = $skillRaw -match '`Export-CarbonHtml`' -or $skillRaw -match 'via the canonical.*Export-CarbonHtml'
Write-Result "No Export-CarbonHtml as canonical helper in SKILL.md" (-not $hasCarbonHtmlAsHelper)

# 16. evals.json eval count >= 28
$evalsPath = Join-Path $skillRoot "evals/evals.json"
$evalsCount = 0
if (Test-Path -LiteralPath $evalsPath) {
    try { $evalsJson = Get-Content -LiteralPath $evalsPath -Raw -Encoding UTF8 | ConvertFrom-Json; $evalsCount = $evalsJson.evals.Count } catch { $evalsCount = 0 }
}
Write-Result "evals.json >=28 evals" ($evalsCount -ge 28) "$evalsCount evals"

Write-Host "`nResults: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) { exit 1 } else { exit 0 }
