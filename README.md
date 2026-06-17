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

| フェーズ | 内容 | 何ができるか |
|---|---|---|
| Phase 1 | S3 + CloudFront（静的サイト配信） | 静的ページを HTTPS で世界配信 |
| Phase 3 | Lambda + API Gateway v2（動的 API） | サーバーレス API エンドポイントが動く |
| Phase 4 | Remote State（S3 + DynamoDB によるバックエンド） | チーム開発・複数環境で tfstate を安全共有 |
| Phase 5 | VPC（terraform-aws-modules/vpc） | DB・コンテナをインターネットから隔離した Private Subnet に置ける |
| Phase 6 | ECR + Docker（コンテナイメージ保管） | Rails コンテナイメージを AWS に保管・バージョン管理できる |
| Phase 7 | RDS + Secrets 管理（コード確定済み・未 apply） | Rails が接続できる PostgreSQL が Private Subnet に立つ。パスワードは AWS が自動管理 |
| Phase 8 | ECS Fargate + ALB（コード確定済み・未 apply） | Rails コンテナが常時稼働し、ALB 経由でインターネットから HTTP アクセスできる |
| Phase 9 | Cognito（ユーザー認証 / アプリ側 JWT 検証）（コード確定済み・未 apply） | Web / iOS / Android で共通のユーザー登録・ログインが動く。Rails API が JWT を検証できる |
| Phase 10 | CloudFront + カスタムドメイン（コード確定済み・未 apply） | `https://example.com` で HTTPS アクセスできる |
| Phase 11 | ElastiCache Redis（セッション / Sidekiq）（コード確定済み・未 apply） | Rails のセッション管理・Sidekiq バックグラウンドジョブが動く |
| Phase 12 | 監視・トレーシング（コード確定済み・未 apply） | CloudWatch アラート・ダッシュボード・X-Ray トレーシング・EventBridge 障害通知が動く |
| Phase 13 | 非同期処理（コード確定済み・未 apply） | SQS ジョブキューで重い処理を非同期化。メール送信・AI 予想ジョブをキューで管理できる |
| Phase 14 | OpenSearch（コード確定済み・未 apply） | 機器名・ブランド・スペックの全文検索が動く |
| Phase 15 | Bedrock（コード確定済み・未 apply） | AI による機器の互換性・音質の予想 API が動く |
| Phase 16 | 運用自動化・信頼性（コード確定済み・未 apply） | 障害時の自動復旧・トラフィック増加時の自動スケール・監査ログが揃う |
| Phase 17 | CI/CD（コード確定済み・未 apply） | git push だけで自動テスト・自動デプロイが動く |
| Phase 18 | 環境分離（コード確定済み・未 apply） | dev と prod を独立した Terraform 構成で管理できる |

### 予定

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
│   ├── alb.tf              # ALB + Target Group + Listener + SG
│   ├── ecs.tf              # ECS Cluster + Task Definition + Service + IAM Role
│   ├── cognito.tf          # Cognito User Pool + App Client（Web/Mobile）
│   ├── acm.tf              # ACM 証明書（us-east-1）+ DNS 検証レコード
│   ├── route53.tf          # Hosted Zone + A/AAAA エイリアスレコード
│   ├── elasticache.tf      # ElastiCache Redis + Subnet Group + SG + SSM
│   ├── monitoring.tf       # SNS + CloudWatch Alarms/Dashboard + X-Ray IAM + EventBridge
│   ├── sqs.tf              # SQS ジョブキュー + DLQ + IAM + SSM
│   ├── opensearch.tf       # OpenSearch ドメイン + SG + IAM + SSM
│   ├── bedrock.tf          # Bedrock IAM 権限 + SSM
│   ├── reliability.tf      # ECS Auto Scaling + AWS Backup + CloudTrail
│   ├── cicd.tf             # GitHub Actions OIDC + IAM Role
│   ├── lambda.tf           # IAM Role + Lambda 関数
│   ├── apigateway.tf       # API Gateway v2 (HTTP API)
│   ├── outputs.tf          # URL・バケット名・API エンドポイントの出力
│   └── envs/
│       ├── dev/            # dev 環境エントリーポイント（スケルトン）
│       └── prod/           # prod 環境エントリーポイント（スケルトン）
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
| `aws_db_subnet_group` | RDS を Private Subnet に配置 |
| `aws_security_group.rds` | ECS の SG からの PostgreSQL(5432) のみ許可 |
| `aws_db_instance` | PostgreSQL 16 / db.t4g.micro / ストレージ暗号化 / 非公開 |
| `manage_master_user_password` | パスワードを AWS が Secrets Manager で自動生成・自動ローテーション |
| `aws_ssm_parameter` | 非機密の接続情報（host/port/name）と設定値（RAILS_ENV） |

認証は `manage_master_user_password = true` により、AWS 管理の Secrets Manager シークレットを使用（tfstate に平文パスワードが残らない）。

### ALB + ECS Fargate（Phase 8）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_lb` | ALB（Public Subnet 配置・HTTP:80） |
| `aws_lb_target_group` | IP ターゲット（Fargate）/ ヘルスチェック `/up` |
| `aws_lb_listener` | 80 → Target Group へ転送 |
| `aws_ecs_cluster` | Fargate クラスター（Container Insights 有効） |
| `aws_ecs_task_definition` | cpu256/mem512 / Secrets・SSM から環境変数注入 |
| `aws_ecs_service` | Private Subnet で常時 1 タスク維持・ALB 連携 |
| `aws_iam_role`（execution / task） | ECR pull・Logs・Secrets 取得 / アプリ権限 |
| `aws_security_group`（alb / ecs） | Internet→ALB→ECS→RDS の SG チェーン |

SG チェーンで最小権限を実現: `ALB(80) → ECS(3000, ALB のみ) → RDS(5432, ECS のみ)`。

### Cognito（Phase 9）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_cognito_user_pool` | ユーザーディレクトリ（メールログイン / パスワードポリシー / メール検証） |
| `aws_cognito_user_pool_domain` | Hosted UI / トークンエンドポイント |
| `aws_cognito_user_pool_client.web` | Web(Next.js) 用・公開クライアント(PKCE) |
| `aws_cognito_user_pool_client.mobile` | Mobile(Expo) 用・公開クライアント(PKCE) |

認証方式は **アプリ側 JWT 検証**: クライアントが Cognito から JWT を取得 → `Bearer` トークンで API を叩き、Rails が署名・iss・aud・exp を検証。Web/iOS/Android で共通のトークンを使う。

### CloudFront + カスタムドメイン（Phase 10）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_route53_zone` | ドメインの Hosted Zone（ネームサーバーを返す） |
| `aws_acm_certificate` | SSL/TLS 証明書（us-east-1 / DNS 検証） |
| `aws_route53_record`（検証用） | ACM の DNS 検証レコードを Route 53 に自動登録 |
| `aws_acm_certificate_validation` | 証明書の検証完了を待つ |
| `aws_route53_record`（A/AAAA） | apex + www → CloudFront へのエイリアスレコード |
| `aws_cloudfront_distribution`（更新） | `aliases` + ACM 証明書を追加 |

apply 手順:
1. `terraform apply -var domain_name=<your-domain.com>`
2. `terraform output route53_nameservers` でネームサーバーを確認
3. ドメインレジストラの NS レコードを Route 53 のネームサーバーに変更
4. DNS 伝播後（数分〜48時間）、ACM 検証が完了して HTTPS が有効になる

### ElastiCache Redis（Phase 11）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_elasticache_subnet_group` | Redis を Private Subnet に配置 |
| `aws_security_group.elasticache` | ECS の SG からの Redis(6379) のみ許可 |
| `aws_elasticache_replication_group` | Redis 7.1 / cache.t4g.micro / シングルノード / 保存暗号化 |
| `aws_ssm_parameter.redis_url` | `redis://<endpoint>:6379/0` を ECS に注入 |

SG チェーン完成: `ALB(80) → ECS(3000) → RDS(5432) → ElastiCache(6379, ECS のみ)`。
Rails の `config/cable.yml`・`config/initializers/session_store.rb`・Sidekiq の接続先に `REDIS_URL` 環境変数を使う。

### 監視・トレーシング（Phase 12）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_sns_topic` | アラート通知先（メール購読） |
| `aws_cloudwatch_metric_alarm` × 6 | ECS CPU/Memory・ALB 5xx・RDS CPU/Storage・Lambda Errors |
| `aws_cloudwatch_dashboard` | ECS / ALB / RDS / Lambda を 1 画面で可視化 |
| `aws_iam_role_policy_attachment`（xray） | ECS タスクロールに `AWSXRayDaemonWriteAccess` を付与 |
| `aws_cloudwatch_event_rule` | ECS タスク STOPPED イベントを検知 |
| `aws_cloudwatch_event_target` | EventBridge → SNS で障害通知 |

X-Ray デーモンは ECS タスク内のサイドカーコンテナとして稼働。Rails アプリから `localhost:2000/UDP` にトレースを送ると X-Ray コンソールでサービスマップを確認できる。

apply 後に `alert_email` 宛に SNS 購読確認メールが届くので **Confirm subscription** をクリックすること。

### 非同期処理 SQS（Phase 13）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_sqs_queue.jobs` | Rails / Sidekiq 用ジョブキュー（Standard / Long Polling / 暗号化） |
| `aws_sqs_queue.jobs_dlq` | Dead Letter Queue（3回失敗で退避） |
| `aws_sqs_queue_policy` | ECS タスクロールからの操作のみ許可 |
| `aws_iam_role_policy.ecs_task_sqs` | ECS タスクロールに SQS 操作権限を付与 |
| `aws_ssm_parameter.sqs_job_queue_url` | `SQS_JOB_QUEUE_URL` を ECS タスクに注入 |

### OpenSearch（Phase 14）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_opensearch_domain` | OpenSearch 2.11 / t3.small / シングルノード / Private Subnet |
| `aws_security_group.opensearch` | ECS の SG からの HTTPS(443) のみ許可 |
| `aws_secretsmanager_secret.opensearch_master` | マスター認証情報を Secrets Manager で管理 |
| `aws_iam_role_policy.ecs_task_opensearch` | ECS タスクロールに OpenSearch 操作権限を付与 |
| `aws_ssm_parameter.opensearch_url` | `OPENSEARCH_URL` を ECS タスクに注入 |

### Bedrock（Phase 15）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_iam_role_policy.ecs_task_bedrock` | ECS タスクロールに Bedrock InvokeModel 権限を付与 |
| `aws_ssm_parameter.bedrock_region` | `BEDROCK_REGION` を ECS タスクに注入 |

Bedrock はマネージドサービスのため IAM 権限と SSM のみ。コンソールで使用するモデルを事前に有効化すること。

### 運用自動化・信頼性（Phase 16）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_appautoscaling_target` | ECS サービスをスケーリング対象に登録 |
| `aws_appautoscaling_policy` × 2 | CPU / メモリ 70% 超過でスケールアウト（最大 4 タスク） |
| `aws_backup_vault` | バックアップデータの保存先 |
| `aws_backup_plan` | RDS の日次バックアップ（02:00 UTC / 7 日保持） |
| `aws_backup_selection` | RDS インスタンスをバックアップ対象に登録 |
| `aws_cloudtrail` | 全リージョン・全 API コールを S3 に記録 |
| `aws_s3_bucket.cloudtrail` | CloudTrail ログ保存先（90 日でライフサイクル削除） |

### CI/CD: GitHub Actions OIDC（Phase 17）※コード確定済み・未 apply

| リソース | 説明 |
|---|---|
| `aws_iam_openid_connect_provider.github` | GitHub Actions の OIDC プロバイダー登録 |
| `aws_iam_role.github_actions` | GitHub Actions が AssumeRoleWithWebIdentity するロール |
| `aws_iam_role_policy.github_actions` | ECR push + ECS UpdateService 権限 |

apply 後に `terraform output github_actions_role_arn` で取得した ARN を GitHub リポジトリの Secrets に設定すること。

### 環境分離（Phase 18）※コード確定済み・未 apply

| ディレクトリ | 説明 |
|---|---|
| `terraform/envs/dev/` | dev 環境のエントリーポイント（スケルトン） |
| `terraform/envs/prod/` | prod 環境のエントリーポイント（スケルトン） |

現状は `terraform/` ルートを直接使用。将来的に `envs/` から `module "app"` を呼び出す構成に移行する。

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
