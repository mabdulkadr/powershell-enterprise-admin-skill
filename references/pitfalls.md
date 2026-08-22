# Known Pitfalls — PS 5.1 WPF

Every crash listed here was debugged in production. The fix is included. Read this file before you start writing WPF — these are the 20+ ways to crash the tool at ShowDialog or runtime.

---

## Table of Contents

1. [PS 5.1 Specific Crashes](#ps-51-specific-crashes)
2. [XAML Silent Failures](#xaml-silent-failures)
3. [Theme Issues](#theme-issues)
4. [Job / Thread Issues](#job--thread-issues)
5. [CLI Script Traps](#cli-script-traps)
6. [Build Verification](#build-verification)
7. [Pitfall: Measure-Object .Sum Returns $null on Empty Sets](#pitfall-measure-object-sum-returns-null-on-empty-sets)
8. [Pitfall: External Cleanup Processes Can Hang Forever](#pitfall-external-cleanup-processes-can-hang-forever)
9. [Trade-off: The Canonical Rich Header Disables Get-Help](#trade-off-the-canonical-rich-header-disables-get-help)
10. [Pitfall: Test-Path Throws on ACL-Protected Paths](#pitfall-test-path-throws-on-acl-protected-paths)
11. [Pitfall: PS 5.1 Reads BOM-less UTF-8 as ANSI](#pitfall-ps-51-reads-bom-less-utf-8-as-ansi)
12. [Pitfall: WhatIf Propagates Into Logging Helpers](#pitfall-whatif-propagates-into-logging-helpers)
13. [Pitfall: $PSScriptRoot Is Empty When Dot-Sourced](#pitfall-psscriptroot-is-empty-when-dot-sourced)
14. [Pitfall: Initial Theme Not Applied — All-White Screen Until First Toggle](#pitfall-initial-theme-not-applied--all-white-screen-until-first-toggle)

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

# ✅ Initialize immediately after load (PSWrap pattern)
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
