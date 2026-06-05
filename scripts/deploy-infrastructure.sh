#!/bin/bash
# ============================================================
# deploy-infrastructure.sh
# Manual Terraform infrastructure deployment script
# Usage: ./scripts/deploy-infrastructure.sh [plan|apply|destroy]
# Default action: plan
# ============================================================

set -euo pipefail

ACTION="${1:-plan}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$(dirname "$SCRIPT_DIR")/terraform"
AWS_REGION="us-east-1"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  StartTech Infrastructure Deployment"
echo "  Action : $ACTION"
echo "  TF Dir : $TF_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Validate AWS credentials are configured
echo "[pre-flight] Validating AWS credentials..."
IDENTITY=$(aws sts get-caller-identity --output json)
ACCOUNT=$(echo "$IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
USER=$(echo "$IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
echo "  Account : $ACCOUNT"
echo "  Identity: $USER"
echo "  Region  : $AWS_REGION"

# Validate required env vars for sensitive variables
if [ -z "${TF_VAR_mongo_uri:-}" ]; then
  echo ""
  echo "❌ TF_VAR_mongo_uri is not set."
  echo "   Export it before running:"
  echo "   export TF_VAR_mongo_uri='mongodb+srv://...'"
  exit 1
fi

if [ -z "${TF_VAR_jwt_secret_key:-}" ]; then
  echo ""
  echo "❌ TF_VAR_jwt_secret_key is not set."
  echo "   Export it before running:"
  echo "   export TF_VAR_jwt_secret_key='your-secret'"
  exit 1
fi

cd "$TF_DIR"

echo ""
echo "[1/4] Terraform Init..."
terraform init -input=false

echo ""
echo "[2/4] Terraform Format Check..."
terraform fmt -check -recursive || {
  echo "⚠️  Format issues found. Run: terraform fmt -recursive"
}

echo ""
echo "[3/4] Terraform Validate..."
terraform validate

echo ""
case "$ACTION" in
  plan)
    echo "[4/4] Terraform Plan..."
    terraform plan -input=false -out=tfplan
    echo ""
    echo "✅ Plan complete. Review above."
    echo "   To apply: $0 apply"
    ;;

  apply)
    echo "[4/4] Terraform Apply..."
    if [ -f tfplan ]; then
      echo "Using existing plan file: tfplan"
      terraform apply -input=false -auto-approve tfplan
    else
      echo "No plan file found — generating and applying..."
      terraform plan -input=false -out=tfplan
      terraform apply -input=false -auto-approve tfplan
    fi
    echo ""
    echo "✅ Infrastructure apply complete!"
    echo ""
    echo "Outputs:"
    terraform output
    ;;

  destroy)
    echo "[4/4] Terraform Destroy..."
    echo ""
    echo "⚠️  WARNING: This will DESTROY all infrastructure!"
    read -r -p "Type 'destroy' to confirm: " CONFIRM
    if [ "$CONFIRM" != "destroy" ]; then
      echo "Cancelled."
      exit 0
    fi
    terraform destroy -input=false -auto-approve
    echo "✅ Infrastructure destroyed."
    ;;

  *)
    echo "❌ Unknown action: $ACTION"
    echo "   Usage: $0 [plan|apply|destroy]"
    exit 1
    ;;
esac
