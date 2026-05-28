# ------------------------------------------------
# ECR
# ------------------------------------------------
output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

# ------------------------------------------------
# VPC
# ------------------------------------------------
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.vpc.private_db_subnet_ids
}

# ------------------------------------------------
# Route53
# ------------------------------------------------
output "route53_zone_id" {
  value = module.route53.zone_id
}

output "route53_name_servers" {
  value = module.route53.name_servers
}

# ------------------------------------------------
# ACM
# ------------------------------------------------
output "acm_certificate_arn" {
  value = module.acm.certificate_arn
}

# ------------------------------------------------
# ALB
# ------------------------------------------------
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_zone_id" {
  value = module.alb.alb_zone_id
}

output "blue_target_group_arn" {
  value = module.alb.blue_target_group_arn
}

output "green_target_group_arn" {
  value = module.alb.green_target_group_arn
}

output "https_listener_arn" {
  value = module.alb.https_listener_arn
}

output "test_listener_arn" {
  value = module.alb.test_listener_arn
}

# ------------------------------------------------
# RDS
# ------------------------------------------------
output "rds_endpoint" {
  value     = module.rds_mariadb.endpoint
  sensitive = true
}

output "rds_port" {
  value = module.rds_mariadb.port
}