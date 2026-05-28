module "naming" {
  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "dns"
  resource   = "route53"
  department = var.department
}

# ホストゾーン
resource "aws_route53_zone" "this" {
  name = var.domain
  tags = module.naming.tags
}

# ALB Aliasレコード（ALB作成後に有効化）
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}