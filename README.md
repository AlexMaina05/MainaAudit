# MainaAudit 🛡️
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Security](https://img.shields.io/badge/Audit-Cybersecurity-red)

> **alexmaina.dev** presents a high-level endpoint security assessment engine.
---

# MainaAudit v2.5 - Endpoint Security Auditor

MainaAudit is a professional-grade PowerShell security assessment tool designed for Windows endpoints. It performs a deep-dive analysis of the system's security posture, identifying vulnerabilities, misconfigurations, and potential exposures.

The tool generates a comprehensive PDF report with a final security score and a prioritized remediation plan.

## 🛡️ Key Audit Modules
- **Network Surface:** Detection of critical open ports (SMB, RPC, RDP) on public interfaces.
- **Identity & Access:** Local administrator accounts analysis and privilege escalation risks.
- **Disk Security:** BitLocker encryption status and protection integrity.
- **Patch Management:** Missing critical security updates via Windows Update API.
- **Persistence & Malware:** Detection of high-risk processes and unauthorized remote tools.
- **Wireless Security:** Analysis of insecure/open Wi-Fi profiles saved on the device.
- **System Integrity:** OS health checks via system event logs.

## 📊 Professional Reporting
The tool utilizes **Pandoc** and **XeLaTeX** with the **Eisvogel template** to produce high-quality, client-ready PDF reports including:
- Executive Summary with a calculated Security Score.
- Detailed technical findings table.
- **Dynamic Remediation Plan:** Customized advice based on specific detected vulnerabilities.

## 🛠️ Prerequisites
To generate the PDF reports, you need:
1. [Pandoc](https://pandoc.org/installing.html)
2. [MiKTeX](https://miktex.org/download) or another LaTeX distribution.
3. Administrator privileges (to access BitLocker and Security logs).

## 🚀 Usage
1. Clone the repository.
2. Run PowerShell as Administrator.
3. Execute the script:
   ```powershell
   ./Invoke-Audit.ps1

## 📜 Credits & Acknowledgments
- **Author:** [Alessandro Mainardi](https://alexmaina.dev)
- **PDF Template:** [Eisvogel](https://github.com/Wandmalfarbe/pandoc-latex-template) by Pascal Wagler.
- **Engines:** Powered by [Pandoc](https://pandoc.org/) and XeLaTeX.
- **AI Collaboration:** Developed with the support of Gemini AI for code optimization and security logic refinement.

## ⚖️ License
This project is for educational and professional audit purposes. Use it responsibly.
