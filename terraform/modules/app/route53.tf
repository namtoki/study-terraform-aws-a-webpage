# ===== Route 53 =====

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = { Project = var.project_name }
}

# apex ドメイン（example.com）→ CloudFront
resource "aws_route53_record" "apex_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.terraaws.domain_name
    zone_id                = aws_cloudfront_distribution.terraaws.hosted_zone_id
    evaluate_target_health = false
  }
}

# IPv6 対応（CloudFront は IPv6 をサポートしている）
resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.terraaws.domain_name
    zone_id                = aws_cloudfront_distribution.terraaws.hosted_zone_id
    evaluate_target_health = false
  }
}

# www サブドメイン → CloudFront
resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.terraaws.domain_name
    zone_id                = aws_cloudfront_distribution.terraaws.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.terraaws.domain_name
    zone_id                = aws_cloudfront_distribution.terraaws.hosted_zone_id
    evaluate_target_health = false
  }
}
