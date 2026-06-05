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
