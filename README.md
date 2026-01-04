# FocusReport 🚀

**A powerful forensic activity auditing tool for macOS.**

FocusReport is designed to provide high-fidelity "Proof of Work" through detailed activity logging, resource usage breakdowns, and automated forensic reporting.

## 🎯 The Problem & Purpose

In the modern era of **Remote Work**, transparency is key. Many employees work from personal laptops, making it difficult for employers to verify actual productivity without intrusive monitoring. FocusReport bridges this gap by providing a non-invasive yet undeniable audit trail.

**The Workflow:**
1.  **Work**: The employee starts a session on their personal macOS device.
2.  **Verify**: The software automatically detects human activity using keystroke density and active application context (distinguishing between real work and idle/media playback).
3.  **Report**: At the end of the day/session, the employee generates an **encrypted PDF audit report** and emails it to the employer.
4.  **Pay**: The employer uses the forensic breakdown to verify the hours worked and process payments with full confidence in the reported activity.

FocusReport is designed for small teams and independent contractors who value trust and verifiable results.

---

## 🔒 Intellectual Property & Ownership

**FocusReport is the intellectual property of Akshun Chauhan.**

This project is shared for transparency and personal use. **Unauthorized resale, commercial redistribution, or rebranding of this software is strictly prohibited.** See the [LICENSE](LICENSE) file for full legal details.

---

## ✨ Key Features

- **Activity Timeline**: Accurate logging of application usage and window titles.
- **Context Awareness**: Captures active URLs (Chrome/Safari) and project paths.
- **Biometric/Human Validation**: Distinguishes between active human work and idle/media time.
- **Forensic PDF Export**: Generates password-protected, immutable audit reports.
- **Privacy First**: All data stays local on your machine.

## 🛠 Installation & Build

### Prerequisites
- macOS 13.0+
- Xcode 15.0+

### Building from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/AkshunChauhan/FocusReport.git
   ```
2. Open `FocusReport.xcodeproj` in Xcode.
3. Select your target and build (Cmd + R).

### Creating a DMG
Use the provided packaging script to create a distribution-ready DMG:
```bash
chmod +x package.sh
./package.sh
```

## 📋 System Requirements & Permissions
FocusReport requires standard macOS privacy permissions to function:
- **Accessibility**: To capture window titles and UI context.
- **Automation**: To fetch active URLs from browsers.
- **Input Monitoring**: To validate human activity via keystroke density (no text is logged).

## 🤝 Contributing
Contributions for bug fixes and feature improvements are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a PR.

---

