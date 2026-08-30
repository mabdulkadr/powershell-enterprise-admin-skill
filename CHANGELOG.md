# Changelog

All notable changes to this project are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

---

## [Unreleased]

### Added

- **Empty-Message Spacer Rule** (Lesson 2026-08-30 Find-IntunePolicyConflict promoted to skill law): every logging helper (`Write-Log`, `Add-LogLine`, `Write-RemediationLog`, `Write-Toast`) declares `[Parameter(Mandatory = $false)] [AllowEmptyString()] [string]$Message = ""` plus an early-return guard, so visual spacers (`-Message ""`) no-op cleanly instead of crashing with `Cannot bind argument to parameter 'Message' because it is an empty string`. Documented in SKILL.md (Empty-Message Spacer Rule), `_logging-canonical.md`, and `references/pitfalls.md` (Pitfall 30).
- **Pitfall 30 gate** in `Test-ToolCompliance.ps1`: FAIL any local copy of a logging helper that still declares `[Parameter(Mandatory = $true)] [string]$Message`. Four checks per script (`Write-Log`, `Add-LogLine`, `Write-RemediationLog`, `Write-Toast`).

### Changed

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
- TOC anchor in SKILL.md #9 (`The Log Levels & UI Colors`) pointed at a slug that didn't match the heading (`The Log Levels (Exact Colors)`); fixed label and verified the other 12 TOC entries match their headings.

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
