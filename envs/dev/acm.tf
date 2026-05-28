# ------------------------------------------------
# ACM
# ------------------------------------------------
module "acm" {
  source     = "../../modules/security/acm"
  env        = var.env
  system     = var.system
  department = var.department

  domain  = var.domain
  zone_id = module.route53.zone_id
}