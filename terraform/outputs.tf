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
