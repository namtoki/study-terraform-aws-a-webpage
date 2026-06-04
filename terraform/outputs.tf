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
