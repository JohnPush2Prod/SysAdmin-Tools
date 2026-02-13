# SysAdmin-Tools

A collection of useful scripts, tools, and documentation for Systems Administrators.

---

## Security Overview

This repository uses defense-in-depth controls to prevent secret leaks and
vulnerable dependencies before code reaches main.

## Enforcement layers
- Developer workstation (pre-commit / pre-push)
- CI / Pull requests
- Nightly scans

## Security Controls
Secrets
-TruffleHog
  - Local: blocking via pre-commit
  - CI: report-only (audit and visibility)
  - Push/PR diff scans and nightly full repository scans
  
Supply Chain
- Syft: generates Software Bill of Materials (SBOM)
- Grype: scans SBOMs for known CVEs
- Runs on push, pull requests, and nightly schedules
---

## Developer Setup (Required)

This repository **blocks secrets before commit and push**.  
All contributors must install the required Git hooks.

### One‑Time Setup (Windows)

```powershell
pip install pre-commit
.\DevSetup\bootstrap-hooks.ps1
```
### One‑Time Setup (Linux)

```Python 
pip install --user pre-commit
pre-commit install
pre-commit install --hook-type pre-push
```
