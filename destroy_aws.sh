#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/infrastructure/terraform"

echo "================================================================="
echo "🔥 VideoForge - Destrucción Completa de Infraestructura en AWS"
echo "================================================================="

if [ -d "$TERRAFORM_DIR" ]; then
  cd "$TERRAFORM_DIR"
  echo "💥 Ejecutando terraform destroy..."
  terraform destroy -auto-approve
  echo "================================================================="
  echo "✅ Infraestructura en AWS destruida con éxito."
  echo "================================================================="
else
  echo "❌ Error: Directorio de Terraform no encontrado."
  exit 1
fi
