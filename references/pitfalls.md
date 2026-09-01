# Known Pitfalls — PS 5.1 WPF

Every crash listed here was debugged in production. The fix is included. Read this file before you start writing WPF — these are the 21+ ways to crash the tool at ShowDialog or runtime.

---

## Table of Contents

1. [Table of Contents](#table-of-contents)
2. [PS 5.1 Specific Crashes](#ps-51-specific-crashes)
3. [XAML Silent Failures](#xaml-silent-failures)
4. [Theme Issues](#theme-issues)
5. [Job / Thread Issues](#job-thread-issues)
6. [CLI Script Traps](#cli-script-traps)
7. [Build Verification](#build-verification)
8. [Pitfall: Measure-Object .Sum Returns $null on Empty Sets](#pitfall-measure-object-sum-returns-null-on-empty-sets)
9. [Pitfall: External Cleanup Processes Can Hang Forever](#pitfall-external-cleanup-processes-can-hang-forever)
10. [Trade-off: The Canonical Rich Header Disables Get-Help](#trade-off-the-canonical-rich-header-disables-get-help)
11. [Pitfall: Test-Path Throws on ACL-Protected Paths](#pitfall-test-path-throws-on-acl-protected-paths)
12. [Pitfall: PS 5.1 Reads BOM-less UTF-8 as ANSI](#pitfall-ps-51-reads-bom-less-utf-8-as-ansi)
13. [Pitfall: WhatIf Propagates Into Logging Helpers](#pitfall-whatif-propagates-into-logging-helpers)
14. [Pitfall: $PSScriptRoot Is Empty When Dot-Sourced](#pitfall-psscriptroot-is-empty-when-dot-sourced)
15. [Pitfall: Initial Theme Not Applied — All-White Screen Until First Toggle](#pitfall-initial-theme-not-applied-all-white-screen-until-first-toggle)
16. [Pitfall: Standalone [HelpMessage()] Attribute Crashes PS 5.1](#pitfall-standalone-helpmessage-attribute-crashes-ps-51)
17. [Pitfall: Array-Preserve Comma Cannot Combine With Splatting Syntax](#pitfall-array-preserve-comma-cannot-combine-with-splatting-syntax)
18. [Pitfall: Indexer Assignment Into XamlReader Resources Corrupts Deferred DynamicResource](#pitfall-indexer-assignment-into-xamlreader-resources-corrupts-deferred-dynamicresource)
19. [Pitfall: Bracket Paths Turn -Path Into Wildcards And Break Log Writes](#pitfall-bracket-paths-turn-path-into-wildcards-and-break-log-writes)
20. [Pitfall: Event Handlers Cannot See Builder Function Locals](#pitfall-event-handlers-cannot-see-builder-function-locals)
21. [Pitfall: Invisible U+FEFF Ghosts Survive Clean Parses After Programmatic Splices](#pitfall-invisible-uffeff-ghosts-survive-clean-parses-after-programmatic-splices)
22. [Pitfall: PowerShell -replace Is Case-Insensitive](#pitfall-powershell--replace-is-case-insensitive)
23. [Pitfall: Load XAML With Parse First — Load Is A Fallback Only](#pitfall-load-xaml-with-parse-first--load-is-a-fallback-only)
24. [Pitfall: Capture A Hash Baseline At Delivery — Treat Mismatch As External Drift First](#pitfall-capture-a-hash-baseline-at-delivery--treat-mismatch-as-external-drift-first)
25. [Pitfall: HTML Report — Grade on KPI, Body, Row, and Chart Provenance — Not "Has a Table"](#pitfall-html-report-grade-on-kpi-body-row-and-chart-provenance-not-has-a-table)
26. [Pitfall: HTML Body Must Not Depend on $rows From a Different try Block (Try-Scope Leak)](#pitfall-html-body-must-not-depend-on-rows-from-a-different-try-block-try-scope-leak)
27. [Pitfall: $_ Shadowing Inside Nested ForEach-Object Breaks Property Access](#pitfall-shadowing-inside-nested-foreach-object-breaks-property-access)
28. [Pitfall: Read param() Before Invoking — Parameter Errors Are Caller Errors](#pitfall-read-param-before-invoking-parameter-errors-are-caller-errors)
29. [Pitfall: Recursive Get-ChildItem on Drive Root or Large Trees Times Out](#pitfall-recursive-get-childitem-on-drive-root-or-large-trees-times-out)
30. [Pitfall: KPI Tiles Must Be Domain-Specific — Generic OK/Failed Counters Are Drift](#pitfall-kpi-tiles-must-be-domain-specific-generic-okfailed-counters-are-drift)
31. [Pitfall: HTML Uses Carbon Dark; WPF Uses Tailwind Slate — Never Mix](#pitfall-html-uses-carbon-dark-wpf-uses-tailwind-slate-never-mix)
32. [Pitfall: Full Triage Pass Before Any Fix — Output Sorted FAIL→WEAK→PASS Table](#pitfall-full-triage-pass-before-any-fix-output-sorted-failweakpass-table)
33. [Pitfall: Bulk Audit (N > 3 files) → Task Agent; Single-File (N ≤ 3) → Inline read+edit](#pitfall-bulk-audit-n-3-files-task-agent-single-file-n-3-inline-readedit)
34. [Pitfall: HtmlEncode Every Dynamic Cell — No Exceptions; Wrap Paths in code](#pitfall-htmlencode-every-dynamic-cell-no-exceptions-wrap-paths-in-code)
35. [Pitfall: Pre-Existing Bugs Out of Scope Unless HTML Depends on Them](#pitfall-pre-existing-bugs-out-of-scope-unless-html-depends-on-them)
36. [Pitfall: Three-Gate HTML Verification — Parser → Run → Row/Cell/Badge Count](#pitfall-three-gate-html-verification-parser-run-rowcellbadge-count)

---


## PS 5.1 Specific Crashes

### Join-Path Multiple Child Paths

In PowerShell 5.1, passing more than one child path (e.g., `Join-Path $a 'b' 'c'`) throws a `ParameterBindingException`. PowerShell 5.1 only accepts two positional arguments.

```powershell
# ❌ Crashes in PS 5.1
Join-Path $projectRoot 'src' 'Features' 'Compiler.ps1'

# ✅ Fix 1: Nest the calls
Join-Path (Join-Path (Join-Path $projectRoot 'src') 'Features') 'Compiler.ps1'

# ✅ Fix 2: Use backslash
Join-Path $projectRoot 'src\Features\Compiler.ps1'
```

### Pester 3.4.0 Compatibility

Windows PowerShell 5.1 ships with **Pester 3.4.0** by default. Writing tests using Pester 5+ syntax crashes immediately on standard Windows machines.

```powershell
# ❌ Crashes on Pester 3.4.0
Describe 'Test' {
    BeforeAll { # Outside Describe block in 3.4.0 = crash
        $x = 1
    }
    It 'works' { $x | Should -Be 1 }  # 'Should -Be' is Pester 5+ syntax
}

# ✅ Pester 3.4.0 compatible
Describe 'Test' {
    $x = 1  # Setup inline, not in BeforeAll
    It 'works' { $x | Should Be 1 }  # 'Should Be' without dash
}
```

If you need Pester 5 features, install Pester 5 first and update `$env:PSModulePath` — but understand that's not what a standard Windows box has.

### Thumb.CornerRadius Does Not Exist

`System.Windows.Controls.Primitives.Thumb` in .NET 4.x WPF has **NO `CornerRadius` dependency property**. Setting `CornerRadius` on a `<Thumb>` (or `{TemplateBinding CornerRadius}` on `<Thumb.Template>`) causes an unhandled `XamlParseException`.

```xml
<!-- ❌ Crashes at ShowDialog -->
<Thumb CornerRadius="5" />

<!-- ✅ Never customize ScrollBar templates. Use system default. -->
<!-- If absolutely needed, hardcode CornerRadius on inner Border only: -->
<Thumb Template="..." > <!-- template with hardcoded Border CornerRadius="3" inside -->
```

### UIElement.Opacity Must Be Fully Qualified

In `BtnBase` control template triggers, use `UIElement.Opacity` (fully qualified). Plain `Opacity` may resolve to the wrong target.

```xml
<!-- ✅ Proven to work -->
<Setter TargetName="border" Property="UIElement.Opacity" Value="0.85"/>
```

### Here-String Opening Must Be Alone

`@"<content>"` on one line is a parse error. Opening `@"` must be followed by a newline.

```powershell
# ❌ Parse error
$xaml = @'<Window></Window>'@

# ✅ Opening on its own line
$xaml = @'
<Window></Window>
'@
```

### [void] Cast on ShowDialog

In PS 5.1 STA mode, `[void]$Window.ShowDialog()` suppresses the dialog result. Without `[void]`, dialog result can interfere with cleanup code that runs after.

```powershell
# ✅ Always cast
[void]$Window.ShowDialog()
```

### `if` as Expression

`Write-Host (if ($x) { 'a' } else { 'b' })` fails with "The term 'if' is not recognized" in PS 5.1.

```powershell
# ❌ Parse error in 5.1
Write-Host (if ($x) { 'a' } else { 'b' })

# ✅ Assign first
$value = if ($x) { 'a' } else { 'b' }
Write-Host $value
```

### ValidateSet Must Include All Used Values

If `Add-LogLine` has `ValidateSet('INFO','SUCCESS','WARNING','ERROR')` but code passes `'DEBUG'`, it crashes at runtime with a validation error. Always include `'DEBUG'` in the ValidateSet.

```powershell
# ✅ Canonical Add-LogLine signature (full implementation: scripts/Add-LogLine.ps1)
function Add-LogLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR','DEBUG')]
        [string]$Level = 'INFO'
    )
    # ...
}
```

---

## XAML Silent Failures

### Control Name Mismatch

`FindName('lblStatus')` doesn't match XAML `x:Name="StatusTxt"` — all controls become `$null`, the app runs but every handler fails silently.

**Fix:** Verify control name checklist — every `x:Name` in XAML must have a matching `FindName()` call. Use `git grep x:Name` then verify against `git grep FindName`.

### Missing StaticResource Key

`{StaticResource MissingKey}` causes no error at parse time. Crashes at `ShowDialog()` with:

```
Provide value on 'System.Windows.StaticResourceExtension' threw an exception
```

**Fix:** Use `{DynamicResource}` instead when the key may not exist at compile time (e.g., dialog windows that inherit from the main window).

### Unescaped Ampersand

`&` in XAML text content or attribute causes `XamlParseException: An error occurred while parsing EntityName`.

```xml
<!-- ❌ Crashes -->
<TextBlock Text="NETWORK & STORAGE"/>

<!-- ✅ Use &amp; -->
<TextBlock Text="NETWORK &amp; STORAGE"/>
```

This is the **single most common XAML crash** in PS 5.1. Always test with `XamlReader.Parse()` before launching.

### Mismatched Grid Closing Tags

Extra or missing `</Grid>` causes `XamlParseException` with a misleading element mismatch error. When removing an outer `<Grid>`, you must also remove its matching `</Grid>` AND remove `Grid.Row` attributes from children.

**Fix:** Count opening `<Grid>` vs closing `</Grid>` tags — they must be equal.

### Duplicate Content Property

`<Button Content="X"><StackPanel>...</StackPanel></Button>` fails. When using child elements as button content, remove the `Content` attribute.

```xml
<!-- ❌ Duplicate Content -->
<Button Content="X"><StackPanel>...</StackPanel></Button>

<!-- ✅ Choose one -->
<Button Content="X"/>
<!-- or -->
<Button><StackPanel>...</StackPanel></Button>
```

### Header Rows Must Pin Right-Side Buttons With LastChildFill="False"

A plain `DockPanel` defaults to `LastChildFill="True"`, so the last child stretches and sits NEXT TO the label instead of docking to the far right. Header rows that pin buttons right (Live Log Copy/Clear) need the attribute.

```xml
<!-- ✅ Label left, buttons pinned right, same row -->
<DockPanel LastChildFill="False">
    <TextBlock DockPanel.Dock="Left" Text="Live Log"/>
    <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
        <Button Content="Copy"/> <Button Content="Clear"/>
    </StackPanel>
</DockPanel>
```

---

## Theme Issues

### Background Tints Hardcoded

`Background="#DBEAFE"` in XAML has wrong contrast in dark mode.

**Fix:** Use DynamicResource tokens (`{DynamicResource IconBg}`, `{DynamicResource AccentTintBrush}`) for every background tint. Never hardcode tints.

### IsMouseOver on Cards Causes Flickering

Cards/Borders with `IsMouseOver` triggers flicker and feel unpolished.

**Rule:** Cards are STATIC. Only `<Button>` elements get hover effects via their ControlTemplate. If you find yourself adding IsMouseOver to a Card, you wanted a Button.

### Unicode Cleanup Order

The order of `-replace` operations matters.

```powershell
# ❌ WRONG: Curly quote already removed by first line; second replace is dead code
$clean = $xaml -replace '[﻿‌‍’]', '' -replace ''', "'"

# ✅ CORRECT: Targeted replacement first, then control-char strip
$xaml = $xaml -replace ''', "'"
$clean = $xaml -replace '[﻿‌‍‎‏‪-‮]', ''
```

### Dark Mode Visual Tree Walk

For runtime-generated content (log entries, dynamic panels), you must walk the visual tree and re-color text dynamically:

```powershell
# When dark mode activates, text with (R+G+B)/3 < 160 should be set to #F1F5F9
# When light mode restores, text with brightness > 200 should be set to #0F172A
```

`Set-Theme` handles tokens for resources, but text created at runtime (in code) doesn't use tokens and must be updated manually.

---

## Job / Thread Issues

### Background Jobs Not Cleaned Up

Jobs still running after window close become orphaned state. The job process keeps holding memory until garbage collection eventually catches it.

**Fix:** In `Add_Closing` handler (the ONE in your tool):

```powershell
if ($script:DataLoadJob) {
    Stop-Job -Job $script:DataLoadJob -ErrorAction SilentlyContinue
    Remove-Job -Job $script:DataLoadJob -Force -ErrorAction SilentlyContinue
}
if ($script:DataLoadTimer) { $script:DataLoadTimer.IsEnabled = $false }
```

### Two Add_Closing Handlers

If two separate blocks both register `Add_Closing`, the first one sets `$script:LogFileWriter` to `$null` and the second one's cleanup silently skips.

**Rule:** ALL UI event handlers including `Add_Closing` belong in ONE file. Never duplicate handlers across multiple registration points.

### BeginInvoke Without EndInvoke

`[powershell]::BeginInvoke()` not paired with `EndInvoke()` on completion is a memory leak. Always call both in the completion branch.

```powershell
# ❌ Leaks
$result = $script:asyncInstance.BeginInvoke()
if ($result.IsCompleted) {
    $output = $script:asyncInstance.EndInvoke($result)  # OK, paired
    # But: never Dispose!
}

# ✅ Paired + Disposed
$result = $script:asyncInstance.BeginInvoke()
if ($result.IsCompleted) {
    try {
        $output = $script:asyncInstance.EndInvoke($result)
    } finally {
        $script:asyncInstance.Dispose()
        $script:asyncInstance = $null
        $script:asyncResult = $null
    }
}
```

### N+1 WMI Query Pattern

Calling `Get-CimInstance Win32_ComputerSystem` multiple times (once per property) is 15 separate WMI queries. Each takes 50-200ms.

**Fix:** Query each class ONCE and reuse:

```powershell
# ❌ 15 queries
$cs = Get-CimInstance Win32_ComputerSystem
$name = $cs.Name
$manufacturer = (Get-CimInstance Win32_ComputerSystem).Manufacturer  # query again
$model = (Get-CimInstance Win32_ComputerSystem).Model                # query again

# ✅ 1 query, reused
$cs = Get-CimInstance Win32_ComputerSystem
$name = $cs.Name
$manufacturer = $cs.Manufacturer
$model = $cs.Model
```

### Null Data from Background Job

`$data.ComputerName` on `$null` gives "Cannot index into a null array" with a misleading ERROR log.

**Fix:** Always add null guard:

```powershell
$data = Receive-Job -Job $script:DataLoadJob -Keep
if (-not $data) {
    Add-LogLine 'No data received from background job' 'WARNING'
    return
}
```

---

## CLI Script Traps

### ShouldProcess('dummy') as a WhatIf Probe

Calling `$PSCmdlet.ShouldProcess('dummy')` to "detect" WhatIf mode misuses the API. `ShouldProcess` is not an interrogation — every call emits a spurious `What if: Performing the operation "dummy"...` line and participates in confirmation logic. Scripts that pass its result around as a flag (`-WhatIf:$PSCmdlet.ShouldProcess('dummy')`) pollute the output with dummy operations and thread the flag manually through every helper.

```powershell
# ❌ Spurious "What if: ... dummy ..." output, manual flag threading
Clean-TargetFolder -Path $path -WhatIf:$PSCmdlet.ShouldProcess("dummy")

# ✅ Preference propagation does this natively
[CmdletBinding(SupportsShouldProcess)]
param()
# Helpers declare [CmdletBinding(SupportsShouldProcess)] too;
# -WhatIf on the script flows into every helper's Remove-Item automatically.
# Log the mode via $WhatIfPreference instead of probing ShouldProcess.
```

**Rule:** Never call `ShouldProcess` with placeholder arguments to detect WhatIf mode. Use `[CmdletBinding(SupportsShouldProcess)]` + preference propagation; log state via `$WhatIfPreference`.

### Mixed File+Folder Enumeration Double-Delete

Enumerating a tree once with `Get-ChildItem -Recurse` returns each folder BEFORE its children. Deleting a folder with `Remove-Item -Recurse` mid-iteration makes every child encountered later throw (already deleted) — inflating failure counts with phantom failures AND undercounting freed space (the children's sizes are never recorded).

```powershell
# ❌ Folder deleted recursively, then its own children fail one by one
$items = Get-ChildItem -Path $Path -Recurse -Force
foreach ($item in $items) { Remove-Item $item.FullName -Recurse -Force }

# ✅ Two passes: stale files first, then empty dirs deepest-first
Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

Get-ChildItem -LiteralPath $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
        if (-not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue)) {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
```

**Rule:** Two passes — stale files first, then empty directories sorted deepest-first (`Sort-Object { $_.FullName.Length } -Descending`). Never mix `-Recurse` folder deletion into a file iteration.

---

## Build Verification

Before running the tool, test the XAML with **both** parsing methods (canonical script: `scripts/Test-XamlFile.ps1`). They catch different errors:

```powershell
# Method 1: Catches syntax errors
try {
    [Windows.Markup.XamlReader]::Parse((Get-Content 'xaml\MainWindow.xaml' -Raw))
    Write-Host "Parse: OK"
} catch {
    Write-Host "Parse FAILED: $_"
}

# Method 2: Catches runtime resource binding issues (this is what ShowDialog uses)
try {
    $xml = [xml](Get-Content 'xaml\MainWindow.xaml' -Raw)
    $reader = New-Object System.Xml.XmlNodeReader($xml)
    [Windows.Markup.XamlReader]::Load($reader)
    Write-Host "Load: OK"
} catch {
    Write-Host "Load FAILED: $_"
}
```

If both succeed, run the app and verify `ShowDialog()` reaches. Even valid XAML can crash on layout/measure if templates have invalid bindings.

**Common ShowDialog crash causes:**

- Invalid template bindings (e.g., binding to a property that doesn't exist)
- Missing dependency properties
- Conflicting global styles (two `Style x:Key="BtnBase"` definitions)
- Unescaped ampersand (caught by Method 1)
- Missing StaticResource key (caught by Method 2)

If ShowDialog crashes, comment out everything below the failing line and add back incrementally until you find the culprit.

**Headless/CI clipboard trap:** automated sessions cannot open the clipboard (`CLIPBRD_E_CANT_OPEN`, even for bare `SetText`). When verifying a Copy button programmatically, assert the entry-buffer StringBuilder format instead of calling `GetText`.

---

## Pitfall: Measure-Object .Sum Returns $null on Empty Sets

`(Get-ChildItem ... | Measure-Object -Property Length -Sum).Sum` returns **$null** — not 0 — when no files match. Downstream arithmetic then silently reports 0 bytes for every folder, which is exactly how one production disk-cleanup detector shipped reporting all folder sizes as 0 until v1.1.

**Always null-coalesce before using the sum:**

```powershell
$size = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum
if ($null -eq $size) { $size = 0 }
```

**Verify with an empty folder** before trusting any size-based threshold logic: a compliant device (nothing stale) must measure as 0, not crash or misreport.

---

## Pitfall: External Cleanup Processes Can Hang Forever

Tools that shell out to long-running executables (`cleanmgr.exe`, installers, DISM) can block remediation indefinitely. Intune will eventually kill the script and mark it failed even though most work succeeded.

**Pattern: bounded wait + kill + count-as-failure:**

```powershell
$proc = Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:100" -NoNewWindow -PassThru
try {
    Wait-Process -Id $proc.Id -Timeout 300 -ErrorAction Stop
}
catch {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
    $failedCount++
}
```

The timeout converts an indefinite hang into a counted per-target failure so the run can still report partial success.

---

## Trade-off: The Canonical Rich Header Disables Get-Help

The canonical header (`.TITLE .TAGS .PLATFORM .PERMISSIONS ...`) contains keywords that PowerShell's comment-based help parser does not recognize. **One unrecognized dotted keyword anywhere in the block causes Get-Help to ignore the ENTIRE block** - even keywords placed after `.NOTES`, and even when known keywords come first.

Verified empirically:

- Flat `.TITLE` first, then `.SYNOPSIS` -> Get-Help shows only the SYNTAX line
- Classic indented help only -> Get-Help works
- `.SYNOPSIS` first with metadata after `.NOTES` -> still broken

**This is an accepted trade-off, not a bug.** The Enterprise Standards ecosystem chose machine/human-readable metadata over Get-Help integration. Do NOT "fix" delivered scripts by deleting the metadata fields to restore Get-Help - the metadata is the contract. If inline help matters for a specific tool, add a separate `about_*.txt` or README instead of mutating the header.

---

## Pitfall: Test-Path Throws on ACL-Protected Paths

`Test-Path` does NOT reliably return `$false` for inaccessible paths. When a path's ACL denies traversal (other users' profiles, `WsiAccount` temp folders, locked-down service profiles), it throws a terminating error - and with `$ErrorActionPreference = 'Stop'` that exception escapes any `Where-Object` filter or pipeline and aborts the whole run. A detection script crashed with exit 2 ("Access is denied") on machines with ACL-protected profiles because of a bare `Test-Path` probe inside a filter.

```powershell
# ❌ One protected profile kills the entire enumeration
$targets = Get-ChildItem 'C:\Users' -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName 'AppData\Local\Temp')
}

# ✅ Probe each untrusted path in its own try/catch; skip + log at DEBUG
foreach ($profile in Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue) {
    $tempPath = Join-Path $profile.FullName 'AppData\Local\Temp'
    try {
        if (-not (Test-Path -LiteralPath $tempPath)) { continue }
        # ... enumerate / clean $tempPath
    }
    catch [System.UnauthorizedAccessException] {
        Add-LogLine -Level DEBUG -Message "Skipped (access denied): $tempPath"
    }
    catch {
        Add-LogLine -Level DEBUG -Message "Skipped ($($_.Exception.GetType().Name)): $tempPath"
    }
}
```

**Rule:** Never trust `Test-Path` to return `$false` on untrusted paths. Wrap every probe of ACL-protected locations (user profiles, system folders) in its own try/catch when EAP is Stop, and degrade gracefully by skipping with a DEBUG log line.

---

## Pitfall: PS 5.1 Reads BOM-less UTF-8 as ANSI

Windows PowerShell 5.1 defaults are not UTF-8: `Get-Content` without `-Encoding` reads BOM-less UTF-8 files using the ANSI code page, mangling every multi-byte character (emoji, Arabic, box-drawing). This silently breaks verification - a grep for an emoji heading reported 0 matches on a file where all occurrences existed. The same applies on write: `Add-Content`/`Set-Content` without `-Encoding UTF8` write logs through the ANSI code page, so non-ASCII log lines arrive corrupted.

```powershell
# ❌ Verification lies: 0 matches for content that exists
(Get-Content $file -Raw) -match '## ⚠ Disclaimer'

# ✅ Explicit encoding both directions
Get-Content $file -Raw -Encoding UTF8
Add-Content -Path $logFile -Value $line -Encoding UTF8
```

**Rule:** In PS 5.1 always pass `-Encoding UTF8` explicitly - when reading files that may contain non-ASCII characters (especially verification greps), and on every log/file write. Never rely on 5.1 encoding defaults.

---

## Pitfall: WhatIf Propagates Into Logging Helpers

With `[CmdletBinding(SupportsShouldProcess)]`, `-WhatIf` flows into EVERY cmdlet call - including the infrastructure writes inside logging helpers. A dry run then spams `What if: Performing the operation "Add-Content"...` lines AND skips writing the log entirely, destroying the audit trail exactly when you want a preview of what would have happened.

```powershell
function Write-Banner { [CmdletBinding(SupportsShouldProcess)] param($Title)
    # ❌ Under -WhatIf: banner never reaches console or log
    Add-Content -Path $Script:LogFile -Value $bannerLine
}

function Write-Banner { [CmdletBinding(SupportsShouldProcess)] param($Title)
    # ✅ Infrastructure writes opt out of WhatIf explicitly
    Add-Content -Path $Script:LogFile -Value $bannerLine -WhatIf:$false
}
```

**Rule:** Every `New-Item`/`Add-Content`/`Out-File` inside logging and setup helpers passes `-WhatIf:$false`. WhatIf should suppress *work* (deletes, moves, installs), never the record of the run itself.

---

## Pitfall: $PSScriptRoot Is Empty When Dot-Sourced

`$PSScriptRoot` is populated only when a script is **invoked** (`& 'path\to\script.ps1'` or `.\script.ps1`). When **dot-sourced** (`. 'path\to\script.ps1'`), it is an empty string, so `Join-Path $PSScriptRoot "Reports"` crashes with:

```
Join-Path : Cannot bind argument to parameter 'Path' because it is an empty string.
```

This was hit in production on `Get-DeviceInfo.ps1:62` when an operator ran `. '...\Get-DeviceInfo.ps1'` from `C:\Users\Mabdu\Downloads\scripts`.

```powershell
# ❌ Crashes when dot-sourced
param([string]$OutputPath = (Join-Path $PSScriptRoot "Reports"))

# ✅ Dot-source safe — default beside the original script, with PSBoundParameters normalization
param(
    [string]$OutputPath = $( $scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }; Join-Path $scriptBase "Reports" )
)
$ErrorActionPreference = 'Stop'
if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
    $scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
    $OutputPath = Join-Path $scriptBase "Reports"
}
```

**Rules:**
1. Default `OutputPath`/`Reports` is **always beside the original script**, never `".\Reports"` or `Get-Location` alone.
2. If the script is dot-sourced and the caller did NOT explicitly pass `-OutputPath`, normalize to beside-script.
3. If the caller DID pass `-OutputPath`, respect it — do not overwrite.

**Verification:** Test all three invocations: `& 'path\script.ps1'`, `.\script.ps1`, and `. 'path\script.ps1'` from a different directory — all must create `Reports` beside the script, not in the caller's `pwd`.

---

## Pitfall: Initial Theme Not Applied — All-White Screen Until First Toggle

When a WPF tool defines Tailwind Slate brushes in `Window.Resources` but never calls `Set-Theme` on startup, all `DynamicResource` brushes remain frozen at their XAML defaults. The window appears as a single flat color, navigation buttons show no accent, and the UI only corrects after toggling Dark → Light.

This was hit in production on `DeviceInfoViewer.ps1` — initial launch was monochrome; after pressing Dark then Light, colors appeared correctly.

```powershell
# ❌ No initial theme — first paint is monochrome
$script:Window = ConvertTo-XamlWindow -Xaml $xaml
# ... bindings, handlers ...
[void]$script:Window.ShowDialog()

# ✅ Initialize immediately after load (Enterprise GUI Framework pattern)
$script:Window = ConvertTo-XamlWindow -Xaml $xaml
try {
    Set-Theme -Window $script:Window -IsDark $false
    $script:isDarkMode = $false
    if ($script:ThemeIcon) {
        $script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($SunIconData)
        $script:ThemeIcon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#EAB308')
    }
} catch { Add-LogLine "Initial theme setup failed: $($_.Exception.Message)" 'WARNING' }
```

**Rules:**
1. Always call `Set-Theme -IsDark $false` immediately after `ConvertTo-XamlWindow`, before any `FindName` or `ShowDialog`.
2. Set `$script:isDarkMode = $false` and initialize `ThemeIcon` to Sun at the same time.
3. The toggle handler then flips `$script:isDarkMode` and calls `Set-Theme` again — first paint and toggle both use the same code path.

**Verification:** Launch tool fresh (no toggle) — sidebar `SidebarBrush #E8EDF4`, header `SurfaceBrush #FFFFFF`, active nav `AccentTintBrush #EFF6FF`, KPI `AccentBrush #3B82F6` must all be distinct. Take a screenshot before any toggle.

## Pitfall: Standalone [HelpMessage()] Attribute Crashes PS 5.1

Declaring `[HelpMessage('...')]` as a standalone attribute above a parameter parses cleanly in pwsh 7 but throws `CustomAttributeTypeNotFound` at runtime on Windows PowerShell 5.1. HelpMessage is not an attribute type - it is a named argument of the Parameter attribute. A tool that passes pwsh checks can still fail its first real run on 5.1.

```powershell
# ? Crashes PS 5.1 at runtime
[Parameter(Mandatory = $false)]
[HelpMessage('Adapter names')]
[string[]]$AdapterName

# ? Correct - named argument inside Parameter()
[Parameter(Mandatory = $false, HelpMessage = 'Adapter names')]
[string[]]$AdapterName
```

**Rules:**
1. Always declare HelpMessage as a named argument of `[Parameter()]` - never as a standalone attribute.
2. Smoke-test every CLI tool under Windows PowerShell 5.1 (`powershell.exe -File tool.ps1 -WhatIf`); pwsh-only success is not proof. `scripts/Test-Delivery.ps1 -SmokeTest` automates this.
3. Keep alias-like English words OUT of HelpMessage strings - "Folder where JSON..." makes the no-aliases grep flag the file. Rephrase ("Folder for JSON...").

## Pitfall: Array-Preserve Comma Cannot Combine With Splatting Syntax

Writing `return ,@$variable` is a parse error ("The splatting operator '@' cannot be used to reference variables in an expression"). The array-preserve comma and the splatting operator are different uses of `@`; only splatting takes the `@var` form, and it is valid only as a command argument.

```powershell
# ? Parse error
return ,@$bindings

# ? Correct - comma operator preserves the array through the pipeline
return ,$bindings
```

**Rules:**
1. To return a single-element array intact, use `return ,$array` - never `,@$array`.
2. Run the parser check before delivering; this class of error never survives `[System.Management.Automation.Language.Parser]::ParseFile`.

## Pitfall: Indexer Assignment Into XamlReader Resources Corrupts Deferred DynamicResource

Swapping theme tokens with `$window.Resources[$key] = $brush` on a dictionary produced by `XamlReader.Load/Parse` crashes at runtime with `"'#FFxxxxxxxx' is not a valid value for property '...'"` - the property and hex differ run to run because deferred DynamicResource references (created pre-ShowDialog) resolve through a corrupted stale entry. The assigned value itself is a perfectly valid frozen SolidColorBrush; the indexer path is what breaks.

```powershell
# ? Crashes during Set-Theme / theme toggle
$Window.Resources[$key] = New-Brush -Hex $tokens[$key]

# ? Safe - re-register the entry
if ($Window.Resources.Contains($key)) { $null = $Window.Resources.Remove($key) }
$Window.Resources.Add($key, (New-Brush -Hex $tokens[$key]))
```

**Rules:**
1. In any runtime theme switch, use Remove+Add - never indexer assignment - on XamlReader-built resources.
2. BeginInit/EndInit does NOT help (verified); the failure fires at EndInit/indexing regardless.
3. Repro harness pattern: truncate the tool before ShowDialog, Invoke-Expression the head, call Set-Theme under `powershell.exe -STA` AND `pwsh -STA`.

## Pitfall: Bracket Paths Turn -Path Into Wildcards And Break Log Writes

A log path containing square brackets (`[ToolName]_20260823.log` from an uncustomized template placeholder, or any computer/username pattern) is treated as a wildcard set by `-Path`. When no file matches, the FileSystem provider hides its dynamic parameters and PowerShell reports the absurd `A parameter cannot be found that matches parameter name 'Encoding'` on the Add-Content line - pointing at Encoding while the real problem is the path.

Related trap: `New-Item` has **no** `-LiteralPath` parameter at all; switching cmdlets blindly breaks creation lines. Use .NET filesystem methods instead - they are wildcard-free by design.

```powershell
# ? Misleading 'Encoding not found' when path contains []
Add-Content -Path $script:LogFile -Value $line -Encoding UTF8
New-Item -LiteralPath $script:LogFile -ItemType File   # ? no such parameter

# ? LiteralPath for IO cmdlets + .NET for creation
Test-Path -LiteralPath $script:LogFile
Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
$null = [System.IO.Directory]::CreateDirectory($script:LogRoot)
$null = [System.IO.File]::Create($script:LogFile).Dispose()
```

**Rules:**
1. Every Test-Path / Add-Content / Get-Content against a constructed log or report path uses -LiteralPath.
2. Never create files/dirs with New-Item -LiteralPath (does not exist); use [System.IO.Directory]::CreateDirectory and [System.IO.File]::Create($p).Dispose().
3. Templates throw a clear "replace [ToolName]" error before any logging runs when placeholders remain.

## Pitfall: Event Handlers Cannot See Builder Function Locals

A scriptblock passed to `Add_Click`/`Add_Tick` runs later under WPF dispatch, rebound to session scope - any reference to the defining function's locals resolves to NULL at invocation time. The tool opens fine, then crashes on the FIRST button press with `You cannot call a method on a null-valued expression` bubbling out of the main window's ShowDialog.

```powershell
# ? Crashes when clicked - $win is out of scope by then
function New-ChildWindow {
    $win = ConvertTo-XamlWindow -Xaml $x
    $win.FindName('okBtn').Add_Click({ $win.Close() })
}

# ? Publish script-scoped refs, then bind handlers to them
$script:ChildWindow = $win
$win.FindName('okBtn').Add_Click({ $script:ChildWindow.Close() })
```

**Rules:**
1. Inside any Add_Click/Add_Tick/Add_Closed scriptblock, touch ONLY `$script:` variables, `$this`, or `$_`.
2. For one-shot timers use `$this.Stop()` instead of referencing the timer variable.
3. Test every button by raising real Click events under a pumped dispatcher (`RaiseEvent(new RoutedEventArgs([Button]::ClickEvent))`) - building the window alone proves nothing about handler bindings.

## Pitfall: RichTextBox Log Appends Without LineBreak Appear As One Line

RichTextBox Paragraph.Inlines with consecutive Runs and no LineBreak renders as a single continuous line: [DEBUG] ...[INFO] ...[SUCCESS] ... . Using "
" inside a Run is ignored by WPF.

```powershell
# -- Wrong: concatenated line
$null=$para.Inlines.Add($head); $null=$para.Inlines.Add($body)

# -- Correct: explicit LineBreak after each entry
$null=$para.Inlines.Add($head); $null=$para.Inlines.Add($body); $null=$para.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
```

**Rule:** Every RichTextBox log append must end with an explicit LineBreak element.

## Pitfall: Default DataGrid Visuals Are Flat

Default DataGrid has plain header, no alternating rows and no hover feedback, so tables look unfinished.

**Fix:** Add implicit enterprise theme in Window.Resources (TableBg/TableAltBg/TableHeaderBg, Header 36px SemiBold, RowHeight 34, AlternationCount 2, hover AccentTintBrush, cell Padding 12,0) and wrap each DataGrid in Border CornerRadius 8 with count badge in card header.

## Pitfall: Flat HTML Executive Report

Minimal HTML (flat header, plain grid) looks weak compared to WPF polish.

**Fix:** Use premium hero (gradient banner + KPI row with SVG icons + toolbar with search + resultCount + Print button + card-head gradient + table-wrap rounded + Volumes progress bars bar-ok/warn/err + footer-inner). Pattern U premium template is canonical.

## Pitfall: String Interpolation With Percent After Subexpression Crashes PS 5.1

"$($_.FreePercent)%" inside an expandable string is parsed as modulo operator in PS 5.1 and crashes with "The string is missing the terminator" or "A positional parameter cannot be found".

```powershell
# -- Wrong in PS 5.1
"$($_.FreeSpace) free of $($_.Size) ($($_.FreePercent)%)"

# -- Correct: use Format operator
('{0} free of {1} ({2}%)' -f $_.FreeSpace, $_.Size, $_.FreePercent)
```

**Rule:** Never put "%" directly after ")" inside an expandable string in PS 5.1 - use -f formatting.

## Pitfall: About Dialog Must Be Concise And ASCII-Only

About that mirrors the full README with 12 sections is too verbose, and live system data (ComputerName, OS Caption) inside XAML Text attributes introduces non-ASCII or dynamic values that break 5.1 parsing or compliance (literal "Add_Closing" inside XAML is counted as second handler).

**Fix:** About is concise program definition only: hero + Overview paragraph + 3 Highlights + Requirements/Author grid + Disclaimer, height 520, ASCII-only, avoid literal "Add_Closing" inside XAML strings (use "window-closing").

## Pitfall: Invisible U+FEFF Ghosts Survive Clean Parses After Programmatic Splices

A leading UTF-8 BOM decoded through tools that treat it as content (e.g., Python `read_text(encoding='utf-8')`) leaves an invisible `U+FEFF` glued to the inserted text. PowerShell then parses `<U+FEFF>function Name {...}` as a COMMAND INVOCATION named `?function` - the Parser reports **0 errors** and the script crashes at runtime with `The term '?function' is not recognized`. A doubled BOM (`EF BB BF EF BB BF`, from repeated editor re-saves) is equally toxic: `#` / `<#` are no longer recognized and the entire help block parses as code.

```powershell
# ✅ After ANY programmatic splice/re-save: normalize to exactly one BOM
$bytes = [System.IO.File]::ReadAllBytes($path)
$body = $bytes; while ($bytes[0] -eq 0xEF) { $body = $bytes[3..($bytes.Length-1)]; break }  # strip, then:
$utf8Bom = [byte[]](0xEF,0xBB,0xBF) + $body
[System.IO.File]::WriteAllBytes($path, $utf8Bom)

# ✅ Ghost-command scan: must return 0
$ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
$ghosts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and
    $args[0].GetCommandName() -match '^\?' }, $true)
```

**Rules:**
1. Parse 0 errors does NOT catch invisible `U+FEFF` ghosts - run the AST ghost-command scan after splicing code programmatically.
2. Validate single BOM: `bytes[0..2] == EF BB BF` AND `bytes[3] -ne 0xEF`. Never prepend BOMs manually.

## Pitfall: PowerShell -replace Is Case-Insensitive

`-replace` ignores case by default. A PascalCase splitter like `-replace '(?<=[a-z])([A-Z])', ' $1'` matched EVERY letter pair and produced `G e t O U U s e r s` in generated `.TITLE` fields.

```powershell
# ❌ Case-insensitive: matches every pair
$name -replace '(?<=[a-z])([A-Z])', ' $1'

# ✅ Case-sensitive replacement operator
$name -creplace '(?<=[a-z])([A-Z])', ' $1'
```

**Rule:** Use `-creplace` for any casing-sensitive regex transformation; reserve `-replace` for case-proof patterns.

## Pitfall: Load XAML With Parse First — Load Is A Fallback Only

`XamlReader.Parse` and the XmlNodeReader+`XamlReader.Load` path build DIFFERENT resource dictionaries: the Load-produced dictionary corrupts deferred DynamicResource references when updated (the true root cause behind the Set-Theme indexer crash). Canonical loaders therefore try `XamlReader.Parse` FIRST and keep XmlNodeReader+Load as a compatibility fallback - a template that inverted this order shipped the buggy dictionary as its primary path.

```powershell
# ✅ Canonical order
try   { $Window = [Windows.Markup.XamlReader]::Parse($xaml) }
catch { # fallback only
    $xml = [xml]$xaml; $reader = New-Object System.Xml.XmlNodeReader($xml)
    $Window = [Windows.Markup.XamlReader]::Load($reader)
}
```

**Rules:**
1. Always load XAML with `XamlReader.Parse` first; XmlNodeReader+Load is a compatibility fallback.
2. When two implementations of the same pattern disagree, diff the LOADER before blaming the consumer.

## Pitfall: Capture A Hash Baseline At Delivery — Treat Mismatch As External Drift First

Delivered scripts were silently modified after handoff twice: a parameter default flipped (`'None'` → `'html'`) and executed by an unknown process, and a template file vanished mid-session with no local operation touching it. Without an integrity baseline, drift is only discoverable through behavioral anomalies during verification.

```powershell
# ✅ Immediately after delivery
Get-FileHash .\*.ps1 -Algorithm SHA256 | Export-Csv .\baseline.csv -NoTypeInformation -Encoding UTF8

# ✅ During verification: documented contract vs observed behavior
Select-String -Path .\Get-DeviceInventory.ps1 -Pattern '\$ExportFormat\s*=\s*' 
```

**Rules:**
1. Capture a `Get-FileHash` baseline CSV at delivery time; re-check it before every follow-up session.
2. During verification, diff observed defaults against the documented `.PARAMETER` contract - treat any mismatch as external drift first, code bug second.
3. Run `Test-Skill.ps1` after ANY bulk file work - inventory drift gets caught immediately.

## Pitfall: Mandatory `[string]` Parameter Crashes When Called With Empty Spacer

`Find-IntunePolicyConflict.ps1` (and every CLI script that copies the canonical `Write-Log` verbatim) crashed at the first device-lookup line with `Cannot bind argument to parameter 'Message' because it is an empty string` after a successful Graph sign-in. Every `Write-Log -Message ""` visual separator — used freely to break sections vertically — crashes before the timestamp/color logic runs because PowerShell's Mandatory binding treats an empty string as a missing value. The same script-local `Write-Log` and the canonical `scripts/Write-Log.ps1` both share the `[Parameter(Mandatory = $true)] [string]$Message` declaration, so this is a latent crash in the canonical helper itself, not just one downstream consumer.

```powershell
# ? Breaks at first spacer line
[Parameter(Mandatory = $true)]
[string]$Message,
...
Write-Log -Message "Signed in as: $($context.Account)" -Level 'SUCCESS'   # ok
Write-Log -Message "" -Level 'INFO'                                       # CRASH

# ? Allow empty + early-return so spacers no-op
[Parameter(Mandatory = $false)]
[AllowEmptyString()]
[string]$Message = "",
...
if ([string]::IsNullOrEmpty($Message)) { return }
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logLine = "[$timestamp] [$Level] $Message"
```

**Rules:**
1. Any logging helper that is called with `""` as a visual separator MUST declare `Message` as non-Mandatory with `[AllowEmptyString()]` and default `""`, then early-return on empty — mandatory + empty is a binding error, not a no-op.
2. The canonical `scripts/Write-Log.ps1` (and any `Write-Log` it copies) must apply the same fix in the next release; until then, every CLI script that uses `Write-Log -Message ""` as a spacer needs the same declaration.
3. When auditing a script for this crash, grep `Write-Log -Message ""` and `Add-LogLine -Message ""` — every hit is a guaranteed crash before the next non-empty line.

## Pitfall: `New-Object TypeName(...)` Arithmetic Arguments Require Parentheses

In PowerShell 5.1, arithmetic expressions passed inside constructor argument lists without parentheses (such as `New-Object System.Drawing.Point($x - $w, $y)`) are parsed as multiple positional parameters or parameter binding errors.

```powershell
# ❌ Crashes in PS 5.1 (treated as separate arguments)
$pt = New-Object System.Drawing.Point($x - $offset, $y)

# ✅ Parenthesize arithmetic expressions explicitly
$pt = New-Object System.Drawing.Point(($x - $offset), $y)
```

**Rules:**
1. Always wrap arithmetic operations in parentheses `($a - $b)` when passing them into constructor arguments of `New-Object`.

## Pitfall: `Add-Type -Path` Fails with ReflectionTypeLoadException on DLL Dependencies

When loading third-party or multi-assembly packages (e.g. MSAL / Graph authentication assemblies) via `Add-Type -Path`, missing transient dependencies cause unhandled `ReflectionTypeLoadException`.

```powershell
# ❌ Fragile on dependent assemblies
Add-Type -Path $msalDllPath

# ✅ Robust assembly loading with AssemblyResolve handler
[System.AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($sender, $args)
    $name = ($args.Name -split ',')[0] + '.dll'
    $target = Join-Path $dllDir $name
    if (Test-Path $target) { [System.Reflection.Assembly]::LoadFrom($target) }
})
[System.Reflection.Assembly]::LoadFrom($msalDllPath)
```

**Rules:**
1. For multi-assembly DLL libraries, register an `AssemblyResolve` handler before calling `[System.Reflection.Assembly]::LoadFrom`.

## Pitfall: `Set-StrictMode` Crashes on Uninitialized `$script:` Scope Variables

When `Set-StrictMode -Version Latest` (or 2.0+) is enabled, referencing an uninitialized variable in `$script:` or `$global:` scope throws `PropertyNotFoundException`.

```powershell
# ❌ Throws under StrictMode if not yet assigned
if (-not $script:lastLogKey) { ... }

# ✅ Initialize script-level variables explicitly at script entry
$script:lastLogKey = $null
```

**Rules:**
1. Always explicitly initialize script-scope variables (`$script:var = $null`) at the top of the file when writing enterprise tools.

## Pitfall: `-replace` With `$_` in Replacement String Evaluates as .NET Regex Whole Match

In PowerShell `-replace` operations, `$_` inside the replacement string is interpreted by .NET regex engine as the special substitution token `$&` (the entire matched text), not the PowerShell pipeline variable.

```powershell
# ❌ Injected matched text instead of current pipeline object
$items | ForEach-Object { $template -replace '\{\{NAME\}\}', $_ }

# ✅ Escape $_ or use [regex]::Replace with a MatchEvaluator delegate
$items | ForEach-Object { $template -replace '\{\{NAME\}\}', [regex]::Escape($_) }
# Or string replace:
$items | ForEach-Object { $template.Replace('{{NAME}}', "$_") }
```

**Rules:**
1. For exact string token substitution, use `.Replace('find', 'replace')` instead of regex `-replace`, or escape the replacement string with `$$`.

## Pitfall: `Write-Host` Output Capture Requires `*>&1` Not `2>&1`

`Write-Host` in PowerShell writes to the Information stream (Stream 6). Piping with `2>&1` redirects only Error stream (Stream 2) to Success stream (Stream 1), completely missing all `Write-Host` output.

```powershell
# ❌ Misses all Write-Host messages
$out = & $childScript 2>&1

# ✅ Captures all streams (including information stream 6)
$out = & $childScript *>&1
```

**Rules:**
1. Always use `*>&1` when capturing output from child PowerShell scripts that use `Write-Host`.

## Pitfall: `[string]$OutputPath = "."` Default Bypasses Script-Directory Anchoring (Law 12)

Declaring `[string]$OutputPath = "."` in parameter blocks causes `$PSBoundParameters.ContainsKey('OutputPath')` or `if ($OutputPath)` to evaluate to true with the caller's working directory (`.`), completely bypassing the `$PSScriptRoot` fallback guard.

```powershell
# ❌ Bypasses beside-script resolution
param(
    [string]$OutputPath = "."
)

# ✅ Default to empty string and resolve in guard block
param(
    [string]$OutputPath = ""
)
$scriptDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
if (-not $OutputPath) { $OutputPath = Join-Path $scriptDirectory 'Reports' }
```

**Rules:**
1. Default path parameters MUST be empty string `""`, never `"."` or `"Reports"`.

## Pitfall: `$LASTEXITCODE` Consumed When Piping Child Script to `Out-String`

Invoking a child script through a pipeline such as `& $script | Out-String` sets `$LASTEXITCODE` to the exit code of `Out-String` (which is always 0), swallowing the child script's explicit `exit <non-zero>` status.

```powershell
# ❌ Swallows child exit code
$out = & $script 2>&1 | Out-String
$code = $LASTEXITCODE   # Always 0!

# ✅ Invoke directly and capture exit code
$null = & $script *>&1
$code = $LASTEXITCODE
```

**Rules:**
1. Never pipe a child script directly to `Out-String` when inspecting `$LASTEXITCODE`.

## Pitfall: `ForEach-Object -Parallel` ScriptBlock Must Precede `-ThrottleLimit`

In PowerShell 7+, placing `-ThrottleLimit` before the `-Parallel` ScriptBlock can cause parsing and parameter binding failures.

```powershell
# ❌ Fragile argument order
$items | ForEach-Object -ThrottleLimit 10 -Parallel { ... }

# ✅ Canonical argument order: ScriptBlock first
$items | ForEach-Object -Parallel { ... } -ThrottleLimit 10
```

**Rules:**
1. Always place the `-Parallel { ... }` block immediately after `ForEach-Object`, followed by `-ThrottleLimit <N>`.

---

## Pitfall: HTML Report — Grade on KPI, Body, Row, and Chart Provenance — Not "Has a Table"

Auditing HTML reports by grepping for `<table>` marks every script as PASS — even a 2-row stub with fake data. The user asked for "real, detailed, script-specific data" and a structural check silently misses the fidelity gap. Test-ToolCompliance does not gate HTML body content.

```powershell
# ❌ Structural check — every HTML file passes
if ($html -match '<table>') { Write-Host "PASS" }

# ✅ Fidelity rubric (4 metrics, each +1):
# 1. KPI tiles bound to real collected data (not hardcoded 0)
# 2. Body built from $rows | ForEach-Object dynamically
# 3. >=5 rows of script-specific detail (cols vary by domain)
# 4. Charts derived from same $rows data
# PASS = 3-4, WEAK = 1-2, FAIL = 0
```

**Rules:**
1. When auditing HTML reports for data fidelity, score KPI provenance, body provenance, row count, and chart provenance — never grade on "has a table" alone.
2. Encode the rubric into a future `Test-HtmlFidelity.ps1` gate.

---

## Pitfall: HTML Body Must Not Depend on $rows From a Different try Block (Try-Scope Leak)

`ExampleTlsAudit.ps1` had console `try { $rows = foreach(...) } catch{}` then HTML `try { $rows.Count }`. The console block used a chained `if` inside `[PSCustomObject]@{}` that PS 5.1 failed to tokenize; it fell into `catch`, `$rows` was never assigned, and HTML rendered "0 combinations" from `$null`.

```powershell
# ❌ HTML trusts cross-try survival
try { $rows = foreach ($p in $paths) { [PSCustomObject]@{ Enabled = (if ($x) { 'Yes' } else { 'No' }) } } } catch {}
try { $html = $rows | ForEach-Object { "<tr><td>$($_.Enabled)</td></tr>" } } catch {}

# ✅ Defensive re-collection inside HTML consumer
try {
    if (-not $rows) { $rows = foreach ($p in $paths) { $enabledLabel = if ($x) { 'Yes' } else { 'No' }; [PSCustomObject]@{ Enabled = $enabledLabel } } }
    $html = $rows | ForEach-Object { $rowRef = $_; "<tr><td>$([System.Net.WebUtility]::HtmlEncode($rowRef.Enabled))</td></tr>" }
} catch { Write-Verbose "HTML failed: $_" }
```

**Rules:**
1. When HTML export consumes `$rows` populated by a prior `try`, re-collect if empty inside the consumer (`if (-not $rows) { $rows = <fresh-query> }`).
2. Never trust cross-try variable survival.

---

## Pitfall: $_ Shadowing Inside Nested ForEach-Object Breaks Property Access

Inside `$rows | ForEach-Object { $_.PSObject.Properties | Where-Object{} | ForEach-Object { if($_.Name -eq 'Enabled'){ $_.Enabled_Raw } } }`, every cell rendered `class="badge neutral"` because `$_.Enabled_Raw` was `$null`.

PowerShell rebinds `$_` at every pipe boundary. The inner `ForEach-Object` over `PSObject.Properties` rebinds `$_` to `PSPropertyInfo`, breaking the outer-row reference. The expression `$_.Enabled_Raw` then reads a property that does not exist on `PSPropertyInfo`.

```powershell
# ❌ Inner pipe shadows outer $_
$rows | ForEach-Object {
    $_.PSObject.Properties | Where-Object { $_.Name -eq 'Enabled' } | ForEach-Object {
        if ($_.Name -eq 'Enabled') { $_.Enabled_Raw } # ← $_ is now PSPropertyInfo, not the row
    }
}

# ✅ Capture outer row before any nested pipeline
$rows | ForEach-Object {
    $rowRef = $_
    $rowRef.PSObject.Properties | Where-Object { $_.Name -eq 'Enabled' } | ForEach-Object {
        if ($_.Name -eq 'Enabled') { $rowRef.Enabled_Raw } # ← explicit outer ref
    }
    "<tr><td>$([System.Net.WebUtility]::HtmlEncode($rowRef.Name))</td></tr>"
}
```

**Rules:**
1. Inside any `ForEach-Object` body containing a nested `ForEach-Object`/`Where-Object`/`Sort-Object`, capture outer `$_` to a named variable (`$rowRef`) at the top, then reference `$rowRef.Property` inside inner blocks.

---

## Pitfall: Read param() Before Invoking — Parameter Errors Are Caller Errors

Re-testing `ExampleFileScan.ps1` with `-LimitMB 10` (remembered from a similar tool) threw "A positional parameter cannot be found that accepts argument 10" and was misdiagnosed as a parser regression. The actual param is `[string[]]$TargetName`.

```powershell
# ❌ Passing from memory of a similar script
.\ExampleFileScan.ps1 -LimitMB 10  # no such param

# ✅ Read the contract first
Get-Help .\ExampleFileScan.ps1 -Full
# or: (Get-Content $path -Raw) -match '(?ms)param\((.*?)\)'
.\ExampleFileScan.ps1 -TargetName "$env:USERPROFILE\Downloads"  # correct
```

**Rules:**
1. Before invoking any script, read its `param()` block or `Get-Help` output.
2. Never pass parameters from memory of similar scripts — parameter errors are caller errors.

---

## Pitfall: Recursive Get-ChildItem on Drive Root or Large Trees Times Out

Testing `ExampleFileScan.ps1` with `-TargetName "$env:SystemDrive\"` and `"$env:TEMP"` (WinGet cache with 50k files) both timed out at 120s. `Get-ChildItem -Recurse` enumerates every file; TEMP and drive root are huge. Smoke-test instructions that default to drive root will hang CI.

```powershell
# ❌ Huge tree — times out
.\ExampleFileScan.ps1 -TargetName "$env:SystemDrive\"

# ✅ Small, representative path
.\ExampleFileScan.ps1 -TargetName "$env:USERPROFILE\Downloads"
```

**Rules:**
1. Smoke-test recursive filesystem scripts against a small representative path (e.g., `Downloads`).
2. Never test `-Recurse` against a drive root in CI.
3. For production, add `-Depth` or document a sensible default path.

---

## Pitfall: KPI Tiles Must Be Domain-Specific — Generic OK/Failed Counters Are Drift

WEAK scripts had KPIs like `@{value=$ok; label='Targets OK'}` — generic counters identical across 20 scripts, saying nothing about TLS/LAPS/SecureBoot at a glance.

```powershell
# ❌ Generic — could appear in any script
@{ value = $ok; label = 'Targets OK' }

# ✅ Domain-specific (ExampleTlsAudit)
@{ value = $weakCount; label = 'Weak Protocols Enabled' }
@{ value = $modernCount; label = 'Modern Protocols' }
```

**Rules:**
1. Every HTML report KPI must be domain-specific. If a label could appear identically in 5 unrelated scripts, it is too generic.
2. `OK/Failed` counters only fit pass/fail scripts (e.g., `ExampleComplianceCheck`, STIG).

---

## Pitfall: HTML Uses Carbon Dark; WPF Uses Tailwind Slate — Never Mix

Carbon Dark: `#0f62fe`, IBM Plex Sans/Mono, `#161616` background. Slate: `#3B82F6`, Segoe UI Variable, `#F1F5F9`. Helper name `Export-ProfessionalHtmlReport` has no "Carbon" in it; inline CSS hex codes carry no token names — easy to conflate.

```powershell
# ❌ Slate token in HTML
--background: #F1F5F9; font-family: 'Segoe UI Variable'

# ✅ Carbon token in HTML (canonical: templates/EnterpriseHtmlReport.template.ps1)
--cds-background: #161616; font-family: 'IBM Plex Sans', 'IBM Plex Mono'
```

**Rules:**
1. HTML output always uses Carbon Dark (`templates/EnterpriseHtmlReport.template.ps1`).
2. WPF always uses Tailwind Slate (`references/xaml-styles.md`).
3. Never mix — inline Carbon CSS (hex) and Slate XAML (DynamicResource) are not interchangeable.

---

## Pitfall: Full Triage Pass Before Any Fix — Output Sorted FAIL→WEAK→PASS Table

Starting fixes immediately without a full classification leaves the operator with no landscape view. Fixes interleaved ad-hoc with audits make re-prioritization impossible.

```powershell
# ✅ Triage first, fix second
# 1. Audit all 32 scripts → table:
# | # | Script | Verdict | Issue |
# |---|--------|---------|-------|
# | 1 | ExampleTlsAudit | WEAK | Generic KPIs, HtmlEncode gaps |
# 2 | ExampleLapsAudit         | PASS | ✅ |
# 2. Then fix in order: FAIL → WEAK → PASS
```

**Rules:**
1. When auditing a library, do a full classification pass before any fix and output a sorted `| # | Path | Verdict | Issue |` table (`FAIL` → `WEAK` → `PASS`).

---

## Pitfall: Bulk Audit (N > 3 files) → Task Agent; Single-File (N ≤ 3) → Inline read+edit

Reading 32 scripts one-by-one with `read` tool (16+ calls, 450-550 lines each) then manually cross-referencing is slow and error-prone. One-file depth is wasted on bulk classification.

```powershell
# N > 3 → task agent with precise output spec (one row per script, sorted by severity)
# N ≤ 3 → inline read+edit directly
```

**Rules:**
1. `N > 3` → delegate bulk-read-and-classify to a task agent with a precise output spec.
2. `N ≤ 3` → use `read` + `edit` directly.

---

## Pitfall: HtmlEncode Every Dynamic Cell — No Exceptions; Wrap Paths in code

`~80%` of cells used `[System.Net.WebUtility]::HtmlEncode($value)` but `~20%` interpolated directly (`<td>$value</td>`). Unsafe for `&`, `<`, `>`, `"`, `'` in computer names, cert subjects, registry paths, SIDs.

```powershell
# ❌ Raw interpolation
"<td>$($row.Path)</td>"

# ✅ Always encode; wrap paths/identifiers in <code>
"<td><code>$([System.Net.WebUtility]::HtmlEncode($row.Path))</code></td>"
"<td>$([System.Net.WebUtility]::HtmlEncode($row.Name))</td>"
```

**Rules:**
1. Every dynamic value rendered into HTML must go through `[System.Net.WebUtility]::HtmlEncode` — no exceptions.
2. Wrap paths/identifiers/SIDs/GUIDs in `<code>` after encoding.

---

## Pitfall: Pre-Existing Bugs Out of Scope Unless HTML Depends on Them

Noticed `ExampleComplianceCheck` and `ExampleTlsAudit` had pre-existing console warnings "The term if is not recognized" from chained `if` inside `[PSCustomObject]@{}` inside `foreach` inside `try`. Fixing the console block as well would expand scope and risk regression.

```powershell
# HTML fidelity audit → fix only HTML block
# Pre-existing console bug → log as separate follow-up
# Exception: if HTML depends on the buggy variable, add defensive re-collection
try { $rows = foreach ($p in $paths) { [PSCustomObject]@{ V = (if ($x) {1} else {0}) } } } catch {}
# HTML:
try { if (-not $rows) { $rows = foreach ($p in $paths) { $v = if ($x){1}else{0}; [PSCustomObject]@{ V=$v } } } } catch {}
```

**Rules:**
1. When auditing for one concern (HTML fidelity), fix only that concern.
2. Log additional bugs as separate follow-ups.
3. If the fix depends on the buggy variable, add defensive re-collection instead.

---

## Pitfall: Three-Gate HTML Verification — Parser → Run → Row/Cell/Badge Count

`[Parser]::ParseFile` = 0 errors is necessary but not sufficient. Parse success does not prove HTML renders correctly or contains real data.

```powershell
# Gate 1: Parser
$errs = $null; [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errs); $errs.Count -eq 0

# Gate 2: Run and produce file
& $script -TargetName $smallPath; Test-Path $htmlPath

# Gate 3: Metrics
$html = Get-Content $htmlPath -Raw
([regex]::Matches($html,'<tr>')).Count   # rows
([regex]::Matches($html,'<td>')).Count   # cells
([regex]::Matches($html,'class="badge"')).Count  # badges
# Compare before/after: e.g., 2 cols/15 rows → 5 cols/42 rows/161 cells
```

**Rules:**
1. After fixing HTML fidelity, verify with three gates: (1) Parser 0 errors, (2) script runs and produces HTML, (3) row/cell/badge counts match expected before vs after.

