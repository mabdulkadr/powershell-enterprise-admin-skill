# Professional README.md Template

Complete template for writing professional README.md files for PowerShell enterprise tools.

---

## Table of Contents

1. [Basic Template](#basic-template)
2. [Intune Remediation Template](#intune-remediation-template)
3. [WPF GUI Tool Template](#wpf-gui-tool-template)
4. [CLI Script Template](#cli-script-template)
5. [Badge Reference](#badge-reference)
6. [Section Examples](#section-examples)

---

## Basic Template

```markdown
# 🌐 [Project Name] – [Brief Description]

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
---

# 📖 Overview

**[Project Name]** is a [brief description of what the tool does].

[Explain the purpose and use case in 2-3 sentences. Mention the problem it solves.]

---

# ✨ Core Features

### 🔹 [Feature 1]
* [Detail 1]
* [Detail 2]

### 🔹 [Feature 2]
* [Detail 1]
* [Detail 2]

---

# 📂 Project Structure

```text
[Project Name]
│
├── [Script1].ps1
├── [Script2].ps1
└── README.md
```

---

# 🚀 Scripts Included

## 🔎 [Script Name]

**File**
```powershell
[ScriptName].ps1
```

### Purpose
[What this script does]

### Logic
1. [Step 1]
2. [Step 2]

### Exit Codes
| Code | Status |
| ---- | ------ |
| 0    | Success |
| 1    | Failure |

### Example
```powershell
.\[ScriptName].ps1
```

---

# ⚙️ Requirements

### Operating System
* Windows 10
* Windows 11

### PowerShell
* PowerShell **5.1 or later**

### Permissions
* [Required permissions]

---

# 🛡 Operational Notes
* [Important note 1]
* [Important note 2]

---

## 📜 License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 👤 Author
**[Your Name]**  
Website: [Your Website]  
Version: **[Version]**  

---

## ⚠ Disclaimer

These scripts are provided as-is. Test them in a staging environment before applying them to production. The author is not responsible for any unintended outcomes resulting from their use.

---

⭐ If this project helps you, please give it a star! ⭐
```

---

## Intune Remediation Template

For Intune Proactive Remediation packages (Detection + Remediation pairs):

> **File naming is canonical:** `detect-<solution-name>.ps1` / `remediate-<solution-name>.ps1` (and `notify-<name>.ps1` for notification scripts). Never `[Solution Name]--Detect.ps1` style names.

```markdown
# 🌐 [Solution Name] – [Brief Description]

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
![Automation](https://img.shields.io/badge/Intune-Proactive%20Remediation-brightgreen.svg)
![Mode](https://img.shields.io/badge/Automation-[Mode]-lightgrey.svg)
![Version](https://img.shields.io/badge/version-[Version]-green.svg)
---

# 📖 Overview

**[Solution Name]** is an Intune remediation package that [what it does].

[Explain the detection and remediation flow.]

---

# ✨ Core Features

### 🔹 [Feature 1]
* [Detail 1]
* [Detail 2]

### 🔹 [Feature 2]
* [Detail 1]
* [Detail 2]

---

# 📂 Project Structure

```text
[Solution Name]
│
├── detect-&lt;solution-name&gt;.ps1
├── remediate-&lt;solution-name&gt;.ps1
└── README.md
```

---

# 🚀 Scripts Included

## 🔎 Detection Script

**File**
```powershell
detect-&lt;solution-name&gt;.ps1
```

### Purpose
[What the detection script does]

### Logic
1. [Step 1]
2. [Step 2]

### Exit Codes
| Code | Status |
| ---- | ------ |
| 0    | Compliant (no remediation needed) |
| 1    | Non-compliant (triggers remediation) |

### Example
```powershell
.\detect-&lt;solution-name&gt;.ps1
```

---

## 🛠 Remediation Script

**File**
```powershell
remediate-&lt;solution-name&gt;.ps1
```

### Purpose
[What the remediation script does]

### Actions
1. [Step 1]
2. [Step 2]

### Key References
* [Command or API used]

### Example
```powershell
.\remediate-&lt;solution-name&gt;.ps1
```

---

# ⚙️ Requirements

### Operating System
* Windows 10
* Windows 11

### PowerShell
* PowerShell **5.1 or later**

### Permissions
* [Required permissions]

### Logging
* Logs are written under `<SystemDrive>\IntuneLogs\[Solution Name]`

---

# 🧭 Intune Deployment

This solution is intended for **Microsoft Intune Proactive Remediations**.

### Detection Script
```powershell
detect-&lt;solution-name&gt;.ps1
```

### Remediation Script
```powershell
remediate-&lt;solution-name&gt;.ps1
```

### Recommended Settings
| Setting | Value |
| ------- | ----- |
| Run script in 64-bit PowerShell | Yes |
| Run this script using logged-on credentials | [Review context requirements] |
| Enforce script signature check | No |

---

# 🔧 Typical Workflow
1. Intune runs the **Detection Script**
2. Detection exits with code `[0/1]`
3. Intune runs the **Remediation Script** (if needed)
4. Remediation completes and logs results

---

# 🛡 Operational Notes
* [Important note 1]
* [Important note 2]

---

## 📜 License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 👤 Author
**[Your Name]**  
Website: [Your Website]  
Version: **[Version]**  

---

## ⚠ Disclaimer

These scripts are provided as-is. Test them in a staging environment before applying them to production. The author is not responsible for any unintended outcomes resulting from their use.

---

⭐ If this project helps you, please give it a star! ⭐
```

---

## WPF GUI Tool Template

For WPF GUI tools following the enterprise design standard:

```markdown
# 🌐 [Tool Name] – [Brief Description]

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
![UI](https://img.shields.io/badge/UI-WPF%20GUI-blue.svg)
![Theme](https://img.shields.io/badge/Theme-Tailwind%20Slate-brightgreen.svg)
![Version](https://img.shields.io/badge/version-[Version]-green.svg)
---

# 📖 Overview

**[Tool Name]** is a [brief description] that provides a user-friendly interface for [task].

[Explain the purpose and use case.]

---

# ✨ Core Features

### 🔹 [Feature 1]
* [Detail 1]
* [Detail 2]

### 🔹 [Feature 2]
* [Detail 1]
* [Detail 2]

---

# 📂 Project Structure

```text
[Tool Name]
│
├── [ToolName].ps1
├── README.md
├── icon.png (optional)
└── Screenshot.png (optional)
```

---

# 🚀 Getting Started

### Prerequisites
* Windows 10/11
* PowerShell 5.1 or later

### Installation
1. Download `[ToolName].ps1`
2. Right-click → "Run with PowerShell"
3. Or run from PowerShell: `.\[ToolName].ps1`

---

# 🖥️ Usage

### Main Window
[Describe the main interface]

### Features
1. [Feature 1 description]
2. [Feature 2 description]

### Screenshots
![Main Window](Screenshot.png)

---

# ⚙️ Requirements

### Operating System
* Windows 10
* Windows 11

### PowerShell
* PowerShell **5.1 or later**

### Permissions
* [Required permissions]

---

# 🛡 Operational Notes
* [Important note 1]
* [Important note 2]

---

## 📜 License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 👤 Author
**[Your Name]**  
Website: [Your Website]  
Version: **[Version]**  

---

## ⚠ Disclaimer

These scripts are provided as-is. Test them in a staging environment before applying them to production. The author is not responsible for any unintended outcomes resulting from their use.

---

⭐ If this project helps you, please give it a star! ⭐
```

---

## CLI Script Template

For command-line scripts without GUI:

```markdown
# 🌐 [Script Name] – [Brief Description]

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
![Mode](https://img.shields.io/badge/Mode-CLI-lightgrey.svg)
![Version](https://img.shields.io/badge/version-[Version]-green.svg)
---

# 📖 Overview

**[Script Name]** is a PowerShell script that [what it does].

[Explain the purpose and use case.]

---

# ✨ Features

* [Feature 1]
* [Feature 2]
* [Feature 3]

---

# 🚀 Usage

### Basic Usage
```powershell
.\[ScriptName].ps1
```

### With Parameters
```powershell
.\[ScriptName].ps1 -ParameterName "Value"
```

### Examples
```powershell
# Example 1: [Description]
.\[ScriptName].ps1 -Param1 "Value1"

# Example 2: [Description]
.\[ScriptName].ps1 -Param2 "Value2"
```

---

# ⚙️ Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| Param1 | String | Yes | - | [Description] |
| Param2 | String | No | "Default" | [Description] |

---

# ⚙️ Requirements

### Operating System
* Windows 10
* Windows 11

### PowerShell
* PowerShell **5.1 or later**

### Permissions
* [Required permissions]

### Modules
* [Required modules]

---

# 🛡 Operational Notes
* [Important note 1]
* [Important note 2]

---

## 📜 License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 👤 Author
**[Your Name]**  
Website: [Your Website]  
Version: **[Version]**  

---

## ⚠ Disclaimer

These scripts are provided as-is. Test them in a staging environment before applying them to production. The author is not responsible for any unintended outcomes resulting from their use.

---

⭐ If this project helps you, please give it a star! ⭐
```

---

## Icon Policy
The header icon (first emoji before the title) must be **variable per script type**, not a fixed 🌐 for every README:
- **Standalone CLI** → 💻 or 📊
- **Intune Remediation** → 🛡️ or ☁️
- **WPF GUI** → 🖥️ or 🎨
- **Suite / Multi-tool** → 📦 or 🧰
Choose the icon that matches the script name/type so the README header is instantly distinguishable. Never use the same 🌐 for all.

## Badge Reference

### License Badge
```markdown
![License](https://img.shields.io/badge/license-MIT-blue.svg)
```

### PowerShell Version Badge
```markdown
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
```

### Platform Badge
```markdown
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
```

### Intune Automation Badge
```markdown
![Automation](https://img.shields.io/badge/Intune-Proactive%20Remediation-brightgreen.svg)
```

### Version Badge
```markdown
![Version](https://img.shields.io/badge/version-1.0-green.svg)
```

### UI Badge
```markdown
![UI](https://img.shields.io/badge/UI-WPF%20GUI-blue.svg)
```

### Theme Badge
```markdown
![Theme](https://img.shields.io/badge/Theme-Tailwind%20Slate-brightgreen.svg)
```

### Mode Badge
```markdown
![Mode](https://img.shields.io/badge/Mode-CLI-lightgrey.svg)
```

---

## Section Examples

### Overview Section
```markdown
# 📖 Overview

**Clear-DnsClientCache** is an Intune remediation package that flushes the Windows DNS client resolver cache whenever the package runs.

The detection script is intentionally designed to trigger remediation every time. It does not check DNS health, stale records, or network conditions. It simply exits with code `1`, which causes Intune to execute the remediation script.

This package is useful when you want a simple scheduled DNS cache reset without building a more complex diagnostic condition around it.
```

### Core Features Section
```markdown
# ✨ Core Features

### 🔹 Intentional Always-Run Detection
* Does not test DNS state
* Always returns exit code `1`
* Forces the remediation step to run on every scheduled execution

### 🔹 Native Windows Cache Flush
* Uses `ipconfig /flushdns`
* Relies on the built-in Windows DNS client behavior
* Does not restart services or change network settings
```

### Project Structure Section
```markdown
# 📂 Project Structure

```text
Clear-DnsClientCache
│
├── detect-Clear-DnsClientCache.ps1
├── remediate-Clear-DnsClientCache.ps1
└── README.md
```
```

### Exit Codes Table
```markdown
### Exit Codes
| Code | Status |
| ---- | ------ |
| 0    | Compliant (no remediation needed) |
| 1    | Non-compliant (triggers remediation) |
| 2    | Script error |
```

### Recommended Settings Table
```markdown
### Recommended Settings
| Setting | Value |
| ------- | ----- |
| Run script in 64-bit PowerShell | Yes |
| Run this script using logged-on credentials | Review your context requirements |
| Enforce script signature check | No |
```

---

## Writing Tips

1. **Use consistent section order**: Overview → Features → Structure → Scripts → Requirements → Deployment → Notes → License → Author
2. **Include badges**: Badges provide at-a-glance information about the project
3. **Use emojis**: Emojis make sections visually distinct and easier to scan
4. **Provide examples**: Always include usage examples with code blocks
5. **Specify language**: Use ```powershell for PowerShell code, ```text for file structures
6. **Use tables**: Tables are great for structured data like exit codes and settings
7. **Keep it concise**: Be clear and direct, avoid unnecessary words
8. **Include operational notes**: Document any important considerations or limitations
9. **Include a Disclaimer**: Every README carries the as-is Disclaimer section immediately before License — test-in-staging warning plus no-liability statement

