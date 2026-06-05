# study-terraform-aws-a-webpage

Terraform × AWS のスタディプロジェクト。静的サイトから始まり、Rails API + ECS + RDS のフルスタック構成まで段階的に構築する。
最終的には高級オーディオ情報サイトを Web / iOS / Android のマルチクライアントで提供する。

## アプリ構成（API ファースト）

```
                    ┌─ Web    : Next.js (React + TypeScript)
Cognito（統一認証）─┼─ iOS    : React Native (Expo)
        ↓           └─ Android: React Native (Expo)
   Rails API モード (ECS Fargate)  ← JSON のみ返す
        ↓
   RDS / S3 / OpenSearch / Bedrock
```

- **Web**: Next.js（React + TypeScript）
- **Mobile**: React Native (Expo) — Web と React/TS を共有
- **Backend**: Rails API モード（HTML を返さず JSON API を提供）
- **Auth**: Cognito（Web・iOS・Android で統一）

## スタディフェーズ

### 完了

| フェーズ | 内容 |
|---|---|
| Phase 1 | S3 + CloudFront（静的サイト配信） |
| Phase 3 | Lambda + API Gateway v2（動的 API） |
| Phase 4 | Remote State（S3 + DynamoDB によるバックエンド） |
| Phase 5 | VPC（terraform-aws-modules/vpc） |
| Phase 6 | ECR + Docker（コンテナイメージ保管） |
| Phase 7 | RDS + Secrets 管理（コード確定済み・未 apply） |

### 予定

| フェーズ | 内容 | 主要リソース |
|---|---|---|
| Phase 8  | ECS Fargate + ALB | ECS / ALB / IAM |
| Phase 9  | Cognito | ユーザー登録・認証 / ALB 連携 |
| Phase 10 | CloudFront + カスタムドメイン | Route 53 / ACM / CloudFront |
| Phase 11 | ElastiCache | Redis（セッション / Sidekiq） |
| Phase 12 | 監視・トレーシング | CloudWatch（アラーム/ダッシュボード）/ X-Ray / EventBridge |
| Phase 13 | 非同期処理 | SQS / SNS / Step Functions |
| Phase 14 | OpenSearch | 機器・組み合わせの全文検索 |
| Phase 15 | Bedrock | AI による互換性・音質予想 |
| Phase 16 | 運用自動化・信頼性 | Systems Manager / AWS Config / CloudTrail / AWS Backup / RDS Multi-AZ・リードレプリカ / Auto Scaling |
| Phase 17 | CI/CD | CodePipeline / CodeBuild / CodeDeploy / GitHub Actions / OIDC |
| Phase 18 | 環境分離 | dev / prod モジュール構成 |

Phase 18 完了以降はアプリ開発（高級オーディオ情報サイト）に注力。

### 取得予定の AWS 認定

保有: CLF / AIF / SAA。本プロジェクトを通じて以下を取得予定。

| 認定 | 主な対応フェーズ |
|---|---|
| **Developer Associate (DVA-C02)** | Lambda / API GW / DynamoDB / ECS / Cognito（Phase 3・6〜9）/ Secrets（7）/ X-Ray（12）/ SQS・SNS・Step Functions（13）/ CI/CD（17） |
| **SysOps Administrator (SOA-C02)** | VPC（5）/ 監視（12）/ 運用自動化・信頼性（16）/ CloudFront・Route 53（10） |

### 最終アーキテクチャ（Phase 18 完了時）

```
Internet
  ↓
Route 53 → CloudFront → ALB → Cognito（認証）
                                    ↓
                               ECS Fargate (Rails)
                                    ↓              ↓
                                   RDS         ElastiCache
                              (PostgreSQL       (Redis)
                               Multi-AZ)
                                    ↓
                               OpenSearch（機器検索）
                               Bedrock（AI 音質予想）
                    S3 ← Active Storage（機器画像・ユーザー写真）

  非同期: ECS/Lambda → SQS/SNS → Step Functions（組み合わせ DB 更新・AI 予想）
  監視:   CloudWatch / X-Ray / EventBridge / CloudTrail / AWS Config
  運用:   Systems Manager / AWS Backup / Secrets Manager
```

---

## 現在の構成

```
.
├── terraform/
│   ├── bootstrap/          # Remote State 用リソース（S3 + DynamoDB）
│   │   ├── providers.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   ├── providers.tf        # AWS / archive プロバイダー / S3 バックエンド設定
│   ├── variables.tf        # 変数定義
│   ├── main.tf             # S3 + CloudFront + OAC + バケットポリシー
│   ├── vpc.tf              # VPC + Subnet + IGW + NAT Gateway（公式モジュール）
│   ├── ecr.tf              # ECR リポジトリ + ライフサイクルポリシー
│   ├── rds.tf              # RDS PostgreSQL + Secrets Manager + SSM Parameter
│   ├── lambda.tf           # IAM Role + Lambda 関数
│   ├── apigateway.tf       # API Gateway v2 (HTTP API)
│   └── outputs.tf          # URL・バケット名・API エンドポイントの出力
├── app/
│   └── Dockerfile          # Rails アプリのコンテナ定義
├── frontend/
│   └── index.html          # デプロイするページ（API 呼び出しデモ含む）
├── lambda/
│   └── handler.py          # Lambda 関数コード（Python）
└── deploy.sh               # S3 アップロード + CF キャッシュ削除
```

## AWS 構成（現在）

### Remote State（Phase 4）

| リソース | 説明 |
|---|---|
| `aws_s3_bucket` | tfstate 保存先（バージョニング・暗号化有効） |
| `aws_dynamodb_table` | state ロック用テーブル（LockID） |

bootstrap/ は独立した Terraform ルート。ローカル state で管理し、本体の backend に使う S3/DynamoDB を事前作成する。

### 静的サイト（Phase 1）

| リソース | 説明 |
|---|---|
| `aws_s3_bucket` | 静的ファイルの格納先（パブリックアクセス全ブロック） |
| `aws_cloudfront_distribution` | HTTPS 配信・CDN |
| `aws_cloudfront_origin_access_control` | CloudFront のみ S3 へアクセス可能にする OAC |
| `aws_s3_bucket_policy` | OAC 経由のアクセスのみ許可するバケットポリシー |

### ECR（Phase 6）

| リソース | 説明 |
|---|---|
| `aws_ecr_repository` | コンテナイメージの保存先 |
| `aws_ecr_lifecycle_policy` | 最新 10 世代のみ保持（古いイメージを自動削除） |

### VPC（Phase 5）

| リソース | 説明 |
|---|---|
| `module "vpc"` | VPC / Public・Private Subnet × 2AZ / IGW / NAT Gateway / Route Table（terraform-aws-modules/vpc） |

### RDS + Secrets（Phase 7）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `random_password` | DB パスワードを自動生成（英数字 32 桁） |
| `aws_db_subnet_group` | RDS を Private Subnet に配置 |
| `aws_security_group.rds` | VPC 内からの PostgreSQL(5432) のみ許可 |
| `aws_db_instance` | PostgreSQL 16 / db.t4g.micro / ストレージ暗号化 / 非公開 |
| `aws_secretsmanager_secret` | DB 接続情報（user/pass/host/port/dbname）を JSON で保管 |
| `aws_ssm_parameter` | 非機密の設定値（RAILS_ENV など） |

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

### Bootstrap（初回のみ・1回だけ）

```bash
# Remote State 用の S3 バケット・DynamoDB テーブルを作成
cd terraform/bootstrap
terraform init
terraform apply

# 作成されたバケット名を確認して providers.tf に反映
terraform output tfstate_bucket
```

### 初回セットアップ（1回だけ）

```bash
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
| 初回構築 | bootstrap `apply` → `terraform init` → `terraform apply` → `./deploy.sh` |
| ページ内容を更新 | `./deploy.sh` |
| Lambda コードを更新 | `lambda/handler.py` を編集 → `terraform apply` → `./deploy.sh` |
| Terraform の設定を変えた | `terraform plan` → `terraform apply` |
| URL を確認したい | `terraform output cloudfront_url` |
| API エンドポイントを確認したい | `terraform output api_endpoint` |
| 課金を止めたい | `terraform destroy` |
| キャッシュが古い | `./deploy.sh`（内部で invalidation 実行） |
