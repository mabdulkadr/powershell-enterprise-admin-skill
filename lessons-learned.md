# Lessons Learned Register (Global)

This is the skill's single global register - it travels with the skill and applies to every script, tool, and project the skill touches. Project-local copies are no longer used.

> One entry per mistake, appended at the bottom.
> A lesson is only logged once - check existing entries and references/pitfalls.md before appending.

## 2026-08-21 | Intune-Temp-Cleanup | filesystem-enumeration

- **Mistake:** Used `Test-Path` inside a `Where-Object` filter to probe user profile Temp folders; the detection script crashed with exit 2 ("Access is denied") on machines with ACL-protected profiles.
- **Cause:** `Test-Path` throws a terminating error (does not return `$false`) when the path's ACL denies traversal, and `$ErrorActionPreference = 'Stop'` escalates it into the outer catch.
- **Fix:** Wrapped each `Test-Path` probe in its own `try/catch [System.UnauthorizedAccessException]` inside `Get-TempTargets`, logging skipped profiles at DEBUG level.
- **Rule:** Never trust `Test-Path` to return `$false` on untrusted paths — always wrap probes of ACL-protected locations in try/catch when EAP is Stop.

## 2026-08-21 | powershell-enterprise-admin skill | documentation-standards

- **Mistake:** Delivered tools whose headers met structural rules but lacked operator-facing quality touches (parameter HelpMessage, intent-labeled examples, graceful-elevation notes, structured per-target results), and shipped READMEs without an as-is Disclaimer section.
- **Cause:** Treated documentation as structure compliance instead of an operator contract; the references had no explicit description-quality bar or disclaimer requirement.
- **Fix:** Added "Description & Comment Writing Standards" to references/script-template.md, CLI Script Traps (ShouldProcess('dummy') probe, mixed-enumeration double-delete) to references/pitfalls.md, Disclaimer section to all four readme-template.md variants, Disclaimer principle #9 to SKILL.md Key Principles, and pointer updates in the CLI workflow.
- **Rule:** Every header answers scope + safety guarantees + degradation behavior + output contract; every README carries the staging-test Disclaimer before License; never invent Graph permissions for local-only scripts.

## 2026-08-21 | skill-maintenance | ps51-verification-encoding

- **Mistake:** Verification grep reported 0 matches for a just-added emoji heading (`## ⚠ Disclaimer`) in a UTF-8 file, suggesting the edit had failed when it had actually succeeded.
- **Cause:** Windows PowerShell 5.1 `Get-Content -Raw` without `-Encoding UTF8` reads BOM-less UTF-8 as ANSI, mangling multi-byte characters so regexes against them never match.
- **Fix:** Re-checked with `Get-Content -Raw -Encoding UTF8`; all 4 occurrences were present.
- **Rule:** In PS 5.1 verification commands, always pass `-Encoding UTF8` when reading files that contain non-ASCII characters.

## 2026-08-21 | Clear-TempFiles + skill | script-file-order

- **Mistake:** Scripts opened with `#Requires -RunAsAdministrator` (and `#Requires -Version 5.1`) before the comment-based help block; the elevation requirement hard-failed unelevated runs before any logging or partial work.
- **Cause:** Followed the common "requires at top" habit instead of treating the help block as the file's opening contract.
- **Fix:** Reordered every script to open with the help block followed by `#Requires -Version 5.1`; removed `#Requires -RunAsAdministrator` everywhere and replaced it with a runtime `Test-IsElevated` check plus WARNING-level graceful degradation; updated HEADER LAW, Header Rules, the CLI/WPF/bootstrap templates, and the PS 5.1 detection wording in the references.
- **Rule:** The help/description block always opens a script; `#Requires -Version 5.1` comes immediately after it; `#Requires -RunAsAdministrator` is banned — elevation is detected at runtime.

## 2026-08-21 | Clear-TempFiles + skill | log-format-unification

- **Mistake:** The Type 3 CLI tool opened its console/log output with plain `[INFO] Starting...` while the Intune detect/remediate pair printed the `==== Solution | Mode ====` banner — inconsistent look across deliverables.
- **Cause:** `Write-Banner` was documented only as an Intune helper, so the general CLI template omitted it.
- **Fix:** Added the canonical `Write-Banner` + "Log file ready" DEBUG line to Clear-TempFiles.ps1 (banner title `Temp-Cleaner | Cleanup`); extended the CLI template (functions skeleton + MAIN block) and the SKILL.md Canonical Conventions logging row so every headless script type now opens with a banner.
- **Rule:** All console scripts open with: banner → "Log file ready" DEBUG → start message. Same shape regardless of Type 2 or Type 3.

## 2026-08-21 | Skill improvement | intuneautomation-header-standard

- **Mistake:** Skill headers were thin (indented `.SYNOPSIS/.DESCRIPTION/.EXAMPLE` only, or minimal `<#!` metadata) and the CHANGELOG guidance did not require documenting fixes with their cause.
- **Cause:** No canonical field order existed; each script type invented its own header shape.
- **Fix:** Adopted the Enterprise Standards standard (enterprise-standards/header-spec) as the single canonical header for ALL script types: `.TITLE .SYNOPSIS .DESCRIPTION .TAGS [.REMEDIATIONTYPE .PAIRSCRIPT] .PLATFORM [.MINROLE] .PERMISSIONS .AUTHOR .VERSION .CHANGELOG .LASTUPDATE .EXAMPLE(s) .NOTES`; plain `<#` everywhere; CHANGELOG newest-first documenting fixes with cause; applied to all delivered scripts and to script-template.md, file-architecture.md, intune-patterns.md, SKILL.md.
- **Rule:** One canonical rich header for every script type; pair fields after `.TAGS`; `.MINROLE` only for Graph/Intune tools; CHANGELOG explains fixes.

### Addendum: Get-Help trade-off (verified empirically)

Any unrecognized dotted keyword (.TITLE, .TAGS, ...) anywhere in a comment block makes Get-Help ignore the whole block. The canonical rich header therefore sacrifices Get-Help by design; documented in pitfalls.md so nobody "fixes" it later by deleting metadata.

## 2026-08-21 | Skill improvement | global-lessons-register

- **Mistake:** The Lessons Learned Register lived per-project at `<project>/.opencode/lessons-learned.md`, so lessons learned in one project never protected builds in another.
- **Cause:** The register was scoped to the working folder instead of traveling with the skill itself.
- **Fix:** Moved the register into the skill root (`<skill-dir>/lessons-learned.md`) as the single global register; updated SKILL.md, references/lessons-learned.md, README structure tree, and evals.json to read/append there; project-local copies discontinued.
- **Rule:** One global register inside the skill - read it before every build and append to it the moment a lesson is learned.

---

## 2026-08-21 | DeviceInfo-Suite | branding-and-language

- **Mistake:** Generated scripts and READMEs contained external branding `IntuneAutomation.com` in `.AUTHOR` and mixed Arabic/English text (Arabic in `.SYNOPSIS/.DESCRIPTION`, `HelpMessage`, log messages) despite enterprise standard requiring English-only output.
- **Cause:** Copied header template verbatim from external reference without stripping branding, and mirrored user's Arabic chat language into code/comments assuming localization was desired.
- **Fix:** Replaced all `IntuneAutomation.com` with generic `AI Generated` and internal references (`references/_header-canonical.md`); rewrote all headers, HelpMessages, and READMEs to 100% English; added LANGUAGE & BRANDING LAW (Law 11) to SKILL.md.
- **Rule:** Never emit external project branding or non-English text in generated scripts/docs; use generic `.AUTHOR AI Generated` and keep all output English-only unless user explicitly requests localization.

## 2026-08-21 | DeviceInfo-Suite | report-path-dot-source

- **Mistake:** `Get-DeviceInfo.ps1:62` used `Join-Path $PSScriptRoot "Reports"` as param default; when dot-sourced (`. '...\Get-DeviceInfo.ps1'`), `$PSScriptRoot` is empty and Join-Path crashed with `ParameterBindingValidationException`.
- **Cause:** Assumed `$PSScriptRoot` is always populated; did not handle dot-source case or enforce beside-script report location.
- **Fix:** Changed default to `$scriptBase = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path $PSCommandPath } ...` plus `if (-not $PSBoundParameters.ContainsKey('OutputPath')) { $OutputPath = Join-Path $scriptBase "Reports" }`; added REPORT PATH LAW (Law 12) and Pitfall entry with verification for `&`, `.\`, and dot-source from different `pwd`.
- **Rule:** Default Reports is always beside the original script via `$PSScriptRoot` with `$PSCommandPath`/`$MyInvocation` fallback and `PSBoundParameters` normalization; never use `".\Reports"` or `Get-Location` alone.

## 2026-08-21 | PSWrap GUI alignment | pswrap-full-architecture

- **Mistake:** GUI tools used only Tier 1 single-file here-string XAML and basic toast, while PSWrap (https://github.com/mabdulkadr/PSWrap) proved that complex GUI needs Tier 3 modular + embedded GZip+Base64 XAML, P/Invoke console-hide, and persistent settings — skill did not teach this as the canonical GUI reference.
- **Cause:** File-architecture.md described Tier 3 as "frameworks only" and patterns.md did not point to PSWrap's WpfHelpers/UiLoader/Settings implementations.
- **Fix:** Updated file-architecture.md Tier 3 to PSWrap reference (15-25 files, embedded XAML, AppConstants, UiLoader with fallback, Settings in %APPDATA%), added Hybrid decision guide (complex GUI → Tier 3 even for one audience), and marked PSWrap as canonical GUI in SKILL.md architecture table and reference list.
- **Rule:** For any GUI with 5+ features, drag-drop, bundling, or persistent settings, use PSWrap Tier 3 modular + embedded XAML; Tier 1 remains only for simple 2-3 button tools.

## 2026-08-21 | DeviceInfoViewer | initial-theme-not-applied

- **Mistake:** DeviceInfoViewer launched with a single flat color — navigation bar and cards indistinguishable — until Dark → Light toggle was pressed, after which colors appeared correctly.
- **Cause:** `Window.Resources` Tailwind Slate brushes were defined in XAML but `Set-Theme -IsDark $false` was never called on startup, so `DynamicResource` brushes remained frozen at XAML defaults until first toggle replaced them.
- **Fix:** Added immediate `Set-Theme -Window $Window -IsDark $false` plus Sun icon init right after `ConvertTo-XamlWindow` (PSWrap pattern); documented in file-architecture.md bootstrap and as Pitfall 14.
- **Rule:** Always initialize theme immediately after XAML load — before FindName and ShowDialog — with `$isDarkMode = $false` and Sun icon.

## 2026-08-21 | DeviceInfoViewer | about-dialog-staticresource

- **Mistake:** About dialog crashed with `Provide value on 'System.Windows.StaticResourceExtension' threw an exception` at `Style="{StaticResource BtnPrimary}"` because dialog XAML is parsed before `Window.Resources` are copied, so `StaticResource` is resolved too early.
- **Cause:** Used `StaticResource` in a child Window that inherits resources via post-parse copy; `StaticResource` requires the key at parse time, `DynamicResource` does not.
- **Fix:** Changed About dialog button from `Style="{StaticResource BtnPrimary}"` to inline `Background="{DynamicResource BtnPrimaryBg}" Foreground="White"` with explicit `ControlTemplate` (no StaticResource); verified with STA parse test.
- **Rule:** In child dialogs whose resources are copied after `XamlReader.Parse/Load`, never use `StaticResource` — use `DynamicResource` or inline template.

## 2026-08-21 | DeviceInfo-Suite docs | readme-icon-variable

- **Mistake:** All 4 READMEs used the same fixed header icon `🌐` (`# 🌐 DeviceInfoViewer...`) regardless of script type, making them indistinguishable in file listings.
- **Cause:** `references/readme-template.md` used `🌐` as the default for every template variant without noting it should vary.
- **Fix:** Assigned distinct icons per type (`💻 Standalone`, `🛡️ Intune`, `🖥️ GUI`, `📦 Suite`) and added Icon Policy to `readme-template.md` requiring variable icons.
- **Rule:** README header icon must be variable per script type/name — never reuse the same 🌐 for all.

## 2026-08-21 | DeviceInfoViewer | live-log-buttons-position

- **Mistake:** Live Log `Copy` and `Clear` buttons were adjacent on the left side of the header, not at the far right of the same row as the `Live Log` label.
- **Cause:** Used a plain `StackPanel` without `DockPanel LastChildFill="False"` — `DockPanel` default `LastChildFill="True"` caused the button container to stretch and sit next to the label instead of docking to the far right.
- **Fix:** Changed to `<DockPanel LastChildFill="False"><TextBlock DockPanel.Dock="Left"/><StackPanel DockPanel.Dock="Right">` with `Copy (BtnBlue)` and `Clear (BtnOutline)` on the far right of the same header row.
- **Rule:** Live Log header is always `DockPanel LastChildFill="False"` — label left, Copy+Clear right, same row.

## 2026-08-21 | DeviceInfoViewer | button-polish-and-nav-colors

- **Mistake:** All buttons used flat hover (`Opacity 0.85`) and navigation bar used subtle `SurfaceHoverBrush`/`AccentTintBrush` with low contrast; no shadow lift or accent border, so hover/active states were barely distinguishable.
- **Cause:** Copied PSWrap's base styles verbatim without enhancing for modern polish; active nav was low-contrast tint instead of vibrant accent.
- **Fix:** Polished `BtnBase` with `DropShadow` hover lift (`Blur 14 Opacity 0.09`), `NavBtnBase` hover to `AccentTintBrush` + `BorderHoverBrush` + blue glow, active nav to `AccentBrush` + White, `BottomActionBtn` hover to `AccentTintBrush` + blue glow, and `Card/StatCard` to `14/18` with hover lift.
- **Rule:** Every button must have a distinct hover (shadow/border) and active (vibrant) state; navigation active is always `AccentBrush` + White for maximum contrast.

## 2026-08-21 | DeviceInfo HTML report | html-beauty

- **Mistake:** HTML executive report used flat `Card`/`kpi-card` with plain `kpi-label/value` and light header, no hero, no icons, no dark-mode toggle, and no radial gradients — visually plain compared to WPF polish.
- **Cause:** Pattern U's CSS was minimal (`--bg #F1F5F9`, simple `.header`, no `hero`, no `kpi-icon`, no `data-theme` toggle).
- **Fix:** Replaced CSS with polished version: gradient `hero` (`#3B82F6→#8B5CF6`), `kpi-icon` circles (`cpu/ram/disk/uptime`), `hero` badges, `card` hover `translateY(-1px)`, `table-wrap` rounded, `search` with icon, `data-theme="dark"` toggle with `localStorage`, and print styles; updated KPI generation to include `kpi-icon` and `valueClass`.
- **Rule:** Every executive HTML report must use the polished hero + KPI-icon + dark-mode template (Pattern U) — never ship the minimal flat header.

## 2026-08-21 | Get-DeviceInfo HTML v2 | bom-in-spliced-function

- **Mistake:** After splicing a new HTML-report function (stored in a UTF-8-BOM temp file) into the main script via Python `read_text(encoding='utf-8')`, PowerShell threw `The term '?function' is not recognized` at runtime even though the Parser reported 0 errors.
- **Cause:** Python's utf-8 codec decodes a leading BOM as an invisible `U+FEFF` character that stayed glued to the inserted text; PS parsed `<U+FEFF>function Name {...}` as a command invocation named `?function`.
- **Fix:** After any programmatic splice, strip ALL `ï»¿` byte sequences then re-add exactly one at byte 0. Verify with AST ghost scan: `FindAll({$args[0] -is [CommandAst] -and $args[0].GetCommandName() -eq '?function'})` must return 0.
- **Rule:** Parse 0 errors does NOT catch invisible U+FEFF ghosts - always run the AST ghost-command scan after splicing code programmatically.

## 2026-08-22 | Skill maintenance | github-readiness-review

- **Mistake:** Full GitHub-readability review found doc drift: two broken TOC anchors in SKILL.md (`#intune-best-practices-type-2-scripts`, `#verification-checklist-run-before-returning` pointed at non-existent heading slugs); the reference list used `0.`-prefixed items that render inconsistently across markdown engines; README claimed "21 architecture & domain guides" while references/ holds 20 .md files; references tree box-drawing indentation drifted mid-block; README had no Table of Contents for its 340+ lines.
- **Cause:** Headings renamed during earlier restructures without re-generating TOC slugs; file counts quoted from memory instead of counted at publish time.
- **Fix:** Corrected both anchors to real heading slugs (`#intune-best-practices`, `#verification-checklist-before-first-run`); renumbered the reference library as one continuous 1-21 list (canonicals first); fixed the count to 20; normalized tree indentation; added a 3-column TOC grid under the badges.
- **Rule:** When renaming/moving headings, regenerate every TOC anchor in the same edit; quote directory file counts only after `Get-ChildItem | Measure`, never from memory; long READMEs ship with a TOC.



## 2026-08-22 | Skill maintenance | header-spacing-standard

- **Mistake:** The canonical template in `_header-canonical.md` showed one blank line between dotted fields, but all 13 shipped scripts used compact headers with fields back-to-back - two visual dialects of the same contract.
- **Cause:** Scripts predated the spaced template becoming the norm; nothing diffed shipped headers against the canonical example.
- **Fix:** Respaced every `scripts/*.ps1` header plus embedded templates in the references (exe-packaging.md) with an idempotent transform (insert blank line before each `^\.[A-Z]{2,}` field unless previous line is `<#` or already empty); documented the Spacing rule explicitly in `_header-canonical.md`, HEADER LAW, and the Canonical Conventions table; verified with Test-Skill (50/50) and the full compliance gate.
- **Rule:** One blank line between every dotted header field; first field sits directly under `<#`. When codifying a formatting rule, mechanically normalize existing artifacts in the same change - never rely on future edits to converge.

## 2026-08-22 | Skill maintenance | github-polish-pass

- **Mistake:** Repo lacked release history; canonical script versions mixed formats (`1.0` / `1.1` / `1.1.0`); Test-Skill's last-resort fallback hardcoded the install path `~/.config/opencode/skills/powershell-enterprise-admin`, breaking silently on any repo rename.
- **Cause:** Publishing artifacts (changelog, semver discipline, rename-safe paths) were never treated as deliverables alongside rules and references.
- **Fix:** Added root CHANGELOG.md (Keep a Changelog format); normalized versions to three-part SemVer with matching `.CHANGELOG` lines; rewrote the fallback to scan PWD then installed skills for a directory owning both `SKILL.md` and `scripts/Test-Skill.ps1`.
- **Rule:** Treat repo-publishing artifacts as part of definition-of-done: changelog updated on every structural change, SemVer everywhere, zero hardcoded install paths in self-tests.

## Promotion Log

Lessons promoted from this register into `references/pitfalls.md` (with user consent, 2026-08-21):

- **filesystem-enumeration** -> [Pitfall: Test-Path Throws on ACL-Protected Paths]
- **ps51-verification-encoding** -> [Pitfall: PS 5.1 Reads BOM-less UTF-8 as ANSI]
- WhatIf logging leak (found during WinTemp-Sweeper manual test) -> [Pitfall: WhatIf Propagates Into Logging Helpers] - also fixed in canonical `scripts/Write-Log.ps1` and `scripts/Add-LogLine.ps1` (`-WhatIf:$false` on all infrastructure writes)
- **report-path-dot-source** -> [Pitfall: $PSScriptRoot Is Empty When Dot-Sourced]
- **initial-theme-not-applied** -> [Pitfall: Initial Theme Not Applied — All-White Screen Until First Toggle]

## 2026-08-22 | Skill maintenance | doc-drift-cleanup

- **Mistake:** Full skill review found internal drift: SKILL.md TOC/Quick Recap/README said "10 Laws" while 12 existed; the Tier 1 bootstrap shipped a simplified Add-LogLine without $script:lastLogKey (tools built from it FAIL Test-ToolCompliance); stale "ring buffer/HashSet" descriptions contradicted the canonical lastLogKey guard; script-template.md log colors (INFO=White/DEBUG=Gray) diverged from canonical Cyan/DarkGray; the Detection template declared a Graph scope on a local-only script; SessionCard had no x:Key style; Embed-Xaml.ps1 was referenced but missing.
- **Cause:** Rapid skill evolution (10 to 12 laws, PSWrap adoption, WhatIf fixes) without a final consistency pass across SKILL.md + references + README.
- **Fix:** Unified all counts and anchors; replaced bootstrap Add-LogLine with verbatim-copy instruction; removed ring-buffer language everywhere; aligned color tables with _logging-canonical.md; fixed .PERMISSIONS/.AUTHOR in templates; converted SessionCard to Style x:Key; created scripts/Embed-Xaml.ps1; moved Advanced Capabilities + Communication Style to references/advanced-capabilities.md (SKILL.md now 536 lines); made Test-Skill.ps1 path fallback portable; fixed evals.json mojibake. Test-Skill: 50/50 PASS.
- **Rule:** After any structural skill change, run Test-Skill.ps1 AND grep for stale counts/names ("10 Laws", old function names) across SKILL.md + references/ + README.md before considering the change done.

## 2026-08-22 | Skill maintenance | foundation-gap-analysis

- **Mistake:** The skill cited PSWrap, Intune-Scripts, IntuneAutomation (ugurkocde), and DeviceOffboardingManager as foundations without auditing that their features were actually captured: compile-to-exe (PSWrap's core purpose), Authenticode signing, Intune Custom Compliance JSON contract, government cloud Graph endpoints, and PSGallery publishing were all absent.
- **Cause:** Patterns were distilled from scripts the author had already internalized; capabilities living in tool form (compiler GUI, cert folder) rather than script patterns escaped extraction.
- **Fix:** Added references/exe-packaging.md (CodeDOM EXE, signing with timestamp, icon conversion, companion bundling, PSGallery Install-Script flow); Custom Compliance Policies section in intune-patterns.md (single-line JSON contract, Compliant boolean, exit semantics); Government Clouds endpoint table in _graph-canonical.md; .github/workflows CI running Test-Skill + compliance gate on push/PR.
- **Rule:** When citing a project as canonical source, diff its README/feature list against the skill's coverage before calling the distillation complete - features embodied in tools (not scripts) are the ones most likely to be missed.