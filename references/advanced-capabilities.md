# Advanced Capabilities & Communication Style

> Moved out of `SKILL.md` to keep it lean. Read this file when delivering a finished tool or when building one of these scenarios.

---

## Communication Style — How to Present Your Work

When building tools for the user, follow these principles:

- **Be precise**: "Here's your tool — all 12 laws applied, Pattern H on every button." Don't say "I made some changes."
- **Reference specific patterns**: "The Add-LogLine consecutive-duplicate guard prevents repeated log lines from flooding the log." The user doesn't need to remember pattern letters, but naming them builds trust.
- **Show the why**: "This XAML violates Law 5 — hardcoded `#F6F8FB` breaks dark mode. Replaced with `{DynamicResource BackgroundBrush}`."
- **Lead with the architecture choice**: "This is a Tier 1 tool (single-file) because it's one workflow for one audience. Here's the decision tree if you want to promote later."
- **Flag trade-offs honestly**: "I used `Start-Job` for the CIM query (Pattern B) — it's simpler than runspace but has a 1-2s startup overhead. If that matters, I'll switch to Pattern C."
- **For Intune scripts**: Always mention the remediation pair strategy — detection + remediation as separate scripts with matching exit codes.

---

## Multi-Window Tools

When a tool needs multiple windows (e.g., main dashboard + settings dialog + log viewer):
- Each child window gets its own XAML here-string or `.xaml` file
- Theme tokens propagate via Pattern E (LogViewer Theme Copy)
- Only ONE `Add_Closing` handler on the main window — children close via `$dialog.Close()`
- Child windows use `Owner = $script:Window` for correct Z-order

## Tools with REST API Backends

Some admin tools need to call external APIs (Graph, custom REST services):
- Use `Invoke-RestMethod` inside `Start-Job` (Pattern B) — never on the UI thread
- Parse responses with `-Depth` on `ConvertTo-Json`/`ConvertFrom-Json` to avoid truncation
- Show API status in the ConnectionDot (green = connected, red = failed, yellow = degraded)
- Implement retry with exponential backoff in the job script block

## Tools That Self-Update

Enterprise tools sometimes need auto-update capability:
- Check a version endpoint on launch (non-blocking, Pattern B)
- Compare `[version]` objects, not strings
- Download to a temp folder, then `Move-Item` atomically — never overwrite a running `.ps1`
- Show update status in the StatusBar, not a modal dialog

## Bulk Operations with Progress

When processing hundreds or thousands of items (CSV-driven bulk AD operations):
- Process in batches of 50-100 to avoid CIM/AD throttling
- Use `Write-Progress` inside the job + `DispatcherTimer` polling for the progress bar
- Implement a cancel flag (`$script:isCancelled`) that the job checks between batches
- Log successes and failures separately — don't mix them in one stream

## Intune Proactive Remediation Pairs & Notification Scripts

**Only for Type 2 (Intune/Graph).** General CLI (Type 3) does NOT use these.

- **Canonical:** `intune-patterns.md` (pairs, validation, Graph retry + 403, always-run) + `notification-patterns.md` (runbooks, HTML email) + `_graph-canonical.md` + `_logging-canonical.md`
- **Pairs:** detection (`0`=compliant / `1`=non-compliant / `2`=error) + remediation (`0`=success / `1`=failure / `2`=error), both carry `.REMEDIATIONTYPE` + `.PAIRSCRIPT`, naming `detect-<name>.ps1` / `remediate-<name>.ps1`, idempotent detection, per-target `$failedCount` tracking, `Wait-Process -Timeout`, report space freed/items processed.
- **Helpers (scripts/Write-Log.ps1):** `Initialize-Log` (`<SystemDrive>\IntuneLogs\`), `Write-Banner`, `Write-Log`, `Finish-Script`
- **Notifications:** header `.EXECUTION RunbookOnly` + `.OUTPUT Email` + `.SCHEDULE`, `saveToSentItems=$false`, context `$IsAzureAutomation` (`$PSPrivateMetadata.JobId.Guid`), boolean params as `[string]` with `ValidateSet("true","false","1","0")`.

## macOS Enterprise Scripts

**Type 3 (General CLI) scripts.** When building bash scripts for macOS management:
- Use `macos-patterns.md` for the canonical header and patterns.
- Check for root privileges with `[[ $EUID -ne 0 ]]` **before** executing — on failure log the error and `exit 1` (never `exit 0`; a success exit on failure makes Intune/operators believe the script succeeded).
- Use `defaults read/write` and `PlistBuddy` for plist operations, not raw file editing.
- Log to `/var/log/` with the structured `[timestamp] [LEVEL] message` format matching the PowerShell logging standard.
- **Intune custom attributes are a special output mode, not a separate script type:** the script prints ONE line as the result and `exit 0`. Only scripts explicitly requested as custom attributes use this mode — standard macOS scripts use `log_message` + `exit 1` on failure.

## Plugin / Extension Points

**Only for Type 1 (WPF GUI) tools.** General CLI scripts and Intune scripts do NOT use plugin architecture.
For frameworks (Tier 3) that need extensibility:
- Define a `$script:plugins = @()` array
- Each plugin is a hashtable with `Name`, `Version`, `Init`, `Execute` keys
- Load plugins from a `plugins/` folder at startup
- Wrap plugin calls in `try/catch` — a broken plugin must not crash the tool
