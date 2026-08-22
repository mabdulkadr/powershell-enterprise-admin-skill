# File Architecture — Right-Sized for Every Tool

Pick the smallest structure that fits. Most admin tools are **single-file** — the modular layout is for the framework itself, not for the tools it produces.

---

## Table of Contents

1. [Three Tiers, Choose by Size](#three-tiers-choose-by-size)
2. [Tier 1: Single-File (Default)](#tier-1-single-file-default)
3. [Tier 2: Split XAML](#tier-2-split-xaml)
4. [Tier 3: Modular (Rare)](#tier-3-modular-rare)
5. [Decision Guide](#decision-guide)

---

## Three Tiers, Choose by Size

| Tier | When | Files | Lines per File |
|------|------|-------|----------------|
| **1. Single-file** | Default — most admin tools | 4-5 files | Everything in 1 `.ps1` |
| **2. Split XAML** | Long XAML or repeated dialogs | 6-7 files | XAML in `.xaml`, code in `.ps1` |
| **3. Modular** | Frameworks that compile other tools | 15-20 files | Each function in its own file |

**The 80% rule:** Use Tier 1 for 80% of tools. Promote to Tier 2 only when Tier 1 hurts. Never reach Tier 3 unless you are building a framework.

---

## Tier 1: Single-File (Default)

**For:** Most admin tools — Intune helpers, AD scripts with GUI, remote command runners, inventory collectors.

```
📂 ProjectRoot
 ├── 🖥 [ToolName].ps1            # everything inside (400-3000 lines)
 ├── 📄 README.md                  # install, usage, screenshot
 ├── 📄 CHANGELOG.md               # version history (optional)
 ├── 🖼 icon.png                   # app icon (optional)
 └── 🖼 Screenshot.png             # for README (optional)
```

**What goes in the single `.ps1`:** Everything — XAML inline as here-string, all functions, all event handlers, logging, STA check, ShowDialog.

**Why this works:** Modern PowerShell ISE / VSCode handles 3000-line files without slowdown. Search is instant. No cross-file dependencies. One file to copy, one file to deploy, one file to troubleshoot.

**When to promote to Tier 2:** When the XAML here-string alone exceeds 500 lines (signals your UI is too complex for single-file editing), or when you need the same dialog in multiple tools.

---

## Tier 2: Split XAML

**For:** Tools with rich UI (multiple pages, repeated dialogs, complex DataGrids) — but still one business domain.

```
📂 ProjectRoot
 ├── 📄 [ToolName].ps1            # all PowerShell code
 ├── 📄 MainWindow.xaml           # primary UI layout (separate file)
 ├── 📄 LogViewer.xaml            # optional — only if you need a custom log viewer
 ├── 📄 README.md
 ├── 📄 CHANGELOG.md
 └── 🖼 icon.png
```

**What moves out:** The XAML here-string becomes `MainWindow.xaml`, loaded via `[xml](Get-Content 'MainWindow.xaml' -Raw -Encoding UTF8)` + `XamlReader.Load()`.

**What stays in the `.ps1`:** All PowerShell code — functions, event handlers, logging, STA check.

**Why this works:** XAML editors (VSCode with XML extension) give you better tag matching, validation, and preview than editing a here-string. PowerShell still gets one file to read end-to-end.

---

## Tier 3: Modular (Hybrid — PSWrap Reference)

**For:** Complex GUI tools with 5+ features, persistent settings, or companion-file workflows — **not only frameworks**. This is the PSWrap canonical pattern.

**PSWrap is the reference GUI implementation:** https://github.com/mabdulkadr/PSWrap — every new complex GUI tool must mirror its structure, embedded XAML, console-hide, and settings persistence. Use **Hybrid rule**: Tier 1 for simple single-workflow tools, Tier 3 (PSWrap-style) for complex tools.

```
📂 ProjectRoot                          # PSWrap example
 ├── 📄 PSWrap.ps1 / Start-[ToolName].ps1  # bootstrapper: console-hide + dot-source in order
 ├── 📂 config/
 │    ├── 📄 AppConstants.ps1          # ToolName, AppVersion, RootDir, LogDir, XamlDir, FeaturesDir
 │    └── 📄 settings.json             # placeholder (runtime creates %APPDATA%\ToolName\settings.json)
 ├── 📂 src/
 │    ├── 📄 Environment.ps1           # STA check + Add-Type WPF assemblies
 │    ├── 📄 Logging.ps1               # Add-LogLine (duplicate guard + file)
 │    ├── 📄 WpfHelpers.ps1            # New-Brush, Set-Theme, Show-ToastMessage (fade), Guard-Action
 │    ├── 📄 Settings.ps1              # Get-AppSettings / Set-AppSettings (JSON in %APPDATA%)
 │    ├── 📄 UiLoader.ps1              # Get-EmbeddedXaml (GZip+Base64) + fallback to xaml/*.xaml + FindName bindings
 │    ├── 📄 EventHandlers.ps1         # all Add_Click with Guard-Action
 │    ├── 📄 Startup.ps1               # Restore settings + Start-BackgroundDataLoad + ShowDialog
 │    └── 📂 Features/
 │         ├── 📄 Compiler.ps1         # per-feature logic
 │         ├── 📄 LogViewer.ps1        # theme copy (Pattern E)
 │         ├── 📄 AboutInfo.ps1        # markdown → WPF
 │         └── 📄 [Name].ps1
 ├── 📂 xaml/
 │    ├── 📄 MainWindow.xaml           # source; build embeds it via scripts/Embed-Xaml.ps1
 │    └── 📄 LogViewer.xaml
 └── 📂 docs/, 📂 scripts/, 📂 tests/, 📂 logs/
```

**Embedded XAML:** Build step `scripts/Embed-Xaml.ps1` GZip+Base64-encodes `xaml/MainWindow.xaml` into `$script:EmbeddedXaml` in `src/UiLoader.ps1`. At runtime `Get-EmbeddedXaml` decompresses; if missing, falls back to `xaml/*.xaml`. This guarantees the tool never loses its UI and supports single-file distribution.

**Console hide:** `PSWrap.ps1` uses P/Invoke `GetConsoleWindow` + `ShowWindow(0)` to hide the PowerShell console flash before WPF shows — copy this verbatim for every GUI tool.

**When to reach Tier 3 (Hybrid):**

- You are building a **framework** that produces other tools
- **OR** GUI has **5+ distinct features** with settings persistence, drag-drop, or companion-file bundling (PSWrap case) — use Tier 3 even for single audience
- You need **per-feature unit tests** in isolation

**Don't reach Tier 3 for:** A single-workflow helpdesk tool with 2-3 buttons and no persistent settings — Tier 1 is still correct.

---

## Decision Guide (Hybrid — PSWrap Rule)

Ask these four questions:

```
Is this a GUI tool with 5+ features, persistent settings, or drag-drop/bundling?
├── YES → Tier 3 (PSWrap modular + embedded XAML)  # complexity wins over audience count
│
└── NO → Is this a single admin tool (one workflow, one audience)?
    ├── YES → Tier 1 (single file)
    │
    └── NO → Is this a framework that produces other tools?
        ├── YES → Tier 3 (modular)
        │
        └── NO → Is the XAML > 500 lines OR do you reuse dialogs across tools?
            ├── YES → Tier 2 (split XAML)
        └── NO → Tier 1 (single file)
```

**Rule of thumb:** Start at Tier 1. Promote only when Tier 1 demonstrably hurts (e.g., editor becomes slow, XAML changes need full-file review). Don't preemptively modularize.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Wrong |
|--------------|----------------|
| Modular structure for a 500-line tool | 15 files of overhead for code that fits in one screen |
| Single-file for a 5000-line tool | Editor slows, merge conflicts every change |
| Putting XAML in a separate file for a 200-line UI | Here-string is fine; separate file adds a load step with no benefit |
| Splitting "for future-proofing" | YAGNI — promote when the pain is real, not when it's imagined |
| Mandatory `tests/`, `scripts/`, `docs/` folders | Empty folders add noise. Add when you actually have content |

---

## Bootstrap (Tier 1)

Tier 1 needs only one file. Here's the complete entry-point structure:

```powershell
<#
.TITLE
    ToolName - Brief purpose statement

.SYNOPSIS
    One-line summary of what the tool does.

.DESCRIPTION
    Full description: what it targets, thresholds and parameters, what gets
    skipped, and how results are reported.

.TAGS
    Operational

.PLATFORM
    Windows

.PERMISSIONS
    None (local execution) or the required Graph scopes

.AUTHOR
    AI Generated

.VERSION
    1.0

.CHANGELOG
    1.0 - Initial release

.LASTUPDATE
    YYYY-MM-DD

.EXAMPLE
    .\ToolName.ps1
    What this example does.

.EXAMPLE
    .\ToolName.ps1 -TryMode
    Preview behavior without making changes.

.NOTES
    - Execution context and elevation behavior.
    - Exit codes: 0 = success, 1 = failure.
    - Log: C:\ProgramData\ToolName\Logs\
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$TryMode
)

$ErrorActionPreference = 'Stop'

# --- STA Check ---
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $PSCommandPath
    exit
}

# --- Logging ---
# IDENTITY LOCK: paste scripts/Add-LogLine.ps1 VERBATIM here — its init block
# (below) plus the full Add-LogLine function ($script:lastLogKey consecutive-duplicate
# guard, UTF8 file write, Tailwind Slate console colors, status-bar update).
# NEVER retype a simplified version: rewriting drops the duplicate guard, floods logs,
# and Test-ToolCompliance FAILs any GUI tool whose Add-LogLine lacks $script:lastLogKey.
$ToolName = 'ToolName'
$script:LogDir = Join-Path $env:LOCALAPPDATA "$ToolName\Logs"
if (-not (Test-Path $script:LogDir)) { New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null }
$script:LogFile = Join-Path $script:LogDir "$ToolName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:lastLogKey = $null
# function Add-LogLine { ... paste the body of scripts/Add-LogLine.ps1 here, unchanged ... }

# --- Assembly + XAML ---
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tool Name" Width="900" Height="600"
        WindowStartupLocation="CenterScreen"
        Background="{DynamicResource BackgroundBrush}"
        FontFamily="Segoe UI" FontSize="13">
    <Window.Resources>
        <!-- Tailwind Slate seed brushes (full set in references/design-tokens.md) -->
        <SolidColorBrush x:Key="BackgroundBrush" Color="#F1F5F9"/>
        <SolidColorBrush x:Key="SurfaceBrush" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#3B82F6"/>
        <SolidColorBrush x:Key="SuccessBrush" Color="#10B981"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#EF4444"/>
        <SolidColorBrush x:Key="WarningBrush" Color="#F59E0B"/>
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="#0F172A"/>
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="#64748B"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#E2E8F0"/>
        <!-- Required styles (full set in references/xaml-styles.md) -->
        <Style x:Key="BtnBase" TargetType="{x:Type Button}">
            <!-- ... full BtnBase template ... -->
        </Style>
        <Style x:Key="BtnPrimary" TargetType="{x:Type Button}" BasedOn="{StaticResource BtnBase}">
            <Setter Property="Background" Value="{DynamicResource AccentBrush}"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <!-- ... more styles as needed ... -->
    </Window.Resources>
    <Grid>
        <!-- Your UI here -->
    </Grid>
</Window>
'@

# --- Safe XAML Loader ---
function ConvertTo-XamlWindow {
    param([string]$Xaml)
    $xaml = $Xaml -replace 'x:Class=".*?"', '' -replace 'mc:Ignorable=".*?"', ''
    $xaml = $xaml.Trim()
    try {
        $reader = New-Object System.Xml.XmlNodeReader([xml]$xaml)
        [System.Windows.Markup.XamlReader]::Load($reader)
    } catch {
        Add-LogLine "XAML parse failed: $_" 'ERROR'
        throw
    }
}

# --- Load + Bind ---
$script:Window = ConvertTo-XamlWindow -Xaml $xaml

# --- Initialize theme immediately (prevents initial single-color screen) ---
# PSWrap and DeviceInfoViewer both showed all-white/all-one-color until first ThemeToggle
# because DynamicResource brushes were not materialized until Set-Theme replaced them.
try {
    Set-Theme -Window $script:Window -IsDark $false
    $script:isDarkMode = $false
    if ($script:ThemeIcon) {
        $script:ThemeIcon.Data = [System.Windows.Media.Geometry]::Parse($SunIconData)
        $script:ThemeIcon.Fill = (New-Object System.Windows.Media.BrushConverter).ConvertFromString('#EAB308')
    }
} catch { Add-LogLine "Initial theme setup failed: $($_.Exception.Message)" 'WARNING' }

# $btnFoo = $script:Window.FindName('btnFoo')
# $txtBar = $script:Window.FindName('txtBar')

# --- State + Guards (canonical: scripts/Guard-Action.ps1) ---
$script:isBusy = $false
function Guard-Action {
    param([string]$Name)
    if ($script:isBusy) { Add-LogLine "Busy: $Name" 'WARNING'; return $false }
    $script:isBusy = $true
    return $true
}
function Release-Action { $script:isBusy = $false }

# --- Event Handlers ---
# $btnFoo.Add_Click({
#     if (-not (Guard-Action 'Action')) { return }
#     try {
#         # ... your logic ...
#     } finally { Release-Action }
# })

# --- Show ---
[void]$script:Window.ShowDialog()
```

For Tier 2, replace the here-string `$xaml = @'...'@` with file loading:

```powershell
$xamlPath = Join-Path $PSScriptRoot 'MainWindow.xaml'
$xaml = Get-Content $xamlPath -Raw -Encoding UTF8
$script:Window = ConvertTo-XamlWindow -Xaml $xaml
```

That's the only change. Everything else stays single-file.
