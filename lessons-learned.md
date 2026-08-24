# Lessons Learned Register (Global)

This is the skill's single global register - it travels with the skill and applies to every script, tool, and project the skill touches. Project-local copies are no longer used.

> One entry per mistake, appended at the bottom.
> A lesson is only logged once - check existing entries and references/pitfalls.md before appending.

**Status: REGISTER RESET on 2026-08-24.** All 30 accumulated entries were reviewed,
promoted into the skill body (`references/pitfalls.md`, SKILL.md laws, templates),
and then cleared per owner decision - the skill evolves by absorbing its lessons,
not by hoarding them. The archive below records where each family of lessons now lives.

---

## How To Use This Register

1. **Before building:** read this file's tail. If a listed lesson applies to the current task, follow its rule.
2. **Append immediately** when any of these happens:
   - The user corrected your output (naming, structure, a rule you got wrong)
   - A delivered script crashed or failed at runtime (PS 5.1 incompatibility, XAML parse error, auth failure, culture-related date bug)
   - You hit a non-obvious pitfall not already in `references/pitfalls.md`
   - You discovered a new environment constraint (PS version, module availability, policy)
3. **Entry format:**

```markdown
## YYYY-MM-DD | <tool name> | <area>
- **Mistake:** what was done wrong
- **Cause:** why it happened
- **Fix:** what actually solved it
- **Rule:** the reusable rule, imperative
```

4. **Rules:** dedupe against this register and `references/pitfalls.md` before appending; entries are evidence-based (no speculation); one line per field.
5. **Promotion:** when a rule has proven itself twice, propose promoting it into `references/pitfalls.md` (ask the user), then log it in the Promotion Archive below.

---

## Promotion Archive

Everything learned before 2026-08-24 was absorbed into the skill body:

| Lesson family | Now encoded in |
|---|---|
| Test-Path ACL crash, BOM/ANSI reads, WhatIf logging leak, dot-source path crash, initial theme, HelpMessage attribute, array-preserve comma, Set-Theme indexer, bracket wildcard paths, handler closure scope, U+FEFF ghosts, -creplace, Parse-first loader, delivery hash baseline | `references/pitfalls.md` (Pitfalls 11-24 + inline sections) |
| RichTextBox LineBreak, DataGrid enterprise theme, premium HTML report, About dialog conciseness, DockPanel header rows, clipboard headless trap | `references/pitfalls.md` (XAML / Build Verification sections) |
| Canonical rich header + Get-Help trade-off, header spacing, `#Requires` order, banner for all CLI scripts | `references/_header-canonical.md`, HEADER LAW (SKILL.md) |
| English-only / no branding, report-path law | Laws 11 & 12 (SKILL.md) |
| README conditional sections, verbatim Disclaimer, variable header icons, template fidelity, centered hero + signature footer | `references/readme-template.md`, README templates |
| Template Lock (copy scaffold first), Fast Track delivery, Test-Delivery one-shot gate | SKILL.md workflow, `templates/`, `scripts/Test-Delivery.ps1` |
| Tier 3 modular guidance, gapfill-not-vendor rule | `references/file-architecture.md`, `references/advanced-capabilities.md` |
| Doc-drift discipline (Test-Skill + stale-count grep after structural change), SemVer + CHANGELOG, portable self-test paths | README Contributing, `CHANGELOG.md`, `scripts/Test-Skill.ps1` |
| External drift awareness (hash baseline CSV, behavior-vs-contract diff) | `baseline.csv` practice + Pitfall 24 |

---
