# study-terraform-aws-a-webpage

S3 + CloudFront によるプライベート静的 Web サイトを Terraform で構築する学習プロジェクト。

## 構成

```
.
├── terraform/
│   ├── providers.tf   # AWS プロバイダー設定
│   ├── variables.tf   # 変数定義
│   ├── main.tf        # S3 + CloudFront + OAC + バケットポリシー
│   └── outputs.tf     # URL・バケット名の出力
├── frontend/
│   └── index.html     # デプロイするページ
└── deploy.sh          # S3 アップロード + CF キャッシュ削除
```

## AWS 構成

| リソース | 説明 |
|---|---|
| `aws_s3_bucket` | 静的ファイルの格納先（パブリックアクセス全ブロック） |
| `aws_cloudfront_distribution` | HTTPS 配信・CDN |
| `aws_cloudfront_origin_access_control` | CloudFront のみ S3 へアクセス可能にする OAC |
| `aws_s3_bucket_policy` | OAC 経由のアクセスのみ許可するバケットポリシー |

---

## コマンドライン一覧

### 初回セットアップ（1回だけ）

```bash
# Terraform の初期化（プロバイダーのダウンロード）
cd terraform
terraform init
```

### インフラの操作（Terraform）

```bash
cd terraform

# 変更内容を事前確認（何も作らない）
terraform plan

# インフラを構築・更新
terraform apply

# URL / バケット名 / Distribution ID を確認
terraform output

# 特定の値だけ取得
terraform output cloudfront_url
terraform output bucket_name

# インフラを全削除（課金停止したいとき）
terraform destroy
```

### フロントエンドのデプロイ

```bash
# index.html を更新したあと → S3 に同期してキャッシュ削除
./deploy.sh

# deploy.sh を使わず手動でやる場合
BUCKET=$(terraform -chdir=terraform output -raw bucket_name)
aws s3 sync frontend/ s3://$BUCKET/ --delete

# キャッシュ削除だけしたい場合
DIST_ID=$(terraform -chdir=terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### 確認・デバッグ

```bash
# S3 の中身を確認
BUCKET=$(terraform -chdir=terraform output -raw bucket_name)
aws s3 ls s3://$BUCKET/

# CloudFront のキャッシュ削除状況を確認
DIST_ID=$(terraform -chdir=terraform output -raw cloudfront_distribution_id)
aws cloudfront list-invalidations --distribution-id $DIST_ID

# CloudFront のディストリビューション詳細を確認
aws cloudfront get-distribution --id $DIST_ID

# ページに直接 curl でアクセス確認
URL=$(terraform -chdir=terraform output -raw cloudfront_url)
curl -I $URL
```

### Terraform の状態管理

```bash
cd terraform

# 現在 Terraform が管理しているリソース一覧
terraform state list

# 特定リソースの詳細を確認
terraform state show aws_cloudfront_distribution.dashboard

# 実際の AWS と差分がないか確認（apply なし）
terraform refresh
terraform plan
```

### よくあるシナリオまとめ

| シナリオ | コマンド |
|---|---|
| 初回構築 | `terraform init` → `terraform apply` → `./deploy.sh` |
| ページ内容を更新 | `./deploy.sh` |
| Terraform の設定を変えた | `terraform plan` → `terraform apply` |
| URL を確認したい | `terraform output cloudfront_url` |
| 課金を止めたい | `terraform destroy` |
| キャッシュが古い | `./deploy.sh`（内部で invalidation 実行） |
