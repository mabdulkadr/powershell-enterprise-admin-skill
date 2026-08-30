<div align="center">

# 📦 [Suite Name]

**[Brief Description]**

[One sentence explaining what the script does and for whom.]

[![Tools](https://img.shields.io/badge/Tools-[N]%20Tools-10B981?style=for-the-badge)](#-scripts-included)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/en-us/powershell/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0F172A?style=for-the-badge)](#-requirements)
[![License](https://img.shields.io/badge/License-MIT-F59E0B?style=for-the-badge)](#-license)
[![Version](https://img.shields.io/badge/Version-1.0.0-334155?style=for-the-badge)](#-overview)

[Overview](#-overview) • [Features](#-core-features) • [Scripts](#-scripts-included) • [Requirements](#-requirements) • [License](#-license)

</div>

> Suite README rule: document each script at its own scope. Do NOT add a global
> 🧭 Intune Deployment section here — that belongs exclusively to the Intune
> pair's own README (link to it instead, as below).

---

# 📖 Overview

**[Suite Name]** is a toolkit of [N] enterprise tools for [domain].

---

# ✨ Core Features

### 🔹 [Tool 1] ([Type])
* [Detail]

### 🔹 [Tool 2] ([Type])
* [Detail]

---

# 📂 Project Structure

```text
[Suite Name]
│
├── [Tool1].ps1
├── IntuneRemediation\
│   ├── detect-[name].ps1
│   ├── remediate-[name].ps1
│   └── README.md   ← Intune deployment guidance lives HERE only
└── README.md
```

---

# 🚀 Scripts Included

## 🔎 [Tool 1] (CLI)

**File**
```powershell
[Tool1].ps1
```

### Purpose / Logic / Exit Codes / Example
[Per-script sections — keep each script's own contract in its own block.]

| Code | Status |
| ---- | ------ |
| 0    | Success |
| 1    | Failure |

## 🖥️ [Tool 2] (GUI)

**File**
```powershell
[Tool2].ps1
```

### Purpose / Exit Codes / Example
[Per-script sections.]

---

# ⚙️ Requirements

### Operating System
* Windows 10 / Windows 11 / Windows Server 2016+ (CLI tools)

### PowerShell
* PowerShell **5.1 or later**

### Permissions
* [Per-tool summary]

> 🧭 **Intune deployment guidance** lives exclusively in
> [`IntuneRemediation\README.md`](IntuneRemediation/README.md).

---

# 🛡 Operational Notes
* [Important note 1]
* [Important note 2]

---

## 👤 Author

**[Your Name]**  
GitHub: [@your-handle](https://github.com/your-handle)  
Website: [Your Website]  

---

## 📜 License
This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## ⚠ Disclaimer

This skill and every script it generates are provided as-is with no warranty of any kind. Test generated tools in a staging environment before deploying to production. The authors assume no liability for any damage or data loss resulting from their use.

---
<div align="center">

⭐ **If this skill saves you time, star the repo — it helps others find it.**

[Report an Issue](../../issues) · [momar.tech](https://momar.tech)

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/mabdulkadrx)

Built with [**PowerShell Enterprise Admin**](https://github.com/mabdulkadr/powershell-enterprise-admin-skill)

</div>