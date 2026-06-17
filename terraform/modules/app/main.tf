# ─── S3 ─────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "terraaws" {
  bucket_prefix = "${var.project_name}-"
  force_destroy = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "terraaws" {
  bucket = aws_s3_bucket.terraaws.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraaws" {
  bucket = aws_s3_bucket.terraaws.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ─── CloudFront ──────────────────────────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "terraaws" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "terraaws" {
  origin {
    domain_name              = aws_s3_bucket.terraaws.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.terraaws.id
  }

  enabled             = true
  default_root_object = "index.html"
  comment             = "Stock terraaws (private)"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # S3 が 403 を返したときも index.html にフォールバック
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [var.domain_name, "www.${var.domain_name}"]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Project = var.project_name
  }
}

# ─── S3 バケットポリシー (CloudFront OAC のみ許可) ───────────────────────────

resource "aws_s3_bucket_policy" "terraaws" {
  bucket = aws_s3_bucket.terraaws.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.terraaws.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.terraaws.arn
          }
        }
      }
    ]
  })

  # public access block を先に適用してからポリシーをアタッチ
  depends_on = [aws_s3_bucket_public_access_block.terraaws]
}
