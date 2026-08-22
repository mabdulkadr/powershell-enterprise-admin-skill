---
name: powershell-enterprise-admin
description: Build production-grade enterprise PowerShell tools: WPF GUI apps with Tailwind Slate dark/light theming, Intune Proactive Remediation detection/remediation pairs, Microsoft Graph / Entra ID / Azure AD automation, and enterprise CLI scripts for Active Directory bulk operations, WinRM multi-device execution, CIM/WMI inventory, event log analysis, printer management, and macOS bash for Intune. Use this skill whenever the user wants a helpdesk tool, WPF app, dashboard, DataGrid UI, dark mode toggle, compliance script, notification runbook with email alerts, CSV-driven AD operations, or a professional README — even if they phrase it casually like "make me a tool" or mention Intune or file paths without saying skill. Do NOT use for simple one-liners, non-PowerShell languages like python or javascript or React, or conceptual explanations without code generation.
---

# PowerShell Enterprise Admin

Build production-grade PowerShell tools with modular architecture, Tailwind Slate design system, dark/light theme, async UI patterns, structured logging, and consistent patterns across every tool.

---

## 📑 Table of Contents

1. [Script Type Routing (Classify Before You Build)](#script-type-routing--classify-before-you-build)
2. [Canonical Conventions (One Table, No Exceptions)](#canonical-conventions-one-table-no-exceptions)
3. [The 12 Non-Negotiable Laws](#the-12-non-negotiable-laws)
4. [Enterprise Platform & Compatibility Matrix](#enterprise-platform--compatibility-matrix)
5. [The Right-Sized Architecture (Tier 1/2/3)](#the-right-sized-architecture-choose-by-tool-size)
6. [The 21 Canonical Patterns](#the-21-canonical-patterns-memorize-these)
7. [The Design System — Tailwind Slate Tokens](#the-design-system--tailwind-slate)
8. [The 19 Required XAML Styles](#the-19-required-xaml-styles)
9. [The Log Levels & UI Colors](#the-log-levels-exact-colors)
10. [Intune & Graph API Best Practices](#intune-best-practices)
11. [Writing Professional README.md Files](#writing-professional-readmemd-files)
12. [Verification Checklist (Run Before Returning)](#verification-checklist-before-first-run)
13. [Reference Library Directory](#reference-files-read-in-this-order)

---

## Script Type Routing — Classify Before You Build

Before writing any code, classify the user's request into one of three types. This determines which patterns, headers, and reference files to use.

### Decision Tree

```
What is the user asking for?
│
├── "Build me a GUI tool / dashboard / WPF app / helpdesk tool"
│   └── TYPE 1: WPF GUI Tool (Tier 1/2/3)
│       → Follow the 12 Laws, use XAML styles, Add-LogLine, Guard-Action
│       → Read: references/file-architecture.md, references/patterns.md
│
├── "Create a script for Intune / detection / remediation / compliance / Graph API / Entra ID"
│   │   OR mentions: Intune, detection script, remediation script, compliance,
│   │   Azure Automation, runbook, Managed Identity, Graph API, proactive remediation
│   └── TYPE 2: Intune/Graph Script (CLI)
│       → Use Intune header fields (.REMEDIATIONTYPE, .PAIRSCRIPT, .PLATFORM, .PERMISSIONS)
│       → Read: references/intune-patterns.md, references/notification-patterns.md
│       → Follow: Intune Best Practices section below
│
├── "Write a script for AD / event logs / remote management / bulk operations / printer"
│   │   OR mentions: Active Directory, WinRM, event log, CSV bulk, CIM query,
│   │   printer management, remote server, multi-machine
│   └── TYPE 3: General Enterprise CLI Script
│       → Use standard PowerShell header (references/script-template.md)
│       → Read the domain-specific reference:
│         AD → references/ad-patterns.md
│         Remote → references/winrm-patterns.md
│         Event logs → references/event-log-patterns.md
│         macOS → references/macos-patterns.md
│
└── "Write a README" / "Create documentation"
    └── TYPE 4: Documentation
        → Use the README template in Writing Professional README.md Files section
        → Read: references/readme-template.md
```

### How to Tell Type 2 (Intune) from Type 3 (General CLI)

| Signal | Type 2 (Intune) | Type 3 (General CLI) |
|--------|-----------------|---------------------|
| Mentions Intune, Entra ID, Azure AD | ✅ | ❌ |
| Mentions "detection" or "remediation" | ✅ | ❌ |
| Mentions "compliance" in device context | ✅ | ❌ |
| Mentions "Graph API", "Microsoft.Graph" | ✅ | ❌ (unless Graph is just a data source) |
| Mentions "Azure Automation", "runbook" | ✅ | ❌ |
| Mentions "Managed Identity" | ✅ | ❌ |
| Mentions Active Directory, WinRM | ❌ | ✅ |
| Mentions event logs, CIM/WMI | ❌ | ✅ |
| Mentions CSV bulk operations | ❌ | ✅ |
| Mentions macOS, bash | ❌ | ✅ |
| Mentions WPF, GUI, XAML, dashboard | ❌ | ❌ (Type 1) |
| Just says "PowerShell script" with no context | ❌ | ✅ (default to general) |

**When ambiguous, ask the user.** A script that uses Graph API to query Entra ID for a WPF dashboard is Type 1 (WPF tool) that happens to call Graph — not Type 2.

---

## Canonical Conventions (One Table, No Exceptions)

These conventions are unified across every reference file. When a reference contradicts this table, this table wins. If you find a contradiction, fix the reference, not the convention.

| Convention | Type 1 (WPF GUI) | Type 2 (Intune/Graph CLI) | Type 3 (General CLI) |
|------------|------------------|---------------------------|----------------------|
| **Header format** | Canonical rich header, ALL types identical (Enterprise standard): `.TITLE .SYNOPSIS .DESCRIPTION .TAGS` `[.REMEDIATIONTYPE .PAIRSCRIPT for pairs]` `.PLATFORM [.MINROLE] .PERMISSIONS .AUTHOR .VERSION .CHANGELOG .LASTUPDATE .EXAMPLE(s) .NOTES` with one blank line between fields — see `references/_header-canonical.md` | Same canonical rich header | Same canonical rich header |
| **File naming** | `[ToolName].ps1` | `detect-<name>.ps1` / `remediate-<name>.ps1` / `notify-<name>.ps1` | `[ToolName].ps1` |
| **Logging function** | `Add-LogLine` (`scripts/Add-LogLine.ps1`) | `Write-Log` + `Initialize-Log` + `Finish-Script` + `Write-Banner` (`scripts/Write-Log.ps1`, `references/intune-patterns.md`) | `Write-Log` + `Write-Banner` (`scripts/Write-Log.ps1`, `references/intune-patterns.md`) |
| **Log path** | `%LOCALAPPDATA%\<ToolName>\Logs\` | `<SystemDrive>\IntuneLogs\<SolutionName>\` | `C:\ProgramData\<ToolName>\Logs\` |
| **Exit codes** | n/a (GUI) | Detection: 0=compliant / 1=non-compliant / 2=error. Remediation: 0=success / 1=failure / 2=error | 0=success / 1=failure |
| **`.PERMISSIONS` field** | n/a | Only real Graph scopes; `None (local SYSTEM context)` when the script doesn't call Graph | Only if the script calls Graph |
| **Busy guard** | `Guard-Action` / `Release-Action` (`scripts/Guard-Action.ps1`) | n/a | n/a |
| **Graph pagination** | In background jobs (Pattern B) | `Get-MgGraphAllPages` (`scripts/Get-MgGraphAllPages.ps1`) | Same, if Graph is used |
| **Graph auth** | Interactive (user context) | Per context — `scripts/Connect-GraphAuth.ps1` | Per context |

**Why this table exists:** five reference files previously shipped different log paths and function names for the same concept. Operators troubleshooting a fleet found logs in three different locations depending on which file the model had read. One table, one convention, one place to look.

---

## Identity Lock — Names You Copy, Never Invent

Long-context models drift: they write a 1,400-line GUI and quietly mint `PrimaryButtonStyle`, `ColorBg`, or `StatusText` instead of the canonical identifiers. Those tools *run*, so the drift ships silently — until theme switching breaks, shared theming tooling misses, or a reviewer rejects the tool. Treat these names as a fixed API. If a name you are about to type is not in this table, stop and re-open the canonical reference instead of inventing an alias.

| Category | Canonical identifiers (exact spelling) |
|----------|----------------------------------------|
| **Brush tokens** | `BackgroundBrush` `SurfaceBrush` `SurfaceAltBrush`(see design-tokens) `BorderBrush` `TextPrimaryBrush` `TextSecondaryBrush` `TextMutedBrush` `TextBodyBrush` `AccentBrush` `AccentHoverBrush` `SuccessBrush` `WarningBrush` `DangerBrush` `SidebarBrush` — full set with light/dark values in `references/design-tokens.md`. Never write `ColorBg`, `ColorSurface`, `CardBg`, or any invented alias |
| **Style keys (GUI)** | The 19 keys under *The 19 Required XAML Styles* below: `BtnBase` `BtnPrimary` `BtnBlue` `BtnGreen` `BtnRed` `BtnPurple` `BtnGhost` `BtnOutline` `BottomActionBtn` `NavBtnBase` `Card` `StatCard` `FieldLabel` `InputBox` `InputBoxNoHover` `StyledCheckBox` `StyledComboBox` `LiveMessageCenterBox` `SessionCard`. Need a variant? Extend with `BasedOn="{StaticResource BtnPrimary}"` — never mint new key names like `PrimaryButtonStyle`, `SecondaryButtonStyle`, `IconButtonStyle`, `CardBorderStyle` |
| **StatusBar controls** | `StatusDot` \| `StatusLabel` \| `StatusBarText` \| `StatusTime` — never `StatusText`, `StatusMessage`, `ClockText` |
| **Header controls** | `ConnectionDot` + `ConnectionLabel` + `ThemeToggleBtn` on every tool; add `TryModeBtn` / `SignInBtn` only when that feature actually exists (omit otherwise — no placeholders) |
| **GUI logging internals** | Copy `scripts/Add-LogLine.ps1` VERBATIM into the tool — including `$script:lastLogKey` duplicate guard, status-bar update, UTF8 file write, and console colors. Rewriting it from memory drops the duplicate guard and floods logs |
| **CLI logging internals** | Copy `scripts/Write-Log.ps1` verbatim (`Initialize-Log` / `Write-Banner` / `Write-Log` / `Finish-Script`) |

**Enforcement:** before delivering ANY tool, run `scripts/Test-ToolCompliance.ps1 -ToolPath <file.ps1>` and fix every FAIL it reports. The script greps for exactly the drift patterns above (symbol fonts, invented style keys, missing token names, missing guards). A tool that passes manual review but fails this script is not done.

---

## The 12 Non-Negotiable Laws

**Violating any law = the tool is rejected. No exceptions.**

| # | Law | Why it matters |
|---|-----|----------------|
| 1 | **HEADER LAW** — Every `.ps1` opens with the canonical rich header FIRST, identical field order for all types: `.TITLE .SYNOPSIS .DESCRIPTION .TAGS [.REMEDIATIONTYPE .PAIRSCRIPT] .PLATFORM [.MINROLE] .PERMISSIONS .AUTHOR .VERSION .CHANGELOG .LASTUPDATE .EXAMPLE(s) .NOTES`, one blank line between field blocks (template: `references/_header-canonical.md`), followed by `#Requires -Version 5.1`. Never write `#Requires -RunAsAdministrator` — detect elevation at runtime with `Test-IsElevated` and degrade gracefully | The header is the API contract. Without it, `Get-Help` returns nothing and reviewers cannot understand the tool. A hard elevation requirement kills partial-work runs and blocks unelevated logging. |
| 2 | **NAMING LAW** — Functions = `Verb-Noun` PascalCase. Local variables = `camelCase` (`$computerName`, `$logDir`). Script-shared variables = `$script:PascalCase` (`$script:IsBusy`, `$script:LogFile`) — prefix + PascalCase. UI controls = prefix (`$btnSubmit`, `$txtInput`, `$dgvResults`) | Consistent naming means every tool reads the same. The next person can find what they need without searching. |
| 3 | **NO ALIASES LAW** — Never use `gci`, `?`, `%`, `select`, `ft`, `where` in saved scripts. Full cmdlet names only | Aliases hide intent and confuse grep. A junior reading `gci | ?` has to translate to `Get-ChildItem | Where-Object` mentally. |
| 4 | **ERROR LAW** — `$ErrorActionPreference = 'Stop'` at entry point. Specific `catch` types. Never empty `catch {}`. Use `try/catch/finally` for cleanup | Production errors must surface with the actual exception type, not get swallowed silently. The user (helpdesk) must see *why* it failed. |
| 5 | **COLOR LAW** — All bg/surface/text/border colors use `{DynamicResource TokenName}`. Semantic colors (`#3B82F6`, `#10B981`, `#EF4444`, `#F59E0B`) may be hardcoded in XAML. Background tints MUST use `DynamicResource` | The only way dark/light theme toggle works without rebuilding the UI. If a color is hardcoded, dark mode breaks that control. |
| 6 | **ICON LAW** — Every icon is an SVG `<Path Data="..."/>` element with `Stretch="Uniform"`. ZERO icon/symbol fonts of any kind: Segoe Fluent Icons, **Segoe MDL2 Assets** (`FontFamily="Segoe MDL2 Assets"`), and Segoe UI Symbol are ALL forbidden. Copy path data verbatim from `references/icons.md`; never synthesize glyph escapes like `&#xE7F4;` or `[char]0xE701` | Symbol fonts look like a shortcut but fail on Windows Server (Fluent is not installed), render as empty boxes on locked-down builds, and cannot recolor with theme brushes the way `Path.Fill="{DynamicResource AccentBrush}"` does. Models rationalize "MDL2 is not Fluent" — this law bans both. Compliance grep: `Segoe\s*(MDL2|Fluent|UI Symbol)` must return 0 hits in every delivered tool. |
| 7 | **SIDEBAR LAW** — Sidebar = Logo + Nav buttons + Version footer ONLY. System controls (Sign In, Theme toggle, Try Mode) belong in the **Header toolbar** top-right | The sidebar is for navigation. Mixing system controls with nav breaks the user's mental model and creates inconsistent layouts across tools. |
| 8 | **THREAD LAW** — NEVER block the WPF dispatcher. Long ops use `[powershell]::BeginInvoke()` + `DispatcherTimer` (350ms poll). Data load uses `Start-Job` + `DispatcherTimer` (300ms poll) | A blocked UI thread = frozen window. The user thinks the tool crashed. They click again. Now you have a second operation racing the first. |
| 9 | **AMPERSAND LAW** — Every `&` in XAML text/attributes MUST be `&amp;`. Unescaped `&` causes `XamlParseException` | This is a silent crash at ShowDialog. The XAML parses but the renderer fails. Test with `XamlReader.Parse()` to catch it before runtime. |
| 10 | **STATICRESOURCE LAW** — Every `{StaticResource X}` MUST have a matching `<Style x:Key="X">` in `Window.Resources`. Missing key = crash at `ShowDialog()` | Same silent crash as Law 9. The parse succeeds, the runtime fails. Use `DynamicResource` when the key may not exist at compile time. |
| 11 | **LANGUAGE & BRANDING LAW** — All generated scripts, comments, headers, log messages, and README.md must be **English only**. Never emit Arabic, mixed-language, or external branding (e.g., `IntuneAutomation.com`) in code or docs. Use generic `.AUTHOR AI Generated` and internal references (`references/_header-canonical.md`) | Enterprise scripts run on English OS locales, Intune, and Git; non-ASCII breaks parsers, grep, and CI. External branding leaks training examples and confuses ownership. |
| 12 | **REPORT PATH LAW** — Default `OutputPath`/`Reports` must be **beside the original script**, never `".\Reports"` or `Get-Location` alone. Use `$PSScriptRoot` with dot-source fallback: `$scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }; Join-Path $scriptBase "Reports"` and normalize with `if (-not $PSBoundParameters.ContainsKey('OutputPath')) { $OutputPath = Join-Path $scriptBase "Reports" }` | `. 'path\to\script.ps1'` leaves `$PSScriptRoot=''` → `Join-Path '' 'Reports'` crashes with `ParameterBindingValidationException`. Beside-script guarantees the report is found where the operator expects it, regardless of caller's `cd`. |

---

## Enterprise Platform & Compatibility Matrix

Every script and tool built with this skill is tested against the following enterprise compatibility matrix:

| Operating System | PowerShell Version | WPF GUI (Type 1) | Intune Remediation (Type 2) | Enterprise CLI (Type 3) | Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Windows 11 (22H2–24H2)** | 5.1 / 7.4+ | ✅ Full Support | ✅ Full Support | ✅ Full Support | Modern WinRT toasts & native STA WPF. |
| **Windows 10 (21H2–22H2)** | 5.1 / 7.4+ | ✅ Full Support | ✅ Full Support | ✅ Full Support | Standard enterprise client base. |
| **Windows Server 2025/2022** | 5.1 / 7.4+ | ✅ Full Support | ⚠️ Hybrid Azure Arc | ✅ Full Support | Server Desktop Experience required for WPF. |
| **Windows Server 2019/2016** | 5.1 | ✅ Full Support | ⚠️ Hybrid Azure Arc | ✅ Full Support | Uses SVG paths; no Segoe Fluent dependency. |
| **macOS (Sonoma / Sequoia)** | Bash 3.2+ / zsh | ❌ n/a | ✅ Via Intune macOS | ✅ macOS Shell | Follows `references/macos-patterns.md`. |
| **Azure Automation Cloud** | 5.1 / 7.2 | ❌ Headless | ✅ Runbooks | ✅ Hybrid Worker | Strict 400MB RAM / 3hr runtime limits. |

---

## The Right-Sized Architecture (Choose by Tool Size)

Pick the smallest structure that fits. Most admin tools are **single-file** — the modular layout is for the framework itself, not for the tools it produces.

| Tier | When | Files |
|------|------|-------|
| **1. Single-file** | Default — most admin tools | 4-5 files, everything in 1 `.ps1` |
| **2. Split XAML** | Long XAML (>500 lines) or repeated dialogs | 6-7 files, XAML in `.xaml` |
| **3. Modular (PSWrap)** | Complex GUI (5+ features, settings, drag-drop) OR frameworks | 15-25 files, embedded XAML + `src/` + `config/` |

**Hybrid rule (PSWrap):** Tier 1 for simple single-workflow tools, **Tier 3 PSWrap-style for complex GUI** even with one audience. PSWrap (https://github.com/mabdulkadr/PSWrap) is the canonical GUI reference — embedded GZip+Base64 XAML, P/Invoke console-hide, `src/` modular, `%APPDATA%` settings. See `references/file-architecture.md` (Tier 3 PSWrap).

**The 80% rule:** Use Tier 1 for 80% of simple tools. Complex GUI → Tier 3.

**Anti-patterns:** Modular structure for a 500-line tool (overhead). Single-file for a 5000-line tool (editor pain). Splitting "for future-proofing" (YAGNI). Empty `tests/`, `scripts/`, `docs/` folders.

For the folder trees, the full decision guide, and the complete Tier 1 bootstrap (single-file structure with all required pieces), see `references/file-architecture.md`.

---

## The 21 Canonical Patterns (Memorize These)

Every tool needs the same primitives. Read the pattern reference for the exact implementation; Pattern H's code is canonical in `scripts/Guard-Action.ps1`:

| Pattern | When | File |
|---------|------|------|
| **A. Theme Toggle** | Always — sun/moon icon swap | `references/patterns.md` |
| **B. Background Data Load** | CIM/WMI queries, Graph API calls | `references/patterns.md` |
| **C. Async Runspace** | Long .NET ops, in-process assemblies | `references/patterns.md` |
| **D. Inline XAML Dialog** | Modal forms that don't need their own XAML file | `references/patterns.md` |
| **E. LogViewer Theme Copy** | Always — child windows must inherit theme | `references/patterns.md` |
| **F. Window-Level Drag & Drop** | File path inputs | `references/patterns.md` |
| **G. Select All / Deselect All DataGrid** | Bulk operations on row-checked grids | `references/patterns.md` |
| **H. Guard-Action / Release-Action** | **EVERY interactive button** | `scripts/Guard-Action.ps1` (canonical) |
| **I. Set-UIState Busy/Idle** | Disable buttons + show progress bar | `references/patterns.md` |
| **J. Update-UIState Central Refresh** | TextChanged events, post-action state | `references/patterns.md` |
| **K. Clock Timer** | StatusBar always shows current time | `references/patterns.md` |
| **L. Show-ToastMessage** | Replace MessageBox for non-blocking notifications (In-App) | `references/patterns.md` |
| **M. About Dialog Markdown Rendering** | `docs/*.md` → WPF elements | `references/patterns.md` |
| **N. Live Column Filtering** | Filter boxes over DataGrid columns | `references/patterns.md` |
| **O. Shift-Click Range Selection** | Fast multi-row checkbox selection | `references/patterns.md` |
| **P. Multi-Input Query Parsing** | Comma/newline search box parsing | `references/patterns.md` |
| **Q. Settings Persistence** | Safe `%LocalAppData%` JSON config | `references/patterns.md` |
| **R. Async External Process Wrapper** | Non-blocking CLI tool wrapper with polling | `references/patterns.md` |
| **S. Live Message Center Console** | Color-coded in-app RichTextBox log terminal | `references/patterns.md` |
| **T. Native Windows Toast** | Action Center notifications via WinRT XML without extra modules | `references/patterns.md` |
| **U. Responsive HTML Executive Report** | Self-contained executive HTML dashboard with instant search | `references/patterns.md` |

---

## The Design System — Tailwind Slate

Every color, every spacing value, every font size is defined as a **token**. The design system lives in `Window.Resources` and gets overridden by `Set-Theme`.

Core tokens (11 shown) + full set in `references/design-tokens.md`:

| Token | Light → Dark | Use |
|-------|--------------|-----|
| `BackgroundBrush` | `#F1F5F9` → `#1E293B` | Window background |
| `SurfaceBrush` | `#FFFFFF` → `#334155` | Cards, inputs |
| `AccentBrush` | `#3B82F6` → `#60A5FA` | Primary accent |
| `TextPrimaryBrush` | `#0F172A` → `#FFFFFF` | Headings |
| `BorderBrush` | `#E2E8F0` → `#475569` | Borders |

Spacing: `Card Padding=18`, `Card CornerRadius=14`, `Button CornerRadius=8`, `Button Height=38/34`. Typography: Segoe UI Variable, 11–28pt. Full dark-mode overrides, spacing, and typography in `references/design-tokens.md` (canonical). Also see `references/_header-canonical.md` for file structure.

---

## The 19 Required XAML Styles

Every `MainWindow.xaml` MUST define these styles in `Window.Resources`. They are the visual identity of every tool — change them and you've broken the design language.

| Style | Target | Purpose |
|-------|--------|---------|
| `BtnBase` | Button | Root button: 38px, 8px corner, hover opacity |
| `BtnPrimary` | Button | Primary CTA — `BtnPrimaryBg` fill, White text |
| `BtnBlue` | Button | Subtle blue — `BtnBlueBg` |
| `BtnGreen` | Button | Success — `BtnGreenBg` |
| `BtnRed` | Button | Danger — `BtnRedBg` |
| `BtnPurple` | Button | About tab selector — `BtnPurpleBg` |
| `BtnGhost` | Button | Transparent, hover tint only |
| `BtnOutline` | Button | Transparent fill, 1px border, hover surface |
| `BottomActionBtn` | Button | 34px, sidebar footer (About/Logs) |
| `NavBtnBase` | Button | 46px, 10px corner, left-aligned nav |
| `Card` | Border | Surface bg, 12px corner, drop shadow |
| `StatCard` | Border | Like Card but with hover-border highlight |
| `FieldLabel` | TextBlock | 12-14px SemiBold, secondary text |
| `InputBox` | TextBox | 34px, focus border AccentBrush, NO IsMouseOver |
| `InputBoxNoHover` | TextBox | Like InputBox but no border change on hover |
| `StyledCheckBox` | CheckBox | Modern CheckBox with SemiBold text and hand cursor |
| `StyledComboBox` | ComboBox | 34px height, surface background, theme border |
| `LiveMessageCenterBox` | RichTextBox | 140px, dark terminal background (`#1E293B`) for streaming logs |
| `SessionCard` | Border | Sidebar session details card with elevation pill |

**Critical:** Cards are STATIC. No `IsMouseOver` triggers — only `<Button>` elements get hover via their ControlTemplate, plus ONE sanctioned exception: `StatCard` KPI tiles use a border-highlight hover trigger. Read `references/xaml-styles.md` for the complete XAML for every style.

---

## The Log Levels (Exact Colors)

| Level | Color | Use |
|-------|-------|-----|
| `DEBUG` | `#94A3B8` | Verbose debug |
| `INFO` | `#3B82F6` | Default informational |
| `SUCCESS` | `#10B981` | Operation succeeded |
| `WARNING` | `#F59E0B` | Non-fatal warning |
| `ERROR` | `#EF4444` | Failure |

**WPF GUI tools use `Add-LogLine`** (duplicate guard + file + status bar + console). **CLI scripts use `Write-Log`** (console + file, see Intune Best Practices → CLI Script Helpers below). The GUI signature is:

```powershell
Add-LogLine -Message "Text" -Level 'INFO'
```

`Add-LogLine` adds to the log, writes to the file log, updates the status bar, and emits to console — in that order. The consecutive-duplicate guard (`$script:lastLogKey`) drops immediate duplicate lines so repeated operations don't flood the log. Canonical implementations: `scripts/Add-LogLine.ps1` (GUI) and `scripts/Write-Log.ps1` (CLI). Never invent a third logging function. The colors above are fixed and identical in console output and the GUI Message Center RichTextBox.

---

## The Required XAML Structure

Every MainWindow follows this layout exactly:

```
Window (WindowStyle="SingleBorderWindow", ResizeMode="CanResizeWithGrip")
└── Grid (3 rows: Auto / * / Auto)
    ├── Row 0: Header (DockPanel)
    │   └── Right side: ConnectionDot + ConnectionLabel + ThemeToggle + TryModeBtn + SignInBtn
    ├── Row 1: Grid (2 cols: Auto Sidebar | * Content)
    │   ├── Col 0: Sidebar (DockPanel)
    │   │   ├── Top: Logo + AppName + Tagline
    │   │   ├── Mid: Nav buttons (NavBtnBase style)
    │   │   └── Bottom: AboutBtn + LogsBtn (BottomActionBtn) + version
    │   └── Col 1: Content area
    │       └── Pages (Visibility toggled by Set-ActivePage)
    └── Row 2: StatusBar
        └── Grid (4 cols): StatusDot | StatusLabel | StatusBarText | StatusTime
```

**Why this exact structure:**

- Header toolbar top-right = consistent "system controls" location across all tools
- Sidebar bottom = consistent "About + Logs" footer
- StatusBar bottom = always-visible status, time, and progress
- Pages pattern = multi-feature tools without navigation tabs cluttering the chrome

---

## Workflow: Building a New Tool

### Tier 1 (Single-File — Most Tools)

0. **Pre-flight gate (do not skip, especially deep into a long session):** re-open `references/xaml-styles.md`, `references/design-tokens.md`, `references/icons.md` (GUI) or the relevant CLI reference (CLI) *immediately before writing code*. Styles, tokens, icons, and logging helpers are COPIED from these files verbatim. Writing them from memory is how naming drift happens — invented style keys, symbol-font glyphs, off-canon colors — even when the rules were read earlier in the session.
1. Create `[ToolName].ps1` with the canonical header (TITLE, SYNOPSIS, DESCRIPTION, PARAMETER, EXAMPLE, NOTES)
2. Add the required building blocks in this order:
   - `#Requires -Version 5.1` (immediately after the help block from step 1 — never before it) + `[CmdletBinding()]` + params
   - `$ErrorActionPreference = 'Stop'`
   - STA check + auto-restart
   - `Add-LogLine` function (console + file)
   - WPF assembly loading
   - XAML here-string with design tokens + required styles in `Window.Resources`
   - `ConvertTo-XamlWindow` loader
   - `Guard-Action` / `Release-Action` functions
   - Control bindings (`$btnFoo = $Window.FindName('btnFoo')`)
   - Event handlers (every `Add_Click` wrapped in `Guard-Action` / `try` / `finally Release-Action`)
   - `[void]$Window.ShowDialog()`
3. Test XAML with `XamlReader.Parse()` before launching
4. Run verification checklist below

### Tier 2 (Split XAML)

Same as Tier 1, but replace the XAML here-string with `$xaml = Get-Content 'MainWindow.xaml' -Raw`.

### Tier 3 (Modular)

See `references/file-architecture.md` for the full structure.

### CLI Scripts (No GUI)

Before writing, classify the script using the **Script Type Routing** decision tree above.

1. Use `references/script-template.md` for the canonical header and the **Description & Comment Writing Standards** (section 17 of that file: .DESCRIPTION quality bar, HelpMessage, intent-labeled examples, graceful elevation degradation, structured per-target results)
2. **Pick the right reference based on classification:**
   - **Type 2 (Intune/Graph):** → `references/intune-patterns.md` (always) + `references/notification-patterns.md` (if notification script)
   - **Type 3 (General CLI):** → pick by domain:
     - Active Directory → `references/ad-patterns.md`
     - Multi-machine remote → `references/winrm-patterns.md`
     - Event log analysis → `references/event-log-patterns.md`
     - macOS enterprise → `references/macos-patterns.md`
     - Printer management → `references/ad-patterns.md` (printer ops use AD + CIM)
     - CIM/WMI inventory → inline CIM patterns (no separate reference)
3. Use `Write-Log` (canonical in `scripts/Write-Log.ps1`) for console output — CLI scripts never use the GUI `Add-LogLine`
4. **Only add Intune-specific header fields (.REMEDIATIONTYPE, .PAIRSCRIPT, etc.) if the script is actually for Intune.** General CLI scripts use the standard header without these fields.

### Intune Best Practices

**Only apply these patterns when the script is Type 2 (Intune/Graph).** General CLI scripts (Type 3) do NOT use these patterns — they use standard PowerShell headers and logging.

The complete production-tested pattern set lives in `references/intune-patterns.md` (headers, module checks, Graph pagination/retry, remediation pairs, always-run detection, config-driven execution, remote diagnostics) and `references/notification-patterns.md` (scheduled email alerts). Read the relevant file before writing a Type 2 script — this section only lists the rules that must never be violated:

- **Exit codes are canonical:** Detection = `0` compliant / `1` non-compliant / `2` script error. Remediation = `0` success / `1` failure / `2` script error. Never use `1` for a script error — Intune would treat a crashed detection as non-compliant and run remediation needlessly.
- **Module checks first:** Validate `Microsoft.Graph.Authentication` (and any other modules) exist before importing — never fail halfway through execution.
- **Pagination is never manual:** Use the canonical `Get-MgGraphAllPages` (in `scripts/Get-MgGraphAllPages.ps1`) for any Graph API call that can return more than one page. Wrap retryable calls in `Invoke-MgGraphRequestWithRetry` for 429/503.
- **Auth matches context:** Managed Identity in Azure Automation, interactive (or MgGraphCommunity for RDP/CI-CD) locally, Client Credentials (App Registration) for unattended service contexts. See `scripts/Connect-GraphAuth.ps1`.
- **Remediation scripts are paired** (detection + action), idempotent, and verify the fix after applying it (pre-check → action → post-verify with JSON output).
- **Log to `<SystemDrive>\IntuneLogs\<SolutionName>\`** with `Initialize-Log` + `Write-Log` (canonical in `scripts/Write-Log.ps1`); use `Finish-Script` for every exit point.
- **`.PERMISSIONS` reflects what the script actually calls.** A script that runs locally in SYSTEM context (`ipconfig /flushdns`, service restarts, disk cleanup) needs **no Graph permission** — declare `None (local SYSTEM context)` instead of inventing Graph scopes. Only scripts that call Graph API list real permissions.
- **Notification scripts** (`.EXECUTION RunbookOnly`, `.OUTPUT Email`) run as Azure Automation runbooks with Managed Identity, send HTML email via Graph Mail API with `saveToSentItems = $false` — see `references/notification-patterns.md`.

---

## Verification Checklist (Before First Run)

### XAML (Tier 1 + 2)
- [ ] Parses with BOTH `XamlReader.Parse()` AND `XmlNodeReader` + `XamlReader.Load()`
- [ ] All `{StaticResource X}` have matching `<Style x:Key="X">` in Window.Resources
- [ ] All `&` in XAML are `&amp;`
- [ ] `<Grid>` open/close tags balanced
- [ ] No custom ScrollBar template (Thumb.CornerRadius doesn't exist in PS 5.1)

### Controls
- [ ] Every `x:Name` in XAML has a matching `FindName()` binding
- [ ] Every interactive button has a handler
- [ ] All buttons have a `ToolTip`
- [ ] All action buttons have an SVG icon (not Segoe Fluent Icons)

### Colors / Theme
- [ ] All bg/surface/border/text use `{DynamicResource}`
- [ ] Cards/Borders have NO `IsMouseOver` triggers (only Buttons do — sole exception: StatCard KPI tiles)
- [ ] InputBox has NO `IsMouseOver` trigger (keyboard focus only)

### Behavior
- [ ] STA check + auto-restart at top of file
- [ ] `$ErrorActionPreference = 'Stop'` at entry point
- [ ] `Guard-Action` wraps every interactive button handler
- [ ] `Release-Action` is in a `finally` block (not after `try`)
- [ ] Long operations use `Start-Job` or async runspace (never block UI thread)
- [ ] Background jobs cleaned up on window close

### Identity Lock (automated)
- [ ] `scripts/Test-ToolCompliance.ps1 -ToolPath <file>` run → **zero FAIL lines**
- [ ] Zero Segoe MDL2 / Fluent / UI Symbol references (ICON LAW)
- [ ] GUI: canonical style keys + brush tokens present, no invented aliases
- [ ] GUI: `$script:lastLogKey` guard present; StatusBar uses `StatusBarText`
- [ ] README has shields.io badges + Disclaimer section

For the **full PS 5.1 pitfalls list** (Thumb.CornerRadius, Join-Path, Pester 3.4, ampersand crashes, etc.), see `references/pitfalls.md`.

---

## Writing Professional README.md Files

Every PowerShell project needs a clear README. **Canonical templates live in `references/readme-template.md`** (4 variants: Basic, Intune Remediation, WPF GUI, CLI Script — ~70% shared).

**Use:** pick the variant matching script type, **paste the variant template as the README's starting skeleton**, then replace `[Placeholders]` — never write a README from scratch. Keep order: Badges → Overview → Features → Structure → Scripts (Purpose/Logic/Exit Codes/Example) → Requirements → Intune Deployment (if pair) → Typical Workflow → Operational Notes → Disclaimer (mandatory: as-is, test in staging) → License → Author.

These elements are non-negotiable in every variant — models writing from scratch reliably skip them:

```markdown
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
```

```markdown
## Disclaimer

This script is provided as-is with no warranty of any kind. Test it in a
staging environment before deploying to production. The author assumes no
liability for any damage or data loss resulting from its use.
```

A README without shields.io badges or a Disclaimer section fails review even when everything else is perfect.

**Key principles:** shields.io badges (`License`, `PowerShell 5.1+`, `Platform`, `Intune` if pair), emojis for scan, tables for exit codes/settings, ` ```powershell` + ` ```text` language tags, `---` between sections.

Full templates + badge reference + section examples → `references/readme-template.md` (canonical). Also see `references/_header-canonical.md` for header consistency.

---

## Lessons Learned Register

This skill learns from its own mistakes. The **Lessons Learned Register** lives INSIDE the skill at `<skill-dir>/lessons-learned.md` — it is global and applies to every script, tool, and project the skill touches. Do not create project-local copies; one shared register means a lesson learned in one project protects every future build.

**Before building:** read the register from the skill directory. If a listed lesson applies to the current task, follow its rule.

**Append an entry immediately when any of these happens:**
- The user corrected your output (naming, structure, a rule you got wrong)
- A delivered script crashed or failed at runtime (PS 5.1 incompatibility, XAML parse error, auth failure, culture-related date bug)
- You hit a non-obvious pitfall not already in `references/pitfalls.md`
- You discovered a new environment constraint (PS version, module availability, policy)

**Entry format** (full format + example in `references/lessons-learned.md`):

```markdown
## YYYY-MM-DD | <tool name> | <area>
- **Mistake:** what was done wrong
- **Cause:** why it happened
- **Fix:** what actually solved it
- **Rule:** the reusable rule, imperative
```

**Rules:** dedupe against this register and `references/pitfalls.md` before appending; entries are evidence-based (no speculation); one line per field. When the same rule has prevented a mistake twice across sessions, propose promoting it into `references/pitfalls.md` (ask the user — never edit reference files unilaterally).

---

## Reference Files (Read in This Order)

**Canonical single sources (edit ONLY these for cross-cutting changes):**

1. **`references/_header-canonical.md`** — Header field order + file order (all types) — single source for `script-template.md`, `intune-patterns.md`, `file-architecture.md`
2. **`references/_logging-canonical.md`** — Logging per context (GUI vs CLI) + levels/colors + paths — single source for `script-template.md`, `intune-patterns.md`
3. **`references/_graph-canonical.md`** — Graph pagination/retry/batch/auth/403 unified (7-service ValidateSet, Retry-After) — single source for `intune-patterns.md`, `notification-patterns.md`, `scripts/*`

Then:

4. **`scripts/`** — Canonical implementations, copy verbatim: `Add-LogLine.ps1` (GUI), `Write-Log.ps1` (CLI + `Initialize-Log`/`Finish-Script`), `Guard-Action.ps1` (Pattern H), `Get-MgGraphAllPages.ps1`, `Invoke-GraphRequestWithRetry.ps1`, `Invoke-GraphBatchRequest.ps1`, `Get-Graph403Message.ps1`, `ConvertTo-SafeDateTime.ps1`, `Connect-GraphAuth.ps1`, `Test-XamlFile.ps1`, `Test-Skill.ps1` (skill self-test), plus PSWrap-style `Embed-Xaml.ps1` for embedded XAML build step
5. **`references/file-architecture.md`** — Tier 1/2/3 folder structures + complete Tier 1 bootstrap code + **PSWrap Tier 3 reference (embedded XAML, console-hide, AppConstants)**
6. **`references/design-tokens.md`** — Complete Tailwind Slate color tokens + light/dark overrides + spacing + typography (canonical for `SKILL.md` Design System)
7. **`references/xaml-styles.md`** — Full XAML for every required style (BtnBase hierarchy, Card, StatCard, InputBox, NavBtnBase, StyledCheckBox, StyledComboBox, LiveMessageCenterBox, SessionCard)
8. **`references/patterns.md`** — The 21 canonical patterns (A–U)
9. **`references/pitfalls.md`** — 20+ documented PS 5.1 crash causes and fixes
10. **`references/icons.md`** — SVG path data for the standard icon set
11. **`references/script-template.md`** — CLI header + Description quality bar + examples (extends `_header-canonical.md`)
12. **`references/intune-patterns.md`** — Intune/Graph remediation pairs, Azure Automation auth, Graph pointers (extends `_header/_logging/_graph` canonicals)
13. **`references/notification-patterns.md`** — Intune notification runbooks (extends `_graph-canonical.md`)
14. **`references/ad-patterns.md`** — Active Directory patterns
15. **`references/winrm-patterns.md`** — Multi-machine WinRM patterns
16. **`references/event-log-patterns.md`** — Windows Event Log patterns
17. **`references/macos-patterns.md`** — macOS bash script patterns
18. **`references/readme-template.md`** — Professional README.md template (4 variants, canonical for `SKILL.md` README section)
19. **`references/lessons-learned.md`** — Lessons Learned Register format, triggers, and worked example
20. **`references/advanced-capabilities.md`** — Communication Style + advanced scenarios (multi-window tools, REST API backends, self-updating tools, bulk operations, plugin architecture)
21. **`references/exe-packaging.md`** — Ship as .exe: PSWrap CodeDOM compilation, Authenticode signing, icon embedding, companion bundling, PSGallery publishing

---

## Related Skills

This skill encodes the **canonical enterprise design standard** for production-grade tools. It pairs with:

- **`powershell-expert`** — Use for general PowerShell best practices NOT covered here: deep `CmdletBinding` parameter sets, `ShouldProcess` (`-WhatIf`/`-Confirm`), `PSResourceGet`, Windows Forms for simple dialogs, Pester testing, live verification against PowerShell Gallery. The two skills are complementary: `powershell-expert` covers *how to write PowerShell well*, this skill covers *what every tool must look and behave like*.

---

## Success Metrics — How You Know It's Right

Every tool you build should hit these targets. If any metric is missed, fix it before shipping.

| Metric | Target | How to Verify |
|--------|--------|---------------|
| **XAML parse** | Zero errors on PS 5.1 | `XamlReader.Parse()` + `XmlNodeReader` + `XamlReader.Load()` |
| **Launch time** | < 3 seconds from double-click to visible window | Manual timing on a standard enterprise laptop |
| **Theme toggle** | 100% of controls respond to dark/light switch | Visual inspection — no control stays wrong-colored |
| **Hardcoded colors** | Zero hex colors in XAML outside of semantic constants | `grep -n '#[0-9A-Fa-f]\{6\}' MainWindow.xaml` returns nothing except `#3B82F6`, `#10B981`, `#EF4444`, `#F59E0B` |
| **Guard-Action coverage** | Every interactive button wrapped | `grep -c 'Guard-Action' tool.ps1` ≥ button count |
| **No MessageBox** | Zero `MessageBox.Show()` calls | `grep -c 'MessageBox' tool.ps1` = 0 |
| **No aliases** | Full cmdlet names only | `grep -nP '(?<![-\w])(gci\|select\|where\|ft\|fl\|%\|?)(?![-\w])' tool.ps1` = 0 — the lookarounds prevent false matches on `Select-Object`/`Where-Object` (the `-` after the alias word is not a word boundary) while still catching bare `gci`, `select`, `%`, `?` |
| **Error handling** | `$ErrorActionPreference = 'Stop'` at entry, no empty `catch {}` | Manual review |
| **Cleanup on close** | `Add_Closed` handler disposes jobs, log writers, runspaces | Manual review |
| **Single Add_Closing** | Exactly one `Add_Closing` handler per tool | `grep -c 'Add_Closing' tool.ps1` = 1 |

## Communication Style & Advanced Capabilities

Presentation principles (precise summaries, pattern references, honest trade-off flags) and advanced scenarios (multi-window tools, REST API backends, self-updating tools, bulk operations with progress, plugin architecture) live in **`references/advanced-capabilities.md`** - read it when delivering a finished tool or building one of those scenarios.
---

## Quick Recap

1. **Always copy the scaffold**, never write from scratch
2. **Follow the 12 Laws** — they prevent 100% of the recurring bugs
3. **Use the 21 patterns** — every one has been battle-tested
4. **Stick to Tailwind Slate tokens** — light/dark theme is automatic when you do
5. **Define all 19 required styles** in `Window.Resources` — never inline-style a Button
6. **One `Add_Closing` handler per tool** — never two
7. **Test XAML with `XamlReader.Parse()`** — catches Ampersand Law violations and StaticResource Law violations before ShowDialog
8. **Intune scripts follow enterprise standards** — structured headers, module checks, Graph pagination, paired remediation scripts
