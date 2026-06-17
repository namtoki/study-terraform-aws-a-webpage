# ===== ACM 証明書（CloudFront 用）=====
# CloudFront に使う証明書は必ず us-east-1 に作成する必要がある
# → provider = aws.us_east_1 を指定

resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  # 更新時に古い証明書を削除する前に新しい証明書を作成する（ダウンタイムを防ぐ）
  lifecycle {
    create_before_destroy = true
  }

  tags = { Project = var.project_name }
}

# DNS 検証レコードを Route 53 に自動作成
# domain_validation_options はドメイン（apex + www）ごとに 1 件ずつ返ってくる
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

# 証明書の検証完了を待つ（この resource の ARN を CloudFront に渡す）
resource "aws_acm_certificate_validation" "cloudfront" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}
