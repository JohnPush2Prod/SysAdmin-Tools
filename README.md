# SysAdmin-Tools

A collection of useful scripts, tools, and documentation for Systems Administrators.

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
