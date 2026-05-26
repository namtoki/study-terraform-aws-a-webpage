#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

BUCKET=$(terraform -chdir="$TF_DIR" output -raw bucket_name)
DIST_ID=$(terraform -chdir="$TF_DIR" output -raw cloudfront_distribution_id)
URL=$(terraform -chdir="$TF_DIR" output -raw cloudfront_url)

echo "==> S3 にアップロード中... ($BUCKET)"
aws s3 sync "$FRONTEND_DIR/" "s3://$BUCKET/" --delete

echo "==> CloudFront キャッシュを削除中..."
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

echo ""
echo "デプロイ完了!"
echo "URL: $URL"
