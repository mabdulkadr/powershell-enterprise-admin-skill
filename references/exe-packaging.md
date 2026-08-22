# EXE Packaging & Distribution — Compile, Sign, Publish

> Distilled from PSWrap (https://github.com/mabdulkadr/PSWrap) and DeviceOffboardingManager (https://github.com/ugurkocde/DeviceOffboardingManager).
> Read this file when the user asks to ship a tool as an `.exe`, sign scripts, or publish to the PowerShell Gallery.

---

## Table of Contents

1. [When to Package vs Ship .ps1](#when-to-package-vs-ship-ps1)
2. [Compile .ps1 to EXE (PSWrap canonical)](#compile-ps1-to-exe-pswrap-canonical)
3. [Custom Icon Embedding](#custom-icon-embedding)
4. [Companion File Bundling](#companion-file-bundling)
5. [Authenticode Code Signing](#authenticode-code-signing)
6. [PowerShell Gallery Publishing (Install-Script)](#powershell-gallery-publishing-install-script)

---

## When to Package vs Ship .ps1

Default to shipping the `.ps1` — it is auditable, greppable, and diffable. Promote to `.exe` only when:

| Driver | Why it wins as EXE |
|--------|--------------------|
| Helpdesk distribution | Double-click launch; no execution policy or right-click-to-run friction |
| IP protection | Source embedded as a compiled managed resource, not plain text next to the user |
| Locked-down endpoints | AppLocker/WDAC rules that block loose scripts but allow signed binaries |
| Branding | Custom icon + version metadata in Explorer |

Never package Intune detection/remediation pairs — they must stay readable `.ps1` files for portal upload.

---

## Compile .ps1 to EXE (PSWrap canonical)

**Canonical tool: PSWrap** (`https://github.com/mabdulkadr/PSWrap`) — use its GUI for interactive compiles; mirror its approach for automation:

- **In-process CodeDOM compilation**, falling back to `csc.exe` on PowerShell 7.x (the GAC ships the .NET Framework `System.Management.Automation` that CodeDOM needs; Core hosts do not).
- **Script embedded as a managed resource** — never Base64 strings or temp files. Managed resources survive AV heuristics better and keep the assembly clean.
- **Async compile** in a background runspace with progress feedback (Pattern C/R) — CodeDOM blocks for seconds on large scripts.
- **Assembly metadata**: version, description, product, copyright, company. Version the EXE from the script's `.VERSION` field so one source of truth drives both.
- **Compilation options** to expose: GUI vs Console output, suppress output/error windows, UAC manifest (asInvoker / requireAdministrator), target platform (x64/x86/AnyCPU), apartment state STA for WPF tools.

Requirements table (put this in every packaging README):

| Requirement | Details |
|-------------|---------|
| OS | Windows 7+ |
| Compiler host | PowerShell 5.1 (CodeDOM) or 7.x (`csc.exe` fallback) |
| .NET Framework | 4.7.2+ (preinstalled on Windows 10/11) |
| Assemblies | `System.Management.Automation`, `System.Windows.Forms` |

**Why STA matters:** every WPF tool from this skill MUST compile with `-target:winexe` + STA thread state, or the window throws `InvalidOperationException` at first ShowDialog inside the EXE.

---

## Custom Icon Embedding

- Embed `.ico` directly via compiler options (`/win32icon:` equivalent).
- When only PNG/JPG/BMP/GIF exists, convert to multi-size ICO first (16/32/48/256 px) — single-size icons render blurry in taskbars and Alt-Tab.
- Keep a default application icon so no build ever ships iconless.
- Store source art in `images/app-icon.png` per the Tier 3 tree in `file-architecture.md`.

---

## Companion File Bundling

Tools that need sidecar assets (docs, templates, reference data) embed them as **resources extracted on first run** to `%LOCALAPPDATA%\<ToolName>\`:

1. Add files to the bundling grid (PSWrap) or resource manifest.
2. At startup, check marker file → extract missing resources before UI load.
3. Never write next to the EXE (`Program Files` is admin-locked); `%LOCALAPPDATA%` keeps first-run unattended.

This is how About dialogs (Pattern M) read `docs/*.md` inside a compiled EXE with zero loose files.

---

## Authenticode Code Signing

Unsigned tools trigger SmartScreen warnings and fail `AllSigned` environments. Sign EVERY distributed artifact:

```powershell
$cert = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.HasPrivateKey -and $_.Subject -match 'YourOrg' } |
    Sort-Object NotAfter -Descending | Select-Object -First 1

$stamp = 'http://timestamp.digicert.com'

# Script
Set-AuthenticodeSignature -FilePath .\ToolName.ps1 -Certificate $cert -TimestampServer $stamp

# Compiled EXE
Set-AuthenticodeSignature -FilePath .\ToolName.exe -Certificate $cert -TimestampServer $stamp

# Verify
Get-AuthenticodeSignature .\ToolName.exe | Select-Object Status, StatusMessage, SignerCertificate
```

Rules:

- **Always timestamp.** Without a timestamp server, signatures die when the certificate expires.
- Keep signing certs out of the repo (PSWrap ships example certs in `cert/` for demos only). Load from the user store or a hardware token.
- CI pipelines sign via a secret-backed certificate import step — never commit `.pfx` files.
- Verify `Status -eq 'Valid'` in the delivery checklist alongside `Test-ToolCompliance`.

---

## PowerShell Gallery Publishing (Install-Script)

Standalone CLI/GUI tools can ship as `Install-Script` packages (the DeviceOffboardingManager model):

```powershell
# One-time author metadata INSIDE the script header (PSScriptInfo block, before the canonical help block):
<#PSScriptInfo

.VERSION 1.0

.GUID <new-guid>

.AUTHOR Mohammad Abdulkader Omar

.PROJECTURI https://github.com/mabdulkadr/YourRepo

.LICENSEURI https://github.com/mabdulkadr/YourRepo/blob/main/LICENSE

.TAGS Intune Graph PowerShell
#>
```

Minimum viable publishing flow:

1. Author with [`New-ScriptFileInfo`](https://learn.microsoft.com/powershell/module/powershellget/new-scriptfileinfo) metadata (Version, Author, Description, ProjectUri, LicenseUri) merged with the canonical header block.
2. Validate: `Test-ScriptFileInfo .\Tool.ps1`
3. Publish: `Publish-Script -Path .\Tool.ps1 -NuGetApiKey <key>`
4. Users then run `Install-Script ToolName` — updates via `Install-Script ToolName -Force`.

Gallery badges for the tool README:

```markdown
![PSGallery](https://img.shields.io/powershellgallery/v/ToolName?label=Version)
![Downloads](https://img.shields.io/powershellgallery/dt/ToolName)
```

Keep the canonical rich header AND the gallery metadata — the trade-off documented in `pitfalls.md` (Get-Help disabled) does not affect `Test-ScriptFileInfo`, which parses its own fields independently.
