<div align="center">

# ⚡ PowerShell Enterprise Admin Skill

**Turn any AI agent into a senior PowerShell architect.**

One standard. Every tool looks, runs, and logs the same way — production-grade, every time.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11%20-0F172A?style=for-the-badge)](#-works-on)
[![UI](https://img.shields.io/badge/UI-WPF%20Tailwind%20Slate-3B82F6?style=for-the-badge&logo=windows&logoColor=white)](#-design-system)
[![Theme](https://img.shields.io/badge/Theme-Light%20%2F%20Dark-8B5CF6?style=for-the-badge)](#-design-system)
[![Evals](https://img.shields.io/badge/Evals-40%20Scenarios-10B981?style=for-the-badge)](#-test-everything)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge)](#-license)
[![Version](https://img.shields.io/badge/Version-1.5.0-334155?style=for-the-badge)](CHANGELOG.md)

[How It Works](#-how-it-works) • [Quick Start](#-quick-start) • [12 Laws](#-the-12-laws) • [Design System](#-design-system) • [Examples & Use Cases](#-examples--use-cases--real-prompts-real-tools) • [FAQ](#-faq)

</div>

---

## 📖 Overview

### What is a "skill"?

A skill is a folder of instructions that you give to an AI coding agent (OpenCode, Claude Code, Cursor, Copilot...). When the skill is loaded, the agent stops writing PowerShell its own way — and starts writing it **this way**: the enterprise way, every single time.

### What problem does it solve?

AI agents write working code — but every script looks different. One uses aliases, one forgets error handling, one hardcodes colors so dark mode breaks, one freezes the window during long queries. Individually they work; together they look like five different teams wrote them.

This skill fixes that. It gives the agent:

* **Laws** — 12 non-negotiable rules (and *why* each exists)
* **Templates** — ready-made starting files to copy from
* **Patterns** — 21 proven solutions for common problems (theme toggle, async loading, logging...)
* **Tests** — automated scripts that *prove* the output is compliant

| Without this skill | With this skill |
| :--- | :--- |
| Headers missing → no help available | One rich header on every file |
| Hardcoded colors → dark mode breaks | Theme tokens — toggle always works |
| Frozen window during long queries | Async jobs — UI never blocks |
| Icons show as empty boxes on servers | SVG paths — render everywhere |
| Each tool invented its own names | Fixed names, enforced by an automated gate |
| Logs scattered in random folders | One known log path per tool type |

> **Simple rule:** if it fails the test script, it doesn't ship.

---

## 🔄 How It Works

When you ask for something, the agent first asks itself one question: **what kind of deliverable is this?** Then it follows the matching recipe.

| Type | You Ask For... | The Agent Builds | Example Prompt |
| :--- | :--- | :--- | :--- |
| **Type 1 — WPF GUI Tool** | Dashboard, helpdesk tool, DataGrid UI | A full desktop app with sidebar, dark/light theme, async loading, live log console | *"Build me a WPF tool to manage AD users"* |
| **Type 2 — Intune Script** | Detection, remediation, compliance, Graph API | Paired detect/remediate scripts with correct exit codes and Intune headers | *"Create a remediation pair that disables TLS 1.0"* |
| **Type 3 — Enterprise CLI** | AD bulk ops, WinRM, event logs, printers, macOS bash | A clean command-line tool with structured logging and exit codes | *"Find inactive AD accounts older than 90 days"* |
| **Type 4 — Documentation** | README, docs | A professional README with badges, tables, and disclaimer | *"Write a README for this tool"* |

After picking the type, the build always follows the same pipeline:

```text
Your request → Classify type → Copy template → Fill placeholders
            → Apply 12 laws + patterns → Run quality gate → Ship ✅
```

> **Why classify first?** Because a GUI tool and an Intune remediation have completely different rules — exit codes, headers, log locations. Picking the wrong recipe is how broken tools get shipped.

---

## ✨ What You Get

* 🖥️ **WPF GUI tools**
  Tailwind Slate design language, dark/light theme toggle that always works, background jobs so the window never freezes, a live color-coded log terminal, and themed DataGrids.

* ☁️ **Intune & Graph automation**
  Detection/remediation pairs that are idempotent (safe to run twice), truthful permission declarations, automatic pagination and retry for Graph API calls, and Managed Identity support for Azure Automation runbooks.

* 🏢 **Enterprise CLIs**
  Active Directory bulk operations with culture-safe dates, WinRM fan-out across many servers with throttling, fast event-log queries using filters (not slow `Where-Object`), and printer management via AD + CIM.

* 🍎 **macOS bash scripts**
  Intune-ready shell scripts with root checks, structured `logger` output, and the same exit-code discipline as Windows tools.

* 📦 **Packaging**
  Compile `.ps1` into a standalone `.exe`, embed icons, Authenticode signing with timestamp, and publish to PSGallery.

* 📚 **Documentation**
  Professional README files with shields.io badges, exit-code tables, and disclaimers — generated from templates, never from scratch.

* 🧪 **Quality gates**
  Automated tests parse the XAML, check naming drift, and smoke-test on real Windows PowerShell 5.1 — before anything ships.

---

## 🚀 Quick Start

From zero to a working tool in about two minutes. Five steps, copy-paste ready.

---

### Step 1 — Install the skill

Pick the agent and run the matching command from a PowerShell prompt in the skill folder:

| Agent | Install Command | Install Path |
|:------| :--- | :--- |
| **OpenCode** (global) | `Copy-Item -Recurse .\powershell-enterprise-admin "$env:USERPROFILE\.config\opencode\skills\"` | `%USERPROFILE%\.config\opencode\skills\powershell-enterprise-admin\` |
| **OpenCode** (project) | `Copy-Item -Recurse .\powershell-enterprise-admin ".\.opencode\skills\"` | `.\.opencode\skills\powershell-enterprise-admin\` |
| **Claude Code** | `Copy-Item -Recurse .\powershell-enterprise-admin "$env:USERPROFILE\.claude\skills\"` | `~/.claude/skills/powershell-enterprise-admin/` |
| **Cursor** | `Copy-Item -Recurse .\powershell-enterprise-admin ".\.cursor\skills\"` | `.\.cursor\skills\powershell-enterprise-admin\` |
| **Windsurf / Continue / Cline** | Copy the folder into the agent's skills directory | Varies — see agent docs |
| **Any other agent** | Copy the folder to your agent's skills directory and point instructions at `SKILL.md` | — |

> **Tip:** For OpenCode, prefer the *global* install so every project in your workspace inherits the skill without re-copying.

---

### Step 2 — Verify the install (one command)

The skill ships with a self-test that confirms your copy is complete and the templates still pass the canonical gate:

```powershell
# Default: tests in place (no install required)
.\scripts\Test-Skill.ps1

# OR install the scripts to your PATH so they're available globally
.\scripts\Install-Skill.ps1
Test-Skill
```

**Expected output** (last few lines):

```text
[PASS] 99/99 self-checks passed
[PASS] Test-ToolCompliance.ps1 — zero FAIL on all 8 templates
[PASS] Test-ReadmeFidelity.ps1 — all README templates faithful
```

If you see any `FAIL`, re-download the skill — a file was corrupted in transit. The self-test never modifies your files; it only reads.

---

### Step 3 — Restart your agent and ask

The skill is loaded into your agent's context on startup. **Restart the agent** (close and reopen the chat) so the new skill triggers.

Then ask naturally. No special commands. No keywords to memorize. Just describe what you need the way you'd tell a colleague.

**First example — try this exact prompt right now:**

> *"Build me a WPF tool to view Intune device compliance. Left side = a list of devices, right side = a details pane. Dark/light theme must work. Don't freeze the window when loading."*

The agent will:
1. Classify the request (Type 1 — WPF GUI)
2. Copy `templates/wpf-gui-tool.template.ps1` and the canonical logging/scripts
3. Fill in detection logic, DataGrid, theme toggle
4. Run `Test-ToolCompliance.ps1` and fix any FAIL before delivering
5. Generate a `README.md` from `templates/readme-gui.template.md`
6. Hand you a complete folder, ready to run

> **More example prompts** (30+ across 7 categories) → [Examples & Use Cases](#-examples--use-cases--real-prompts-real-tools)

---

### Step 4 — Run the tool the agent produced

The agent will hand you a folder like this:

```text
Get-IntuneDeviceCompliance/
├── Get-IntuneDeviceCompliance.ps1   # main tool, 1 file
├── Get-IntuneDeviceCompliance.exe   # (optional) packaged binary
├── README.md                         # usage, screenshots, exit codes
├── Reports/                          # output goes here (created on first run)
└── Logs/                             # if the tool uses Initialize-Log
```

**Run it:**

```powershell
# Unpackaged (still .ps1)
.\Get-IntuneDeviceCompliance.ps1

# Or with a parameter the agent's README mentioned
.\Get-IntuneDeviceCompliance.ps1 -TenantId 'contoso.onmicrosoft.com' -OutputPath 'C:\Reports'

# Packaged .exe (after running exe-packaging workflow)
.\Get-IntuneDeviceCompliance.exe
```

For an **Intune remediation pair**, the agent delivers two scripts:

```text
Disable-SMBv1/
├── detect-Disable-SMBv1.ps1      # read-only, exit 0/1/2
├── remediate-Disable-SMBv1.ps1   # applies the fix, verifies, exit 0/1/2
├── README.md
└── Reports/Logs/                 # C:\IntuneLogs\Disable-SMBv1 at runtime
```

**Deploy to Intune:**

1. Open `intune.microsoft.com` → **Devices → Scripts and remediations**
2. **+ Create** → Platform **Windows 10 and later**
3. Upload `detect-Disable-SMBv1.ps1` as the **Detection script**
4. Upload `remediate-Disable-SMBv1.ps1` as the **Remediation script**
5. **Run script in 64-bit PowerShell** = `Yes`, **Run as** = `SYSTEM`, **Enforce signature check** = `No`
6. Assign to a pilot group first, then roll out

---

### Step 5 — Verify the deliverable before shipping (CI-ready gates)

The skill ships three test scripts. Each one is a standalone PowerShell script with `exit 0` (pass) or `exit 1` (fail) — wire them into your CI:

```powershell
# 1. "Is the skill installed correctly?" — runs on the SKILL itself
.\scripts\Test-Skill.ps1
# Exit code 0 = all PASS · 1 = at least one FAIL

# 2. "Does my new tool follow the standard?" — runs on any tool
.\scripts\Test-ToolCompliance.ps1 -ToolPath '.\Get-IntuneDeviceCompliance.ps1'
# Output: [PASS]/[WARN]/[FAIL] per law, then RESULT: COMPLIANT or NON-COMPLIANT

# 3. "Is this delivery ready to ship?" — combines everything + a real PS 5.1 smoke test
.\scripts\Test-Delivery.ps1 -ScriptPath '.\Get-IntuneDeviceCompliance.ps1' -ReadmePath '.\README.md' -SmokeTest
# This is the final gate. It catches the things pwsh-only success hides —
# like [HelpMessage()] that parses on pwsh 7 but crashes 5.1.
```

| Gate | Question it answers | When to run |
|------|--------------------|-------------|
| `Test-Skill.ps1` | Is the skill itself healthy? | After install / after editing the skill |
| `Test-ToolCompliance.ps1` | Does my tool follow the 12 laws? | After every build, before commit |
| `Test-Delivery.ps1` | Is the whole delivery ready to ship? | Last command before merge / push / Intune upload |
| `Test-ReadmeFidelity.ps1` | Does the README match its template? | After every README change |

> **The rule:** if it fails the gate, it doesn't ship. The gates are 100% automatable — add them to your pre-commit hook and your CI pipeline, then forget about manual review.

---

### Step 6 (optional) — Customize before you scale

Once you've confirmed the skill works on one tool, you can tune it:

| What | Where | When |
|------|-------|------|
| **Design tokens** (colors, spacing, fonts) | `references/design-tokens.md` | Only if your brand differs from Tailwind Slate |
| **HTML report design** | `templates/EnterpriseHtmlReport.template.ps1` | Only if you want a different executive-report look |
| **WPF styles** (the 19 required) | `references/xaml-styles.md` | Almost never — copy verbatim per Identity Lock |
| **Log paths per script type** | `references/_logging-canonical.md` | Only if your enterprise has a mandated log share |
| **Author/brand** | `SKILL.md` § Identity Lock + canonical author block in each README | If you're forking for an organization |

> **Don't change names.** You can change values (hex colors, font sizes, log paths) freely. You cannot change names (`BtnBase`, `BackgroundBrush`, `Write-Log`, `Add-LogLine`) — the gates and the canonical helpers all depend on those names. Changing them silently breaks every delivered tool.

---

## 💬 Examples & Use Cases — Real Prompts, Real Tools

Below are 30+ tested prompts organized by the type of deliverable you need. Every prompt was written the way a real operator would type it — casual, with context, and asking for the same thing three different ways so you can see how the skill matches intent, not keywords. Copy any of them verbatim or paraphrase to your situation.

---

### 🖥️ Type 1 — WPF GUI Tools (Type 1: DataGrid + dark/light + async)

The model will build a full Tier 1 desktop app with sidebar, status bar, theme toggle, and a live log console — every interactive button wrapped in `Guard-Action` so double-clicks can't race.

| # | Prompt | What you get |
|:-:| :--- | :--- |
| 1 | *"Build me a WPF tool to manage Entra ID users — search bar, DataGrid with the user list, side panel for details, dark/light toggle, and a button to disable a selected account."* | Full Tier 1 desktop app: sidebar nav, async Graph call, Tailwind Slate themed DataGrid, Guard-Action on every button, live log terminal at the bottom. |
| 2 | *"I need a helpdesk-style dashboard that shows our top 5 Intune compliance problems and a button to drill into each. Must have a working dark mode."* | WPF app with `StatCard` KPI tiles at the top, `Card`-themed drill-down sections, theme toggle that updates every control instantly via `DynamicResource` tokens. |
| 3 | *"Create a BitLocker recovery key viewer GUI. Side panel shows the list of devices, main panel shows the recovery key with a copy button and a 'Rotate Key' button."* | WPF app with `DataGrid` + selected-detail layout, `BtnPrimary` for safe actions, `BtnRed` for destructive (rotate), `StatusBar` shows the last operation result. |
| 4 | *"Make me a Local Admin Password Solution (LAPS) GUI for our helpdesk. Read-only view per device + a 'Request Password' button that copies to clipboard."* | WPF app with `InputBox` filters, `InputBoxNoHover` for read-only fields, `BtnGreen` for the request action, clipboard via `System.Windows.Clipboard`, security warning toast. |
| 5 | *"A WPF tool to view Intune policy assignments: left tree = policies, right pane = assignments. Status bar at the bottom shows connection state. Light/dark must work everywhere."* | WPF app with `TreeView` + `DataGrid` master/detail, status bar with `ConnectionDot` + `ConnectionLabel`, every color via theme tokens so dark mode is instant. |
| 6 | *"Helpdesk: 'Reset Intune Primary User on this device' WPF tool — search device, show current primary user, pick replacement, Apply. Confirm dialog before submit."* | WPF app with `Guard-Action` on Apply, `Show-ToastMessage` confirmation pattern instead of `MessageBox`, async `Start-Job` for the Graph call. |
| 7 | *"I want a WPF dashboard for our tenant: tenant name, license count, last 30 days of Intune enrollments, last 10 audit events. Refresh button at the top."* | WPF app with `LiveMessageCenterBox` log, `StatCard` tiles, async Graph call to `/reports`, refresh button uses `Guard-Action` to prevent rapid double-clicks. |
| 8 | *"Build me a WPF tool to manage Windows Update for Business rings. Top panel = ring list, bottom = assigned devices. Buttons: 'Add Ring', 'Edit Assignments', 'Delete'."* | WPF app with `BtnRed` (Delete) + `BtnPrimary` (Add) + `BtnBlue` (Edit), edit dialog as `Inline XAML Dialog` (Pattern D), no second window. |

**Tips for the GUI prompt:** name the *controls* you want (`DataGrid`, `TreeView`, `Card`, `StatCard`, `InputBox`) — the model maps them to the canonical 19 styles. Always mention *"dark/light must work"* and *"must not freeze"* — the model adds `DynamicResource` everywhere and uses `Start-Job` for long ops.

---

### 🛡️ Type 2 — Intune Remediations, Custom Compliance, and Graph scripts

The model will classify your request into one of: (a) **detection/remediation pair** (two scripts in one folder, exit codes 0/1/2), (b) **Custom Compliance discovery** (one script returning JSON, plus a `.json` rules file), (c) **Graph workstation report** (CLI that calls Microsoft Graph and exports CSV/HTML).

| # | Prompt | What you get |
|:-:| :--- | :--- |
| 1 | *"Create an Intune remediation pair that detects and disables TLS 1.0 and 1.1 on Windows devices. Detection should be read-only; remediation must verify the fix after applying."* | Two scripts in one folder: `detect-*.ps1` and `remediate-*.ps1`. Headers with `.REMEDIATIONTYPE` / `.PAIRSCRIPT` / `.PERMISSIONS = None (local SYSTEM context)`. Exit `0/1/2`. Logs to `<SystemDrive>\IntuneLogs\<SolutionName>\`. |
| 2 | *"Build me a Custom Compliance discovery script that flags any device whose BitLocker is not using XTS-AES 256, plus the JSON rules file Intune needs."* | Discovery script returns `{"BitLockerEncryptionMethod":"XTS-AES 256","Compliant":true}` JSON, plus `Bitlocker-EncryptionMethod.json` with `SettingName: Compliant` and `Operand: true` rules. Always exits `0`. |
| 3 | *"Intune detection that checks if the local admin account 'Administrator' is disabled. Read-only. Run hourly."* | `detect-DisableBuiltinAdmin.ps1` reading `HKLM:\SAM\SAM\Domains\Account\Users\Names\Administrator\F` or `Get-LocalUser`. Returns `0/1/2`. Logs at `DEBUG` level only (read-only — must be silent). |
| 4 | *"Graph script to export all Intune managed devices to CSV with their primary user UPN, last check-in, and compliance state. App-only auth."* | CLI with `Connect-GraphAuth` app-only flow, `Get-MgGraphAllPages` for pagination, `Export-Csv` to `Reports\` beside the script, throttling-aware retry. |
| 5 | *"Remediation pair: detect and repair the Windows Update components (reset WU service, clear SoftwareDistribution, run wuauclt /resetauthorization). Idempotent — safe to run twice."* | Two scripts. Detection checks `Get-Service wuauserv` + SoftwareDistribution folder size. Remediation stops service, renames folder, re-registers binaries, restarts, **verifies** by re-running detection logic. |
| 6 | *"I need a notification runbook that emails me daily at 8 AM with the count of non-compliant Intune devices. Graph Mail API, HTML body, no attachments."* | `Send-EmailNotification.ps1` runbook for Azure Automation. Managed Identity auth, HTML body, `saveToSentItems = $false`. `Finish-Script` exit `0` (success) or `1` (transport error). |
| 7 | *"Detection script: are all required Windows services running? Print-Win32Service — Spooler, WinRM, BITS, WSearch, Themes, TabletInputService. Return non-compliant if any are stopped."* | Single detection script using `Get-Service -RequiredServices`, exit `1` if any required service is Stopped/Disabled. Header declares `Remediation not required - alert only`. |
| 8 | *"Generate the Intune custom compliance JSON to enforce TPM 2.0 enabled, Secure Boot on, and UEFI firmware (not Legacy BIOS). I'll pair it with a discovery script."* | Discovery script that reads `Win32_Tpm`, `Win32_ComputerSystem`, `Win32_BIOS` and emits JSON with `TpmVersion`, `SecureBootEnabled`, `BIOSMode` fields. JSON rules file with three `SettingName`/`Operator: IsEquals`/`Operand: true` blocks. |
| 9 | *"PowerShell script to find all Windows devices in Intune that haven't checked in for 30 days, export to CSV, email the result to me."* | Combined script: `Get-MgGraphAllPages` with `$filter = lastSyncDateTime lt ...`, `Export-Csv` to `Reports\StaleDevices_*.csv`, then `Send-EmailNotification` with HTML body and CSV attachment. |
| 10 | *"Remediation: detect and disable the SMBv1 server feature. Don't break SMBv2/3. Verify after."* | Detection: `Get-WindowsFeature FS-SMB1`. Remediation: `Disable-WindowsFeature -Online -Remove -NoRestart`, then **post-verify** by re-running detection. Exit `0` only if both passes are compliant. |

**Tips for the Intune prompt:** state the *exit codes* explicitly (`0 = compliant`, `1 = non-compliant`, `2 = error`). Mention the log path you want (`<SystemDrive>\IntuneLogs\<SolutionName>\`). For Graph calls, name the auth method (interactive / app-only / managed identity) — the model wires the right auth block.

---

### 🏢 Type 3 — Enterprise CLI Scripts (AD, WinRM, event logs, printers, CIM)

The model will write a single-file CLI with `Initialize-Log` + `Write-Banner` + `Write-Log` + `Write-Summary` + `Finish-Script` — header declares `.PERMISSIONS` honestly, structured per-target results, `-WhatIf` / `-Confirm` for destructive ops.

| # | Prompt | What you get |
|:-:| :--- | :--- |
| 1 | *"Find inactive AD accounts (no logon for 90+ days) and disable them. CSV export, -WhatIf support, exclude service accounts from a 'svc-*' prefix."* | CLI with `Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 90`, `Disable-ADAccount` with `-WhatIf`, CSV in `Reports\InactiveUsers_<timestamp>.csv`, structured per-user result object. |
| 2 | *"Restart the Print Spooler service on every computer in 'CN=PrintServers,DC=contoso,DC=com'. Show per-server success/failure. Don't run on more than 10 at a time."* | CLI with `Get-ADComputer -SearchBase ...`, `Invoke-Command -ThrottleLimit 10` for `Restart-Service Spooler -Force`, structured per-server result, summary table at the end. |
| 3 | *"Find all locked-out AD users and send their manager an email with the unlock instructions. Pull the manager from the 'manager' AD attribute."* | CLI that finds locked accounts, looks up each `manager` from AD, sends mail via `Send-MailMessage` (or Graph). Handles missing manager with a default "no manager" path. |
| 4 | *"Pull all Event Log entries with ID 4625 (failed logon) from the last 24 hours across 5 domain controllers. Export to CSV. Use XPath filter, not Where-Object."* | CLI using `Get-WinEvent -FilterXml` with pre-built XPath (fast, doesn't load all events), `Invoke-Command` to each DC, `Export-Csv`. |
| 5 | *"Set the description on a list of printers (from CSV) to 'Available - Floor 3'. Need a dry-run first."* | CLI with `Get-Printer -Name ...`, `Set-Printer -Description ...`, `-WhatIf` support, per-printer success/failure report. Uses AD + CIM to find the printers' OU if needed. |
| 6 | *"Inventory all installed software on a remote machine and export to CSV: name, version, publisher, install date. Use CIM, not the slow Win32_Product WMI class."* | CLI with `Get-CimInstance -ClassName Win32_InstalledWin32Program` (the fast path), `Invoke-Command`, `Export-Csv` with `-NoTypeInformation`. |
| 7 | *"Bulk-rename AD computers from `OLDCOMP-NNNN` to `NEWCOMP-NNNN` using a CSV. Show -WhatIf by default. Log every change to a file."* | CLI with `Import-Csv`, `Rename-Computer -NewName` (remote via `Invoke-Command`), structured per-row result, requires `-Confirm` for actual changes. |
| 8 | *"Get the last 7 days of 'Application Error' events from the local server. Group by source. Top 5 noisiest apps at the top."* | CLI with `Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2; StartTime=(Get-Date).AddDays(-7)}`, `Group-Object ProviderName, Count, Sort-Object Count -Descending`, `Select-Object -First 5`. |
| 9 | *"Enumerate all AD groups with more than 100 members. List group name, member count, manager (if any), and last modified date."* | CLI with `Get-ADGroup -Filter * -Properties Members,ManagedBy,WhenChanged`, filter on `.Count -gt 100`, sort by member count, `Export-Csv`. |
| 10 | *"On every server in 'CN=DomainControllers,DC=contoso,DC=com', check if the time skew from the PDC emulator is more than 5 minutes. Alert on each offender."* | CLI with `Get-ADDomainController -Discover -Service PrimaryDC`, then `w32tm /query /computer:<dc> /status` via `Invoke-Command` against each DC. Reports in green/yellow/red table. |

**Tips for the CLI prompt:** name the *output* (CSV / console table / email). Mention the *limit* (`don't run on more than 10 at a time`, `exclude service accounts`). Always include `-WhatIf` for any destructive op — the model will add the `ShouldProcess` block automatically.

---

### 🍎 Type 3b — macOS bash scripts for Intune

The model follows `references/macos-patterns.md`: `set -euo pipefail`, `logger` integration, exit codes 0/1/2.

| # | Prompt | What you get |
|:-:| :--- | :--- |
| 1 | *"Bash script to enforce dock settings: disable 'Displays have separate Spaces' and set the dock to auto-hide. Run via Intune as system."* | macOS shell script using `defaults write` followed by `killall cfprefsd`, `defaults` verification read-back, exit `0`/`1`/`2`. |
| 2 | *"Bash detection: is FileVault enabled? Print yes/no and the recovery key status. Used as a compliance gate."* | macOS script with `fdesetup status`, exit `0` if enabled, `1` if not, JSON output mode for Intune. |
| 3 | *"macOS bash: check if XProtect (Apple's malware scanner) is up to date. Print last update date and comparison to current date."* | macOS script with `system_profiler SPInstallHistoryDataType` filter for XProtect, or `defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist`. |
| 4 | *"macOS bash: check the warranty status of this Mac via AppleCare API. Output serial + coverage status."* | macOS script with `ioreg -l | grep IOPlatformSerialNumber`, `curl` to `https://selfsolve.apple.com/...` for warranty, `jq` for JSON parsing. |

---

### 📚 Type 4 — Documentation only (READMEs, runbooks)

| # | Prompt | What you get |
|:-:| :--- | :--- |
| 1 | *"Write a README for this Intune remediation pair — it disables SMBv1, requires SYSTEM context, logs to C:\IntuneLogs\DisableSMBv1."* | README from the intune-pair template: hero with 5+ shields.io badges, Overview, Core Features, Project Structure tree, Scripts Included (Detection + Remediation subsections), Requirements, Intune Deployment table, Typical Workflow, Operational Notes, Disclaimer, License, Author. |
| 2 | *"Write a README for a WPF helpdesk tool that shows AD users in a DataGrid, with a dark/light toggle. The tool is signed and shipped as a .exe."* | README from the gui template: hero with UI + Theme badges, Usage section with the theme-toggle caveat, Operational Notes for the .exe packaging, exit-code table. |
| 3 | *"I have a 200-line PowerShell script that gets AD users and emails the result. Write the README only — don't rewrite the script."* | README from the basic template, inferring metadata from the script's `.DESCRIPTION` and `.NOTES` blocks. No code change. |
| 4 | *"Generate a CHANGELOG.md from my recent git commits in the v1.x branch."* | CHANGELOG.md with grouped entries (Added / Changed / Fixed) per release, generated from `git log` with conventional-commit parsing. |

---

### 🧪 Auditing, reviewing, and refactoring existing PowerShell libraries

The model can also review, audit, and refactor existing code — the canonical gates (`Test-ToolCompliance.ps1`, `Test-ReadmeFidelity.ps1`, `[Parser]::ParseFile`) are built for this.

| # | Prompt | What you get |
|:-:| :--- | :--- |
| 1 | *"Run a final compliance review on my 200+ PowerShell scripts. Check headers, log paths, exit codes, and the Icon Law. Report failures with file paths."* | Full library audit. The model runs `Test-ToolCompliance.ps1` over every `.ps1`, then `Test-ReadmeFidelity.ps1` over every `README.md`, then `[Parser]::ParseFile` for syntax. Outputs a table of PASS/FAIL/WARN per file. |
| 2 | *"My Intune-Scripts library has duplicates and dead .ps1 files. Find the duplicates and the dead files. Don't delete anything — just list them."* | The model scans for: identical function names across files, identical folder names that differ only in case, and files that no other file references. Outputs a `DUPLICATES.md` and `DEAD-CODE.md` report. |
| 3 | *"Normalize the `.PERMISSIONS` header field across all my Intune scripts. They all say different things right now. Use the canonical wording."* | The model rewrites every `.PERMISSIONS` to either real Graph scopes (for Graph callers) or `None (local SYSTEM context)` (for non-Graph). Re-runs `Test-ToolCompliance.ps1` to confirm zero FAIL. |
| 4 | *"Audit my CHANGELOG.md — every script has a different version date. Sync the dates with the latest git tag per folder."* | The model walks each script folder, finds the latest `.CHANGELOG` date, updates `.LASTUPDATE` to match, and re-runs `Test-ToolCompliance.ps1`. |
| 5 | *"My WPF XAML uses invented style names like `PrimaryButtonStyle` and `CardBorderStyle`. Rename them to the canonical names from the skill."* | The model maps the invented names to the 19 canonical styles (`BtnPrimary`, `Card`, etc.), rewrites all XAML references, re-runs `Test-XamlFile.ps1` to confirm zero parse errors. |
| 6 | *"I have 30 PowerShell scripts that all use `[Parameter(Mandatory=$true)] [string]$Message` for the logging helper. Apply the Pitfall 30 fix: add `[AllowEmptyString()]` and a default of `""`, plus an early-return guard."* | The model rewrites every local `Write-Log` / `Add-LogLine` to follow the Empty-Message Spacer Rule, with `if ([string]::IsNullOrEmpty($Message)) { return }` as the first line of the function. |
| 7 | *"Check my PowerShell code for PS 5.1 compatibility. Anything that uses `??` or `? :` ternary or `[ordered]` without explicit import is broken on 5.1."* | The model greps for `??` and `? :` patterns, replaces them with `if` expressions, and rewrites any `ordered` dict usage to `New-Object System.Collections.Specialized.OrderedDictionary`. |
| 8 | *"Generate a ROADMAP.md for my Intune-Scripts library — what I have, what's missing, what should be in v3.0 based on Microsoft 2025-2026 Intune changes."* | The model reads the directory tree, counts scripts by category, then writes a ROADMAP.md comparing the current state to known 2025-2026 Intune gaps (Secure Boot CA 2023, Hotpatch, macOS Platform SSO, LAPS migration, etc.). |
| 9 | *"My README badges are inconsistent — some scripts have 3 badges, some have 8. Normalize every README to the canonical hero (5+ badges in fixed order)."* | The model reads every README, rewrites the hero with the canonical badge set (PowerShell 5.1+, Platform, License, Version, Intune if pair) in the canonical order, re-runs `Test-ReadmeFidelity.ps1`. |
| 10 | *"Audit my master README's counts — file count, script count, README count, remediation pair count. Update the master README to match the actual filesystem."* | The model runs `Measure-Object` across the repo, computes the real counts, and rewrites the master README's Tables + Summary + Project Structure to match. |

**Tips for the audit prompt:** name the *gate* (`Test-ToolCompliance.ps1`, `Test-ReadmeFidelity.ps1`, `[Parser]::ParseFile`). State the *scope* (whole library, one folder, one script). State the *output format* (table, list, summary, no edits — just a report).

---

### 🆕 Quick copy-paste starter prompts (one for each type)

| Type | Starter prompt |
|:---:|:---|
| **Type 1** | *"Build a WPF tool that shows a DataGrid of [ENTITIES] with a search box, a dark/light toggle, and a button to [ACTION]. Log everything to a colored log terminal at the bottom. Use the canonical 19 styles and don't freeze the window."* |
| **Type 2** | *"Create an Intune remediation pair that detects and [ACTION] on Windows. Detection is read-only with exit 0/1/2. Remediation must verify the fix after applying. Logs to `<SystemDrive>\IntuneLogs\<SolutionName>\`."* |
| **Type 2b** | *"Build a Custom Compliance discovery script that returns JSON with `{Field1, Field2, Compliant}`. Pair it with the rules JSON file Intune needs."* |
| **Type 2c** | *"Graph PowerShell script to query [ENDPOINT] with pagination, retry on 429, and export to CSV beside the script. App-only auth, report the run time."* |
| **Type 3** | *"PowerShell script to [READ/MODIFY] [ENTITIES] on a remote machine list. -WhatIf by default, structured per-target results, summary at the end, exit 0 on success, 1 on any failure."* |
| **Type 3b** | *"macOS bash script to [ACTION]. Use set -euo pipefail, send output to syslog via logger, exit 0/1/2. Compatible with Intune macOS shell scripts."* |
| **Type 4** | *"Write a README for this [SCRIPT TYPE] — include badges, features, structure, scripts, requirements, deployment, workflow, operational notes, disclaimer, license, author."* |
| **Audit** | *"Audit my [LIBRARY/FOLDER] — check every .ps1 for header correctness, log path, exit codes, Icon Law, and README fidelity. Report failures by file."* |

---

### 🚫 Common mistakes that break the skill (don't do this)

| Mistake | Why it fails | What to do instead |
| :--- | :--- | :--- |
| *"Make me a PowerShell tool"* | Too vague — could be WPF, CLI, or Intune. The model will ask, but you can save a round-trip by saying which type. | Add the type: *"WPF dashboard for…"*, *"Intune remediation pair for…"*, *"CLI tool for…"* |
| *"Use whatever icons look good"* | Invites Segoe MDL2 or font-based glyphs — the Icon Law will reject them. | Name the canonical icon set: *"use SVG paths only, not font icons"*. The model picks from `references/icons.md`. |
| *"Add some colors to the dashboard"* | Model will hardcode hex codes, breaking dark mode. | *"Use the Tailwind Slate theme tokens — light/dark must work everywhere."* |
| *"Skip the tests, I just need the script"* | Removes the quality gate — the next iteration of the same model (or a different one) will drift. | Always run `Test-Delivery.ps1` before shipping. It's one command. |
| *"Write me a 1,400-line GUI tool in one shot"* | Models drift on long contexts — they invent names, miss laws. | Ask for Tier 1 (single file, all required styles, ~300-500 lines) and iterate. |
| *"Detect non-compliance with a 1-line message"* | A 1-line message is not a script. The model needs a verb, a noun, and an input. | *"Detect if [CONDITION] and exit 0/1/2"* — be explicit about exit codes. |
| *"I'll send you a file, fix it"* | The model has limited context for large files. | Specify the *path*, the *gate* that failed, and the *expected vs actual* behavior. |
| *"Just give me the script, I don't care about the docs"* | Skipping docs means the next maintainer (you, in 6 months) cannot use the tool safely. | Always include the README — the template generates it in seconds and it standardizes the deliverable. |

---

## 📂 Folder Map

```text
powershell-enterprise-admin/
├── SKILL.md                  # Full specification — the brain of the skill
├── README.md                 # This file
├── LICENSE                   # MIT
├── CHANGELOG.md              # Version history
├── lessons-learned.md        # Real production mistakes we never repeat
│
├── scripts/                  # Ready-made helpers — copied VERBATIM into tools
│   ├── Add-LogLine.ps1       #   GUI logging: file + status bar + duplicate guard
│   ├── Write-Log.ps1         #   CLI logging: init / banner / finish helpers
│   ├── Guard-Action.ps1      #   Button busy guard — prevents double-click races
│   ├── Get-MgGraphAllPages.ps1          #   Graph pagination done right
│   ├── Invoke-GraphRequestWithRetry.ps1 #   Auto-retry on 429 / 503 errors
│   ├── Invoke-GraphBatchRequest.ps1     #   Graph batch ($batch) helper
│   ├── Get-Graph403Message.ps1          #   Actionable 403 messages per service
│   ├── Connect-GraphAuth.ps1 #   Auth per context (interactive / managed identity)
│   ├── ConvertTo-SafeDateTime.ps1       #   Dates safe on any locale
│   ├── Send-EmailNotification.ps1       #   Graph Mail API — HTML email helper
│   ├── Settings.ps1          #   GUI settings persistence (Pattern Q)
│   ├── Embed-Xaml.ps1        #   GZip+Base64 XAML embed for Tier 3 modular tools
│   ├── Test-XamlFile.ps1     #   XAML validator (catches crashes before launch)
│   ├── Test-Skill.ps1        #   Self-test for the skill itself
│   ├── Test-ToolCompliance.ps1  #   Compliance gate for generated tools
│   ├── Test-ReadmeFidelity.ps1  #   README vs template fidelity gate
│   └── Test-Delivery.ps1     #   One command = full delivery check
│
├── references/               # Deep-dive guides the agent reads when building
│   ├── design-tokens.md      #   Every color, spacing, and font value
│   ├── xaml-styles.md        #   Full XAML for all 19 required styles
│   ├── patterns.md           #   Code for all 21 canonical patterns
│   ├── pitfalls.md           #   Documented PS 5.1 crash causes and fixes
│   ├── icons.md              #   SVG path library (no fonts)
│   └── ...                   #   AD, WinRM, event logs, Intune, macOS, packaging
│
└── templates/                # Copy-paste scaffolds for every deliverable
    ├── wpf-gui-tool.template.ps1        # Full GUI skeleton, all 19 styles included
    ├── cli-tool.template.ps1            # Standard CLI tool
    ├── intune-detect.template.ps1       # Detection script
    ├── intune-remediate.template.ps1    # Remediation script
    ├── intune-notification.template.ps1 # Notification runbook (Graph Mail API)
    ├── EnterpriseHtmlReport.template.ps1# IBM Carbon Dark HTML report (Pattern U)
    ├── macos-script.template.sh         # macOS bash script
    └── readme-*.template.md             # 4 README variants (basic/cli/gui/intune-pair)
```

> **Golden rule:** agents copy from `templates/` first, then fill placeholders — never write from scratch. Templates already pass the compliance gate, so staying close to them *is* compliance.

---

## 📜 The 12 Laws

Twelve simple rules. Break one → the tool is rejected. None are arbitrary — each law exists because of a real production bug it prevents.

| # | Law | Rule | Why It Exists |
|:-:| :--- | :--- | :--- |
| 1 | **Header** | Every file starts with the full standard header | Without it, nobody knows what the script does or who owns it |
| 2 | **Naming** | Functions `Verb-Noun`, variables `camelCase`, controls prefixed | Anyone can open any tool and instantly find their way around |
| 3 | **No Aliases** | Write `Get-ChildItem`, never `gci` | Aliases hide intent and break text searches |
| 4 | **Errors** | `$ErrorActionPreference = 'Stop'`; never empty `catch {}` | Silent failures are the worst failures — users must see *why* |
| 5 | **Colors** | All colors via theme tokens `{DynamicResource}` | Hardcoded colors break dark mode — tokens make toggle instant |
| 6 | **Icons** | SVG paths only — no symbol fonts ever | Font icons show empty boxes on locked-down servers |
| 7 | **Sidebar** | Navigation only — system buttons live in the header | Users always know where to look for nav vs. settings |
| 8 | **Threads** | Never block the UI thread | A frozen window looks like a crash — users click again and make it worse |
| 9 | **Ampersand** | Every `&` in XAML written as `&amp;` | Unescaped `&` silently kills the app at startup |
| 10 | **StaticResource** | Every referenced style must exist | Missing style = crash at launch, not at build time |
| 11 | **Language** | English-only code, comments, and docs | Non-English text breaks parsers, grep, and CI pipelines |
| 12 | **Report Paths** | Reports save beside the script | Relative paths crash when the script is dot-sourced |

Full details with enforcement commands: [`SKILL.md`](SKILL.md)

---

## 🎨 Design System

Every GUI tool shares one visual language: **Tailwind Slate**. It works like paint-by-numbers — instead of choosing colors, the agent picks a named token, and light/dark mode just works.

### How theming works

Each color exists once as a named token (a brush). Controls reference the token name, never the hex value. Switching themes swaps the token values behind the scenes — every control updates instantly, nothing gets rebuilt.

```text
Button uses BackgroundBrush  →  Light mode: #F1F5F9  →  Dark mode: #1E293B
```

### Core tokens

| Token | Light | Dark | Used For |
| :--- | :--- | :--- | :--- |
| `BackgroundBrush` | `#F1F5F9` | `#1E293B` | Window background |
| `SurfaceBrush` | `#FFFFFF` | `#334155` | Cards and inputs |
| `BorderBrush` | `#E2E8F0` | `#475569` | Borders |
| `TextPrimaryBrush` | `#0F172A` | `#FFFFFF` | Headings |
| `AccentBrush` | `#3B82F6` | `#60A5FA` | Buttons and highlights |
| `SuccessBrush` | `#10B981` | same | Success states |
| `DangerBrush` | `#EF4444` | same | Errors and danger actions |

### The 19 required styles

Every GUI defines the same style set, so every tool feels familiar:

```text
Buttons:     BtnPrimary, BtnGreen, BtnRed, BtnGhost, BtnOutline,
             NavBtnBase (sidebar), BottomActionBtn ...
Containers:  Card, StatCard, SessionCard
Inputs:      InputBox, StyledCheckBox, StyledComboBox, FieldLabel
Console:     LiveMessageCenterBox (dark terminal-style log viewer)
```

Full XAML for all of them: [`references/xaml-styles.md`](references/xaml-styles.md)

---

## 💻 Works On

| OS | WPF GUI | Intune | CLI |
| :--- | :---: | :---: | :---: |
| Windows 11 / 10 | ✅ | ✅ | ✅ |
| Windows Server 2016 – 2025 | ✅ | ⚠️ Azure Arc | ✅ |
| macOS (Sonoma / Sequoia) | ❌ | ✅ | ✅ Bash |
| Azure Automation | ❌ | ✅ Runbooks | ✅ |

Works with PowerShell 5.1 and 7+. No special fonts, no extra modules required — SVG paths render everywhere, even on locked-down server builds.

---

## 🧪 Test Everything

Three commands. That's the whole quality system — and each one answers a different question:

```powershell
# 1. "Is the skill installed correctly?"
.\scripts\Test-Skill.ps1

# 2. "Does my new tool follow the standard?"
.\scripts\Test-ToolCompliance.ps1 -ToolPath .\MyTool.ps1

# 3. "Is this delivery ready to ship?"  ← run last, before shipping
.\scripts\Test-Delivery.ps1 -ScriptPath .\MyTool.ps1 -ReadmePath .\README.md -SmokeTest
```

What each one actually checks:

* **`Test-Skill.ps1`** — validates the skill's own files: syntax parses, headers are ordered correctly, tokens and styles exist, file sizes stay within budget.
* **`Test-ToolCompliance.ps1`** — greps your tool for drift: forbidden icon fonts, invented style names, missing button guards, missing README badges or disclaimer.
* **`Test-Delivery.ps1`** — combines everything plus a **real PS 5.1 smoke test**. This matters because code that parses fine on PowerShell 7 can still crash on 5.1 (the version most enterprises actually run).

Exit codes are CI-ready: `0` = pass, `1` = fail. Wire them into any pipeline.

---

## ❓ FAQ

**Q: Do I need this for small scripts too?**
A: Yes — that's the point. Small tools get the Tier 1 treatment: everything in one `.ps1` file, still fully compliant. Only complex apps (5+ features) use the modular structure.

**Q: Can my agent use Segoe MDL2 icons?**
A: No. They look fine on Windows 10/11 but render as empty boxes on Server Core and locked-down builds. SVG paths from `references/icons.md` render everywhere and can recolor with the theme.

**Q: Does it really never freeze the UI?**
A: Correct. Any operation longer than a moment runs in a background job (`Start-Job`) or async runspace, with the UI polling results on a timer. It's Law 8 — no exceptions.

**Q: What if the request is ambiguous?**
A: The skill instructs the agent to ask you before building — e.g., "Graph API + dashboard" could mean a GUI tool (Type 1) or a cloud script (Type 2). Guessing wrong wastes a whole build.

**Q: Why does `Get-Help` show nothing on generated scripts?**
A: The rich header uses custom dotted fields (`.TAGS`, `.REMEDIATIONTYPE`) — machine-readable by design, which standard comment-based help can't mix with. The trade-off is documented in `references/pitfalls.md`.

**Q: Can I customize the design?**
A: Change values, not names. Adjust token hex values freely — but keep token and style *names* fixed, because shared tooling and tests depend on them.

---

## 🛡 Operational Notes

* **Least privilege** — `.PERMISSIONS` lists only real Graph scopes actually used, or honestly says `None (local SYSTEM context)`
* **No secrets stored** — settings files never contain passwords or client secrets
* **Safe by default** — destructive actions support `-WhatIf` / `-Confirm`
* **Government clouds supported** — Commercial, GCC, GCC-High, and DoD endpoints documented
* **Culture-safe dates** — `ConvertTo-SafeDateTime` works on any locale, not just en-US
* **Idempotent remediations** — paired scripts are safe to run twice; they verify the fix after applying it

---

## ⚠ Disclaimer

This skill and every script it generates are provided as-is with no warranty
of any kind. Test generated tools in a staging environment before deploying to
production. The authors assume no liability for any damage or data loss
resulting from their use.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Mohammad Abdulkader Omar**  
GitHub: [@mabdulkadr](https://github.com/mabdulkadr)  
Website: [momar.tech](https://momar.tech)  

---

<div align="center">

⭐ **If this skill saves you time, star the repo — it helps others find it.**

[Report an Issue](../../issues) · [momar.tech](https://momar.tech)

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/mabdulkadrx)

 Built with [**PowerShell Enterprise Admin**](https://github.com/mabdulkadr/powershell-enterprise-admin-skill)

</div>
