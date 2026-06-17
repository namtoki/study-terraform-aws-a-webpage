output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.terraaws.id
}

output "cloudfront_url" {
  description = "サイト URL (ブックマーク用)"
  value       = "https://${aws_cloudfront_distribution.terraaws.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (キャッシュ削除に使用)"
  value       = aws_cloudfront_distribution.terraaws.id
}

output "api_endpoint" {
  description = "API Gateway エンドポイント URL"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/hello"
}

output "ecr_repository_url" {
  description = "ECR リポジトリ URL（docker push 先）"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "RDS の接続先エンドポイント（host:port）"
  value       = aws_db_instance.main.endpoint
}

output "db_master_secret_arn" {
  description = "RDS マスターユーザーの認証情報（AWS が Secrets Manager で自動管理）の ARN"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "alb_url" {
  description = "ALB の URL（Rails アプリのエンドポイント）"
  value       = "http://${aws_lb.main.dns_name}"
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_web_client_id" {
  description = "Web（Next.js）用 App Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "cognito_mobile_client_id" {
  description = "Mobile（Expo）用 App Client ID"
  value       = aws_cognito_user_pool_client.mobile.id
}

# Rails 側で JWT を検証するときの issuer。JWKS は {issuer}/.well-known/jwks.json
output "cognito_issuer" {
  description = "JWT の発行者 URL（aud=client_id, iss=この値 を検証）"
  value       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

output "cognito_hosted_ui_domain" {
  description = "Hosted UI / トークンエンドポイントのドメイン"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "route53_nameservers" {
  description = "ドメインレジストラに設定する NS レコード（ここを向けないと Route 53 が機能しない）"
  value       = aws_route53_zone.main.name_servers
}

output "custom_domain_url" {
  description = "カスタムドメインの URL（HTTPS）"
  value       = "https://${var.domain_name}"
}

output "redis_primary_endpoint" {
  description = "Redis のプライマリエンドポイント"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch ダッシュボード URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}"
}

output "sns_alerts_arn" {
  description = "アラート通知 SNS トピック ARN"
  value       = aws_sns_topic.alerts.arn
}

output "sqs_job_queue_url" {
  description = "SQS ジョブキュー URL（Rails / Sidekiq の接続先）"
  value       = aws_sqs_queue.jobs.url
}

output "sqs_dlq_url" {
  description = "SQS Dead Letter Queue URL（処理失敗メッセージの退避先）"
  value       = aws_sqs_queue.jobs_dlq.url
}

output "opensearch_endpoint" {
  description = "OpenSearch ドメインエンドポイント"
  value       = "https://${aws_opensearch_domain.main.endpoint}"
}

output "bedrock_enabled_region" {
  description = "Bedrock を利用するリージョン"
  value       = var.aws_region
}

output "cloudtrail_s3_bucket" {
  description = "CloudTrail ログの保存先 S3 バケット"
  value       = aws_s3_bucket.cloudtrail.id
}

output "backup_vault_arn" {
  description = "AWS Backup ボールト ARN"
  value       = aws_backup_vault.main.arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions が AssumeRole する IAM ロール ARN（workflow の aws-actions/configure-aws-credentials に設定）"
  value       = aws_iam_role.github_actions.arn
}
