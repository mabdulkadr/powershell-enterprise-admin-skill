# Canonical Logging — Single Source of Truth

> **DO NOT DUPLICATE.** Copy implementations verbatim from `scripts/` — never retype.

## One Logger Per Context

| Context | Script | Functions | Log Path |
|---------|--------|-----------|----------|
| WPF GUI (Type 1) | `scripts/Add-LogLine.ps1` | `Add-LogLine` | `%LOCALAPPDATA%\<ToolName>\Logs\` |
| CLI (Type 2 Intune + Type 3 General) | `scripts/Write-Log.ps1` | `Initialize-Log`, `Write-Log`, `Finish-Script`, `Write-Banner` | Intune: `<SystemDrive>\IntuneLogs\<SolutionName>\` — General: `C:\ProgramData\<ToolName>\Logs\` |

- Default for `Initialize-Log` is `-Type General`. Intune scripts must pass `-Type Intune` explicitly.
- All infrastructure writes use `-WhatIf:$false` to avoid WhatIf leak (see `pitfalls.md`).

## Usage

```powershell
# GUI
Add-LogLine -Message "Backup complete" -Level "SUCCESS"

# CLI
Initialize-Log -SolutionName "MyTool" -Type General
Write-Banner
Write-Log "Starting MyTool v1.0" "INFO"
Write-Log "Done" "SUCCESS"
Finish-Script -ExitCode 0 -Message "Success" -Level "SUCCESS"
```

## Deduplication

Consecutive-duplicate guard via `$script:lastLogKey` — drops immediate duplicate `Level|Message` only. Not a full `HashSet`.

## Levels & Colors (fixed, identical in console + GUI MessageCenter)

| Level | Console | Hex |
|-------|---------|-----|
| DEBUG | DarkGray | `#94A3B8` |
| INFO | Cyan | `#3B82F6` |
| SUCCESS | Green | `#10B981` |
| WARNING | Yellow | `#F59E0B` |
| ERROR | Red | `#EF4444` |

Level set is exactly `INFO, SUCCESS, WARNING, ERROR, DEBUG` — no `DIVIDER`.

## Empty-Message Spacer Rule (Pitfall 30)

Callers commonly use `Write-Log -Message ""` or `Add-LogLine -Message ""` as a
visual spacer between sections. PowerShell's `[Parameter(Mandatory = $true)]`
treats an empty string as a missing value, so a Mandatory `Message` crashes
the FIRST spacer line before any real content reaches the log. Every logging
helper in this skill declares:

```powershell
[Parameter(Mandatory = $false)]
[AllowEmptyString()]
[string]$Message = "",
...
if ([string]::IsNullOrEmpty($Message)) { return }
```

`Finish-Script -Message` stays Mandatory (it is a true summary line, never a
spacer). This is enforced by `Test-ToolCompliance.ps1` (Pitfall 30 gate).

## Rules

- CLI scripts use `Write-Log`, never `Add-LogLine`.
- Every exit path uses `Finish-Script` (Intune) or explicit `Write-Log` + `exit`.
- `Get-Content -Raw -Encoding UTF8` when reading logs on PS 5.1 (see `lessons-learned.md` ps51-verification-encoding).
- `Message` parameter is **non-Mandatory + AllowEmptyString + default "" + early-return** — see Empty-Message Spacer Rule above.
