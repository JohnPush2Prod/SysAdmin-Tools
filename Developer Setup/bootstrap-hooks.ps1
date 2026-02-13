$ErrorActionPreference = "Stop"

if (-not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
    Write-Error "pre-commit is required. Install it first: pip install pre-commit"
    exit 1
}

Write-Host "Installing git hooks with pre-commit..."

pre-commit install
pre-commit install --hook-type pre-push

Write-Host "✅ Git hooks installed successfully."
