module "naming" {
  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "security"
  resource   = "acm"
  department = var.department
}

# 証明書発行
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain
  validation_method = "DNS"
  tags              = module.naming.tags

  lifecycle {
    create_before_destroy = true
  }
}

# DNS検証用CNAMEレコード
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

# 検証完了まで待機
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}