#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/infrastructure/terraform"

echo "================================================================="
echo "🔥 VideoForge - Complete AWS Infrastructure Teardown"
echo "================================================================="

if [ -d "$TERRAFORM_DIR" ]; then
  cd "$TERRAFORM_DIR"
  echo "💥 Executing terraform destroy..."
  terraform destroy -auto-approve
  echo "================================================================="
  echo "✅ AWS Infrastructure successfully destroyed."
  echo "================================================================="
else
  echo "❌ Error: Terraform directory not found."
  exit 1
fi
