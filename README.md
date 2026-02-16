# SysAdmin-Tools

A collection of useful scripts, tools, and documentation for Systems Administrators.

---

## AI & Content Notice 

Portions of this content have been generated or assisted by AI systems**.
All AI‑assisted content has be reviewed and approved by a human prior to being commited**.
Files and code in this Repository are provided as-is and may modify system configuration, files, or data**.
Do NOT run this code unless you fully understand what it does and have reviewed it for safety, correctness, and suitability for your environment**.

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
