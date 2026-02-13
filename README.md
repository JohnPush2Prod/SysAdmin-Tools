# SysAdmin-Tools

A collection of useful scripts, tools, and documentation for Systems Administrators.

## Security Overview

This repository is protected by **defense‑in‑depth security controls** designed to prevent common supply‑chain and credential‑leak risks.

### Implemented Controls

- **Secret Prevention (Local + CI)**
  - TruffleHog runs in **blocking mode** to prevent secrets from being committed or pushed.
  - Local enforcement via `pre-commit` and `pre-push` hooks.
  - CI enforcement as a secondary control to catch bypasses.

- **Software Supply Chain Security**
  - **Syft** generates a Software Bill of Materials (SBOM).
  - **Grype** scans the SBOM for known vulnerabilities.
  - Vulnerability findings can fail builds based on severity.

These controls are intentionally enforced **before code reaches `main`** whenever possible.

---

## Developer Setup (Required)

This repository **blocks secrets before commit and push**.  
All contributors must install the required Git hooks.

### One‑Time Setup (Windows)

```powershell
pip install pre-commit
.\scripts\bootstrap-hooks.ps1
