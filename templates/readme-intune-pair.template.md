<div align="center">

# 🛡️ [Solution Name]

**Intune Proactive Remediation Pair**

[One sentence on what the package detects and remediates.]

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue.svg)
![Platform](https://img.shields.io/badge/Windows-10%2F11-blue.svg)
![Automation](https://img.shields.io/badge/Intune-Proactive%20Remediation-brightgreen.svg)
![Version](https://img.shields.io/badge/version-[Version]-green.svg)

</div>

---

# 📖 Overview

**[Solution Name]** is an Intune remediation package that [what it does].

[Explain the detection and remediation flow.]

---

# ✨ Core Features

### 🔹 [Feature 1]
* [Detail 1]
* [Detail 2]

---

# 📂 Project Structure

```text
[Solution Name]
│
├── detect-[solution-name].ps1
├── remediate-[solution-name].ps1
└── README.md
```

---

# 🚀 Scripts Included

## 🔎 Detection Script

**File**
```powershell
detect-[solution-name].ps1
```

### Purpose
[What the detection checks - read-only, never modifies the system.]

### Logic
1. [Check step 1]
2. [Check step 2]

### Exit Codes
| Code | Status |
| ---- | ------ |
| 0    | Compliant (no remediation needed) |
| 1    | Non-compliant (triggers remediation) |
| 2    | Script error |

## 🛠 Remediation Script

**File**
```powershell
remediate-[solution-name].ps1
```

### Purpose
[What the remediation fixes, with pre-check → fix → post-verify flow.]

### Exit Codes
| Code | Status |
| ---- | ------ |
| 0    | Success (fix applied and verified) |
| 1    | Failure (verification failed) |
| 2    | Script error |

---

# ⚙️ Requirements

### Operating System
* Windows 10 / Windows 11

### PowerShell
* PowerShell **5.1 or later**

### Permissions
* Runs in local SYSTEM context via Intune — no Graph permissions required.

### Logging
* `<SystemDrive>\IntuneLogs\[Solution-Name]\`

---

# 🧭 Intune Deployment

This section exists ONLY in the Intune pair's README — never in GUI or standalone CLI READMEs.

### Detection Script
```powershell
detect-[solution-name].ps1
```

### Remediation Script
```powershell
remediate-[solution-name].ps1
```

### Recommended Settings
| Setting | Value |
| ------- | ----- |
| Run script in 64-bit PowerShell | Yes |
| Run this script using logged-on credentials | No (SYSTEM context) |
| Enforce script signature check | No |

---

# 🔧 Typical Workflow
1. Intune runs the **Detection Script**
2. Detection exits with code `[0/1]`
3. If non-compliant, Intune runs the **Remediation Script**
4. Remediation applies the fix, verifies it, and logs results

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