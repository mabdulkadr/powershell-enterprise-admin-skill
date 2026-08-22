# Canonical Header — Single Source of Truth

> **DO NOT DUPLICATE THIS CONTENT.** All other files must reference this file.
> If header order changes, edit **only** this file. This is the canonical Enterprise Standards standard adopted for ALL script types.

## Field Order (ALL types)

```
.TITLE → .SYNOPSIS → .DESCRIPTION → .TAGS → [.REMEDIATIONTYPE → .PAIRSCRIPT] → .PLATFORM → [.MINROLE] → .PERMISSIONS → .AUTHOR → .VERSION → .CHANGELOG → .LASTUPDATE → .EXAMPLE(s) → .NOTES
```

**Spacing rule:** every dotted field block is separated from the next by exactly ONE blank line (`.TITLE`, blank line, `.SYNOPSIS`, ...). The first field starts directly after `<#` with no blank line. This applies to every script and every template that mirrors this file.

- `.REMEDIATIONTYPE` + `.PAIRSCRIPT` only for Intune pairs (`detect-*` / `remediate-*`).
- `.MINROLE` only for Graph/Intune tools.
- `.PERMISSIONS` = real Graph scopes or `None (local SYSTEM context)` for local-only scripts. Never invent scopes.
- `.CHANGELOG` is newest-first and documents FIXES with cause.

## Canonical Header Template

```powershell
<#
.TITLE
    [ToolName Mode - Brief purpose]

.SYNOPSIS
    [One line <100 chars]

.DESCRIPTION
    Scope + safety guarantees + degradation behavior + output contract (see script-template.md § Description & Comment Writing Standards).

.TAGS
    [Category], [Subcategory]

.PLATFORM
    Windows

.PERMISSIONS
    [e.g., DeviceManagementManagedDevices.Read.All  or  None (local SYSTEM context)]

.AUTHOR
    AI Generated

.VERSION
    1.0.0

.CHANGELOG
    1.0.0 (YYYY-MM-DD)
    - Initial release

.LASTUPDATE
    YYYY-MM-DD

.EXAMPLE
    .\ToolName.ps1 -Param "Value"
    What this does (intent, not syntax restatement).

.NOTES
    - Execution context / elevation behavior
    - Exit codes
    - Log path
    - Skip/locked-file behavior
#>

#Requires -Version 5.1
```

## File Order Rule

1. `<# help block #>` — ALWAYS FIRST
2. `#Requires -Version 5.1` — immediately after, never before, never elsewhere
3. Configuration / Functions / Main

Never `#Requires -RunAsAdministrator`. Detect at runtime with `Test-IsElevated` and degrade gracefully (WARNING log + skip).

## References

- Full rules + examples: `script-template.md` (Script Header section)
- Intune pair fields: `intune-patterns.md` (Script Header Format)
- Bootstrap placement: `file-architecture.md` (Tier 1 bootstrap)
