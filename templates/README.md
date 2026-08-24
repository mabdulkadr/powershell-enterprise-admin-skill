# Template Library

Copy-paste-ready scaffolds for every artifact this skill produces. **Never start a
deliverable from an empty file** — copy the matching template, rename, fill the
`[Placeholders]`, and keep every structural block intact.

## The TEMPLATE LOCK rule

1. **Copy first.** Pick the template from the map below before writing any code.
2. **Keep the skeleton.** Header order, logging block, exit paths, guard patterns,
   and lifecycle blocks are load-bearing — extend them, never delete or rewrite them.
3. **Fill only the marked regions.** `TODO:` comments and `[Bracketed]` placeholders
   are the customization surface.
4. **Prove adherence.** Every generated `.ps1` must pass
   `scripts/Test-ToolCompliance.ps1`. Because the templates themselves pass it,
   staying close to the template is how you stay compliant.

## Template Map

| Deliverable | Copy this template | Compliance gate |
|-------------|--------------------|-----------------|
| Type 2 detection script | `intune-detect.template.ps1` → rename `detect-<name>.ps1` | Test-ToolCompliance |
| Type 2 remediation script | `intune-remediate.template.ps1` → rename `remediate-<name>.ps1` | Test-ToolCompliance |
| Type 2 notification runbook | `intune-notification.template.ps1` → rename `notify-<name>.ps1` | Manual review + Graph auth test |
| Type 3 general CLI tool | `cli-tool.template.ps1` → rename `<ToolName>.ps1` | Test-ToolCompliance |
| Type 1 WPF GUI tool (Tier 1) | `wpf-gui-tool.template.ps1` → rename `<ToolName>.ps1` | Test-ToolCompliance + XAML dual parse |
| macOS bash script | `macos-script.template.sh` → rename `<toolname>.sh` | shellcheck / manual review |
| README for CLI tool | `readme-cli.template.md` | Test-ToolCompliance `-ReadmePath` |
| README for Intune pair | `readme-intune-pair.template.md` | Test-ToolCompliance `-ReadmePath` |
| README for GUI tool | `readme-gui.template.md` | Test-ToolCompliance `-ReadmePath` |
| README for multi-tool suite | `readme-suite.template.md` | badges + Disclaimer check |

## How to use

```powershell
# 1. Copy (example: an Intune remediation pair)
Copy-Item templates\intune-detect.template.ps1   MySolution\detect-bitlocker.ps1
Copy-Item templates\intune-remediate.template.ps1 MySolution\remediate-bitlocker.ps1

# 2. Fill [Placeholders] and TODO regions; update .PAIRSCRIPT on both halves.

# 3. Verify
.\scripts\Test-ToolCompliance.ps1 -ToolPath MySolution\detect-bitlocker.ps1, MySolution\remediate-bitlocker.ps1 -ReadmePath MySolution\README.md
```

## Section rules per type

Sections are conditional — see the Smart Sectioning matrix in SKILL.md /
references/readme-template.md. Summary: Intune Deployment + Typical Workflow exist
ONLY in `readme-intune-pair`; Usage/Screenshots ONLY in `readme-gui`; the ⚠
Disclaimer text is verbatim-canonical in ALL variants.
