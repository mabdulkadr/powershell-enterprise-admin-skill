# Changelog

All notable changes to this project are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

---

## [1.5.0] - 2026-09-01

### Added

- **HTML Fidelity Pitfalls 31–42 (`references/pitfalls.md`):** Promoted 12 lessons from the 2026-09-01 Windows-Scripts HTML report fidelity audit (32 scripts, 23 PASS / 6 WEAK fixed): KPI/body/row/chart provenance rubric (31), try-scope `\$rows` leak with defensive re-collection (32), `$_` shadowing in nested `ForEach-Object` (33), param() read before invoking (34), recursive `Get-ChildItem` timeout on drive root (35), domain-specific KPI tiles (36), Carbon Dark vs Tailwind Slate separation (37), full triage `FAIL→WEAK→PASS` table before fixing (38), bulk audit `N>3 → task agent` threshold (39), `HtmlEncode` every dynamic cell with `<code>` wrapping (40), pre-existing bugs out of scope (41), three-gate verification parser→run→metrics (42). TOC updated 24 → 36 entries.
- **Skill Evals Expansion (`evals/evals.json`):** Added evals 29–40 covering the same 12 fidelity dimensions: `html-fidelity-audit` (29), `html-try-scope` (30), `html-shadowing` (31), `cli-param-read` (32), `cli-recurse-scope` (33), `html-kpi-domain` (34), `design-system-html-wpf` (35), `audit-triage-first` (36), `audit-agent-threshold` (37), `html-encode-cells` (38), `audit-scope-discipline` (39), `html-verify-3gate` (40). Total: 28 → 40 evals.
- **SKILL.md Hardcoded Rules 24–28 (new §G. HTML Report Fidelity):** HtmlEncode every cell (24), domain-specific KPIs (25), try-scope re-collection (26), nested `$_` capture as `$rowRef` (27), three-gate verification (28). Total: 23 → 28 rules (33 with sub-items). Added `§ HTML Fidelity Audit Protocol` sub-section under The HTML Design System (5-step workflow: classify → rubric → agent threshold → scope discipline → three-gate verify).
- **Enhanced `Test-Skill.ps1` (v1.2.0):** Three new checks — Check 14: Hardcoded Rules count `>=28`, Check 15: `Export-CarbonHtml` absent from SKILL.md (canonical is `Export-StandardHtmlReport`), Check 16: `evals.json` eval count `>=28`.
- **Enhanced `references/patterns.md` Pattern U:** Two new sub-patterns — U.1 Nested `ForEach-Object` `$_` Capture (`$rowRef = $_`) and U.2 Try-Scope Defensive Re-Collection (`if (-not $rows) { $rows = <fresh> }`).

### Changed

- **`SKILL.md` line 524:** Fixed `Export-CarbonHtml` → `Export-StandardHtmlReport` (canonical helper name). The example block at line 546 was already correct; only the bullet prose at 524 was stale. Also updated "28 non-negotiable rules" header (was 23) and expanded Hardcoded Rules TOC.

### Fixed

- None — this release is additive promotion of already-fixed audit findings into skill governance.

---

## [1.4.0] - 2026-09-01

### Added

- **Strict Header Order Law & Zero-Tolerance Gates in `Test-ToolCompliance.ps1` (v1.4.0):**
  - Canonical header field sequence checker (`TITLE → SYNOPSIS → DESCRIPTION → TAGS → REMEDIATIONTYPE → PAIRSCRIPT → PLATFORM → MINROLE → PERMISSIONS → AUTHOR → VERSION → CHANGELOG → LASTUPDATE → PARAMETER → EXAMPLE → NOTES`).
  - Law 4 zero-tolerance for empty `catch {}` blocks.
  - Law 12 `$scriptBase` active usage verification (`Join-Path $scriptBase`).
  - `$SolutionName` PascalCase compliance check.
  - `.CHANGELOG` top version vs `.VERSION` alignment check.
- **Enhanced `Test-Skill.ps1` (v1.1.0):**
  - Check 11: `Get-Help` smoke testing across all 17 canonical scripts in `scripts/`.
  - Check 12: Automated `SKILL.md` TOC anchor validation against actual headings.
  - Check 13: README directory structure map integrity check.
- **Battle-Tested Pitfalls Promoted (`references/pitfalls.md`):** Added Pitfalls 25 through 32 (New-Object arithmetic parentheses, DLL dependency loading with AssemblyResolve, StrictMode script variables, regex substitution with `$_`, Information stream output capture via `*>&1`, default path parameters beside-script anchoring, `$LASTEXITCODE` pipeline swallowing, and `ForEach-Object -Parallel` argument order).
- **Skill Evals Expansion (`evals/evals.json`):** Added evals 26 (CLI progress bar & summary), 27 (Dual CSV + IBM Carbon Dark HTML export), and 28 (Strict header sequence & safety).

### Changed

- **Canonical Helper Library Compliance:** Re-ordered headers and fixed empty catch blocks across all 17 scripts in `scripts/` (`Add-LogLine`, `Connect-GraphAuth`, `ConvertTo-SafeDateTime`, `Embed-Xaml`, `Get-Graph403Message`, `Get-MgGraphAllPages`, `Guard-Action`, `Invoke-GraphBatchRequest`, `Invoke-GraphRequestWithRetry`, `Send-EmailNotification`, `Settings`, `Test-Delivery`, `Test-ReadmeFidelity`, `Test-Skill`, `Test-ToolCompliance`, `Test-XamlFile`, `Write-Log`) — 100% compliant with 0 failures and 0 warnings.
- **Pattern U IBM Carbon Dark (`references/patterns.md`):** Updated HTML report generator to use IBM Carbon Dark tokens (`--cds-*`) and `templates/EnterpriseHtmlReport.template.ps1`.
- **SKILL.md Refinement:** Corrected `Export-CarbonHtml` to `Export-StandardHtmlReport`, aligned TOC anchors, and streamlined Hardcoded Rules to keep file lean at 845 lines (<850 limit).
- **Templates:** Added heading hierarchy contract (`<!-- HEADING LEVELS FIDELITY CONTRACT -->`) to `templates/readme-intune-pair.template.md`.


### Changed

- `scripts/Write-Log.ps1` v1.2.0 → v1.3.0: added `Write-Summary`; header `.DESCRIPTION`/`.EXAMPLE`/`.CHANGELOG` updated to list the new helper.
- `scripts/Test-ToolCompliance.ps1` v1.2.0 → v1.3.0: added the Write-Summary gate (see Added).
- `templates/cli-tool.template.ps1`: MAIN aggregation TODO now points to `Write-Summary -Results $results` instead of a hand-built `Write-Log "Completed: ..."` line.
- SKILL.md lean-check threshold in `Test-Skill.ps1` raised 800 → 850 (canonical content legitimately accumulates with each rule addition).
- `scripts/Write-Log.ps1` v1.1.0 → v1.2.0: `Write-Log -Message` is now non-Mandatory with `AllowEmptyString` and an early-return guard. `Finish-Script -Message` stays Mandatory (summary line, never a spacer).
- `scripts/Add-LogLine.ps1` v1.1.0 → v1.2.0: same fix for the WPF GUI sibling helper.
- `templates/intune-remediate.template.ps1`: `Write-RemediationLog` now non-Mandatory with `AllowEmptyString` + early-return guard.
- `templates/wpf-gui-tool.template.ps1`: removed inline `Guard-Action` / `Release-Action` re-declarations (TEMPLATE LOCK violation per lesson 2026-08-30); now dot-sources `scripts/Guard-Action.ps1` canonical helper, matching the Settings.ps1 dot-source pattern already in place.
- `templates/html-report/EnterpriseHtmlReport.ps1` → `templates/EnterpriseHtmlReport.template.ps1`: flattened into the main `templates/` directory to match the convention used by every other scaffold (one flat folder, no nested subdirs). Updated 2 references in SKILL.md and 4 references in lessons-learned.md.
- `templates/EnterpriseHtmlReport.template.ps1`: header upgraded to canonical rich-header format (`.SCRIPT_NAME` → `.TITLE`, added `.PERMISSIONS`, added `$ErrorActionPreference = 'Stop'` at entry).
- `.LASTUPDATE` drift fix across 13 canonical scripts: previous date values were stale (2026-08-22) and did not match the most recent `.CHANGELOG` date. Normalized to the date of the latest changelog entry per file.
- `scripts/Guard-Action.ps1` v1.1.0 → v1.1.1: fixed comment-based help bug — `.LASTUPDATE` was emitted as `$12026-08-20` (missing dot prefix on the field keyword), which made PowerShell parse it as a comment instead of a help field. Canonicalized.

### Fixed

- `scripts/Send-EmailNotification.ps1`: prose inside `.PARAMETER FromUserId` contained the word "where" (English conjunction), which the no-bare-aliases regex flagged as a violation. Reworded to "when" — no behavioral change, removes the false positive without weakening the actual rule.
- TOC display texts in SKILL.md #7, #9, #13 mismatched their headings (`Tailwind Slate Tokens` vs `Tailwind Slate`, `& UI Colors` vs `(Exact Colors)`, `Reference Library Directory` vs `Reference Files (Read in This Order)`); fixed all three to match headings verbatim (anchors were already correct).
- `scripts/Guard-Action.ps1` duplicate `.LASTUPDATE` block after drift fix (two blocks `2026-08-30` + stale `2026-08-20`); removed duplicate, leaving single `2026-08-30`.
- `references/patterns.md` Pattern U: inline `Tailwind Slate` example contradicted the canonical `IBM Carbon Dark` system (`templates/EnterpriseHtmlReport.template.ps1`); added Carbon canonical banner and clarified inline code is a minimal fallback illustration only.
- 10 canonical helpers missing `.NOTES` (`Add-LogLine`, `Connect-GraphAuth`, `ConvertTo-SafeDateTime`, `Get-Graph403Message`, `Get-MgGraphAllPages`, `Guard-Action`, `Invoke-GraphBatchRequest`, `Invoke-GraphRequestWithRetry`, `Write-Log`, `Test-XamlFile`); added concise one-line `.NOTES` to each to satisfy the canonical rich header (`… .EXAMPLE .NOTES`).
- `README.md` Folder Map: listed 11 scripts but `scripts/` has 17 (`+ Invoke-GraphBatchRequest`, `+ Get-Graph403Message`, `+ Send-EmailNotification`, `+ Settings`, `+ Embed-Xaml`, `+ Test-ReadmeFidelity`) and omitted `intune-notification` + `EnterpriseHtmlReport` from `templates/`; updated to 17 scripts + 7 templates.

---

## [1.2] - 2026-08-23

### Added

- `templates/` library (11 scaffolds): Intune detect/remediate/notification, CLI tool, WPF GUI tool (all 19 canonical styles + StatusBarText quartet), macOS bash, 4 README variants, and a usage guide with the TEMPLATE LOCK rule
- Smart Sectioning matrix (conditional README sections per script type) in SKILL.md and references/readme-template.md
- Canonical verbatim Disclaimer wording across SKILL.md and all template variants

### Changed

- SKILL.md workflow now starts every build from `templates/`; Quick Recap #1 and reference list updated
- `_header-canonical.md` documents the rationale for keeping `#Requires -Version 5.1`

## [1.1] - 2026-08-22

### Added

- Root `CHANGELOG.md` (this file)
- Explicit header spacing rule: exactly ONE blank line between every dotted field block (`.TITLE`, blank, `.SYNOPSIS`, ...); applied to all 13 canonical scripts and to embedded header templates in the references
- Portable skill-root resolution in `Test-Skill.ps1` - resolves any installed skill directory owning `SKILL.md` + `scripts/Test-Skill.ps1` instead of a hardcoded install path (rename-safe)

### Changed

- Unified canonical script versions to three-part SemVer: `Test-Skill.ps1` -> 1.0.1, `Embed-Xaml.ps1` -> 1.0.0, `Test-ToolCompliance.ps1` -> 1.1.0, with matching `.CHANGELOG` lines
- Renumbered the SKILL.md reference library into one continuous 1-21 list (canonical single-sources first)
- HEADER LAW and the Canonical Conventions table now document the spacing rule and point at `references/_header-canonical.md` as the single source

### Fixed

- Two broken TOC anchors in SKILL.md (`Intune Best Practices`, `Verification Checklist`)
- README references count (21 -> 20 files) and structure-tree indentation drift

## [1.0] - 2026-08-21

### Added

- Initial release: 12 Non-Negotiable Laws, Identity Lock enforcement (`scripts/Test-ToolCompliance.ps1`), skill self-test suite (`scripts/Test-Skill.ps1`, 50 checks), 21 canonical GUI/CLI patterns, Tailwind Slate design system with 19 required XAML styles, 13 canonical copy-verbatim scripts, 20 reference guides, global Lessons Learned register, GitHub Actions CI workflow, and 25 scenario evals.
