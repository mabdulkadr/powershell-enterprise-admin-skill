# Changelog

All notable changes to this project are documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
