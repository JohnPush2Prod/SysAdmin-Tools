# SysAdmin-Tools
Useful scripts, tools, and documentation for SystemsAdministrators


## Security: Secret Prevention

This repository enforces secret scanning using TruffleHog.

## Developer Setup (Required)

This repository prevents secrets from being committed or pushed.

### One-time setup
```powershell
pip install pre-commit
.\scripts\bootstrap-hooks.ps1

