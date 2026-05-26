output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.dashboard.id
}

output "cloudfront_url" {
  description = "ダッシュボードURL (ブックマーク用)"
  value       = "https://${aws_cloudfront_distribution.dashboard.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (キャッシュ削除に使用)"
  value       = aws_cloudfront_distribution.dashboard.id
}
