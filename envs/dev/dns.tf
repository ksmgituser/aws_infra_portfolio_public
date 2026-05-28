# ------------------------------------------------
# Route53
# ------------------------------------------------
module "route53" {
  source     = "../../modules/dns/route53"
  env        = var.env
  system     = var.system
  department = var.department

  domain       = var.domain
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}