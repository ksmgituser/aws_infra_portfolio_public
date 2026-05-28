module "alb" {
  source     = "../../modules/elb/alb"
  env        = var.env
  system     = var.system
  department = var.department

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = values(module.vpc.public_subnet_ids)
  certificate_arn    = module.acm.certificate_arn
  security_group_id  = module.alb_sg.security_group_id
  access_logs_bucket = module.s3_alb_logs.bucket_id
}