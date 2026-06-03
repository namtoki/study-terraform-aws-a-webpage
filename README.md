# study-terraform-aws-a-webpage

Terraform × AWS のスタディプロジェクト。静的サイトから始まり、Rails + ECS + RDS のフルスタック構成まで段階的に構築する。

## スタディフェーズ

### 完了

| フェーズ | 内容 |
|---|---|
| Phase 1 | S3 + CloudFront（静的サイト配信） |
| Phase 3 | Lambda + API Gateway v2（動的 API） |

### 予定

| フェーズ | 内容 | 主要リソース |
|---|---|---|
| Phase 4 | Remote State | S3 + DynamoDB |
| Phase 5 | VPC | VPC / Subnet / NAT Gateway / IGW |
| Phase 6 | ECR + Docker | ECR / Dockerfile（Rails） |
| Phase 7 | RDS | RDS PostgreSQL / Security Group |
| Phase 8 | ECS Fargate + ALB | ECS / ALB / IAM |
| Phase 9 | CloudFront + カスタムドメイン | Route 53 / ACM / CloudFront |
| Phase 10 | ElastiCache | Redis（セッション / Sidekiq） |
| Phase 11 | CI/CD | GitHub Actions / OIDC |
| Phase 12 | 環境分離 | dev / prod モジュール構成 |

### 最終アーキテクチャ（Phase 12 完了時）

```
Internet
  ↓
Route 53 → CloudFront → ALB → ECS Fargate (Rails)
                                    ↓           ↓
                                   RDS      ElastiCache
                                (PostgreSQL)   (Redis)
                    S3 ← Active Storage（画像等）
```

---

## 現在の構成
```
.
├── terraform/
│   ├── providers.tf    # AWS / archive プロバイダー設定
│   ├── variables.tf    # 変数定義
│   ├── main.tf         # S3 + CloudFront + OAC + バケットポリシー
│   ├── lambda.tf       # IAM Role + Lambda 関数
│   ├── apigateway.tf   # API Gateway v2 (HTTP API)
│   └── outputs.tf      # URL・バケット名・API エンドポイントの出力
├── frontend/
│   └── index.html      # デプロイするページ（API 呼び出しデモ含む）
├── lambda/
│   └── handler.py      # Lambda 関数コード（Python）
└── deploy.sh           # S3 アップロード + CF キャッシュ削除
```

## AWS 構成（現在）

### 静的サイト（Phase 1）

| リソース | 説明 |
|---|---|
| `aws_s3_bucket` | 静的ファイルの格納先（パブリックアクセス全ブロック） |
| `aws_cloudfront_distribution` | HTTPS 配信・CDN |
| `aws_cloudfront_origin_access_control` | CloudFront のみ S3 へアクセス可能にする OAC |
| `aws_s3_bucket_policy` | OAC 経由のアクセスのみ許可するバケットポリシー |

### Lambda + API Gateway（Phase 3）

| リソース | 説明 |
|---|---|
| `aws_iam_role` | Lambda の実行ロール |
| `aws_iam_role_policy_attachment` | CloudWatch Logs 書き込み権限を付与 |
| `aws_lambda_function` | 動的処理の実装（Python 3.12） |
| `aws_lambda_permission` | API Gateway からの呼び出しを許可 |
| `aws_apigatewayv2_api` | HTTP API エンドポイント（CORS 設定済み） |
| `aws_apigatewayv2_integration` | API Gateway と Lambda を接続 |
| `aws_apigatewayv2_route` | `GET /hello` のルーティング |
| `aws_apigatewayv2_stage` | デプロイステージ（auto_deploy） |

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

# URL / バケット名 / API エンドポイントなどを確認
terraform output

# 特定の値だけ取得
terraform output cloudfront_url
terraform output bucket_name
terraform output api_endpoint

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

### Lambda の確認・デバッグ

```bash
# Lambda を直接テスト実行
aws lambda invoke \
  --function-name $(terraform -chdir=terraform output -raw project_name)-api \
  --payload '{}' \
  /tmp/response.json && cat /tmp/response.json

# API エンドポイントに curl でアクセス確認
API=$(terraform -chdir=terraform output -raw api_endpoint)
curl $API

# Lambda のログを確認（直近5分）
aws logs tail /aws/lambda/$(terraform -chdir=terraform output -raw project_name)-api --since 5m
```

### 確認・デバッグ（静的サイト）

```bash
# S3 の中身を確認
BUCKET=$(terraform -chdir=terraform output -raw bucket_name)
aws s3 ls s3://$BUCKET/

# CloudFront のキャッシュ削除状況を確認
DIST_ID=$(terraform -chdir=terraform output -raw cloudfront_distribution_id)
aws cloudfront list-invalidations --distribution-id $DIST_ID

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
terraform state show aws_cloudfront_distribution.terraaws
terraform state show aws_lambda_function.api

# 実際の AWS と差分がないか確認（apply なし）
terraform refresh
terraform plan
```

### よくあるシナリオまとめ

| シナリオ | コマンド |
|---|---|
| 初回構築 | `terraform init` → `terraform apply` → `./deploy.sh` |
| ページ内容を更新 | `./deploy.sh` |
| Lambda コードを更新 | `lambda/handler.py` を編集 → `terraform apply` → `./deploy.sh` |
| Terraform の設定を変えた | `terraform plan` → `terraform apply` |
| URL を確認したい | `terraform output cloudfront_url` |
| API エンドポイントを確認したい | `terraform output api_endpoint` |
| 課金を止めたい | `terraform destroy` |
| キャッシュが古い | `./deploy.sh`（内部で invalidation 実行） |
