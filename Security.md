## Security Overview

This repository uses the following enforcement layers and security controls to prevent secret leaks and
vulnerable dependencies before commits are pushed to main.

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
