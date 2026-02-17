$ErrorActionPreference = "Stop"

Write-Host "🔧 Bootstrapping pre-commit + TruffleHog hooks..." -ForegroundColor Cyan

# Check: Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is required but not found on PATH."
    exit 1
}

# Check: Python / pip
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Error "pip is required. Install Python first: https://www.python.org/downloads/"
    exit 1
}

# Check: pre-commit
if (-not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
    Write-Host "Installing pre-commit via pip..." -ForegroundColor Yellow
    pip install pre-commit
} else {
    Write-Host "pre-commit already installed"
}

# Check: TruffleHog
if (-not (Get-Command trufflehog -ErrorAction SilentlyContinue)) {
    Write-Warning @"
TruffleHog is not installed or not on PATH.

Install one of the following:
  macOS (Homebrew):   brew install trufflehog
  Windows (Scoop):   scoop install trufflehog
  Windows (Choco):   choco install trufflehog
  Linux:             https://github.com/trufflesecurity/trufflehog
"@
    exit 1
} else {
    Write-Host "TruffleHog found: $(trufflehog --version)"
}

# Install git hooks
Write-Host "Installing git hooks with pre-commit..." -ForegroundColor Cyan

pre-commit install
pre-commit install --hook-type pre-push

Write-Host "Git hooks installed successfully." -ForegroundColor Green

# Optional: sanity check
Write-Host "Running a quick pre-commit dry run (no changes made)..." -ForegroundColor Cyan
pre-commit run --all-files || Write-Warning "Pre-commit reported findings (this is expected if secrets exist)."

Write-Host "Pre-commit setup complete." -ForegroundColor Green
