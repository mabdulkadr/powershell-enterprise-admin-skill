<div align="center">

# ⚡ PowerShell Enterprise Admin Skill

**Turn any AI agent into a senior PowerShell architect.**

One standard. Every tool looks, runs, and logs the same way — production-grade, every time.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11%20-0F172A?style=for-the-badge)](#-works-on)
[![UI](https://img.shields.io/badge/UI-WPF%20Tailwind%20Slate-3B82F6?style=for-the-badge&logo=windows&logoColor=white)](#-design-system)
[![Theme](https://img.shields.io/badge/Theme-Light%20%2F%20Dark-8B5CF6?style=for-the-badge)](#-design-system)
[![Evals](https://img.shields.io/badge/Evals-25%20Scenarios-10B981?style=for-the-badge)](#-test-everything)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge)](#-license)
[![Version](https://img.shields.io/badge/Version-1.2-334155?style=for-the-badge)](CHANGELOG.md)

[How It Works](#-how-it-works) • [Quick Start](#-quick-start) • [12 Laws](#-the-12-laws) • [Design System](#-design-system) • [FAQ](#-faq)

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

Four steps. About two minutes.

**Step 1 — Install.** Copy the skill folder into your agent's skills directory:

| Agent | Install Command |
| :--- | :--- |
| **OpenCode** (global) | `Copy-Item -Recurse .\powershell-enterprise-admin "$env:USERPROFILE\.config\opencode\skills\"` |
| **Claude Code** | `Copy-Item -Recurse .\powershell-enterprise-admin "$env:USERPROFILE\.claude\skills\"` |
| **Cursor** | `Copy-Item -Recurse .\powershell-enterprise-admin ".\.cursor\skills\"` |
| **Any other agent** | Copy the folder to your agent's skills directory and point instructions at `SKILL.md` |

**Step 2 — Ask naturally.** No special commands needed — just describe the tool like you'd tell a colleague:

> *"Build me a WPF tool to manage AD users with search filtering and dark mode."*

> *"Create an Intune remediation pair that detects and disables TLS 1.0/1.1."*

> *"Run a command on 50 servers and show results in a grid."*

**Step 3 — The agent builds it.** It classifies your request, copies the right template, fills it in, and applies all 12 laws automatically.

**Step 4 — Verify before shipping.**

```powershell
# Test the skill installation itself
.\scripts\Test-Skill.ps1
# Expected result: all checks PASS
```

---

## 💬 More Example Prompts

| Category | Prompt | What You Get |
| :--- | :--- | :--- |
| GUI | *"Build a dashboard for Entra ID users with live search."* | Type 1 · WPF app with async Graph queries |
| Intune | *"Export all Intune devices and BitLocker keys to CSV."* | Type 2 · Graph script with pagination |
| AD | *"Disable inactive accounts (>90 days) with WhatIf support."* | Type 3 · Safe bulk CLI with `-WhatIf` |
| Remote | *"Restart a service on 100 machines from a CSV list."* | Type 3 · Throttled WinRM fan-out |
| Event Logs | *"Pull all failed logons from the last 24h across servers."* | Type 3 · Fast filtered event-log query |
| macOS | *"Bash script for Intune to enforce dock settings."* | Type 3 · Intune-ready macOS script |
| Docs | *"Write a README for this remediation pair."* | Type 4 · README with badges + disclaimer |

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
│   ├── Connect-GraphAuth.ps1 #   Auth per context (interactive / managed identity)
│   ├── ConvertTo-SafeDateTime.ps1       #   Dates safe on any locale
│   ├── Test-XamlFile.ps1     #   XAML validator (catches crashes before launch)
│   ├── Test-Skill.ps1        #   Self-test for the skill itself
│   ├── Test-ToolCompliance.ps1  #   Compliance gate for generated tools
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
    ├── macos-script.template.sh         # macOS bash script
    └── readme-*.template.md             # 4 README variants
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
