#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
TMP_DIR="$SCRIPT_DIR/.deploy_tmp"

BUCKET=$(terraform -chdir="$TF_DIR" output -raw bucket_name)
DIST_ID=$(terraform -chdir="$TF_DIR" output -raw cloudfront_distribution_id)
URL=$(terraform -chdir="$TF_DIR" output -raw cloudfront_url)
API_ENDPOINT=$(terraform -chdir="$TF_DIR" output -raw api_endpoint)

# index.html の __API_ENDPOINT__ を実際の URL に置換してから upload
mkdir -p "$TMP_DIR"
sed "s|__API_ENDPOINT__|$API_ENDPOINT|g" "$FRONTEND_DIR/index.html" > "$TMP_DIR/index.html"

echo "==> S3 にアップロード中... ($BUCKET)"
aws s3 sync "$TMP_DIR/" "s3://$BUCKET/"
aws s3 sync "$FRONTEND_DIR/" "s3://$BUCKET/" --delete --exclude "index.html"

echo "==> CloudFront キャッシュを削除中..."
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

rm -rf "$TMP_DIR"

echo ""
echo "デプロイ完了!"
echo "サイト URL:         $URL"
echo "API エンドポイント: $API_ENDPOINT"
