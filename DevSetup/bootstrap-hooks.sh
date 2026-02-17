#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrapping pre-commit + TruffleHog hooks..."

# Check: Git
command -v git >/dev/null || {
  echo "Git is required but not installed."
  exit 1
}

# Check: Python / pip
command -v pip >/dev/null || {
  echo "pip is required. Install Python first."
  exit 1
}

# Check: pre-commit
if ! command -v pre-commit >/dev/null; then
  echo "Installing pre-commit..."
  pip install --user pre-commit
else
  echo "pre-commit already installed"
fi

# Check: TruffleHog
command -v trufflehog >/dev/null || {
  echo "TruffleHog not found. Install it first:"
  echo "https://github.com/trufflesecurity/trufflehog"
  exit 1
}

echo "TruffleHog found: $(trufflehog --version)"

# Install git hooks
pre-commit install
pre-commit install --hook-type pre-push

echo "Git hooks installed successfully."

# Optional sanity check
pre-commit run --all-files || echo "Pre-commit reported findings (expected if secrets exist)."

echo "Pre-commit setup complete."
