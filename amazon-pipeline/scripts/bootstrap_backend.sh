#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/bootstrap_backend.sh <state_bucket> <lock_table> <region>
# Example: ./scripts/bootstrap_backend.sh spotify-terraform-state-bryan terraform-locks-spotify us-east-1

STATE_BUCKET=${1:-}
LOCK_TABLE=${2:-}
REGION=${3:-us-east-1}

if [[ -z "$STATE_BUCKET" || -z "$LOCK_TABLE" ]]; then
  echo "Usage: $0 <state_bucket> <lock_table> <region>" >&2
  exit 1
fi

echo "Ensuring S3 bucket '$STATE_BUCKET' exists in region '$REGION'..."
if aws s3api head-bucket --bucket "$STATE_BUCKET" >/dev/null 2>&1; then
  echo "Bucket already exists."
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "Bucket created."
fi

echo "Enabling versioning on '$STATE_BUCKET'..."
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" --versioning-configuration Status=Enabled

echo "Ensuring DynamoDB table '$LOCK_TABLE' exists..."
if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "Table already exists."
else
  aws dynamodb create-table \
    --table-name "$LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
  echo "Table created."
fi

echo "Backend bootstrap complete."
