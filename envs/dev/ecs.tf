# ------------------------------------------------
# ECS
# ------------------------------------------------
module "ecs" {
  source     = "../../modules/container/ecs"
  env        = var.env
  system     = var.system
  department = var.department

  ecs_security_group_id = module.sg_ecs.security_group_id
  private_subnet_ids = [
    module.vpc.private_subnet_ids["ap-northeast-1a-app"],
    module.vpc.private_subnet_ids["ap-northeast-1c-app"],
  ]

  task_role_arn = module.iam_ecs.task_role_arn
  exec_role_arn = module.iam_ecs.exec_role_arn

  domain = var.domain

  nginx_image_uri = module.ecr.repository_urls["nginx"]
  app_image_uri   = module.ecr.repository_urls["app"]

  blue_target_group_arn  = module.alb.blue_target_group_arn
  green_target_group_arn = module.alb.green_target_group_arn
  https_listener_arn     = module.alb.https_listener_arn
  test_listener_arn      = module.alb.test_listener_arn

  # SSM Parameter Store ARNs
  db_host_ssm_arn     = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/host"]
  db_database_ssm_arn = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/database"]
  db_username_ssm_arn = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/username"]
  db_password_ssm_arn = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/password"]
  app_key_ssm_arn     = module.ssm.parameter_arns["/dev/portfolio/app/key"]

  # サイジング
  task_cpu     = 512
  task_memory  = 1024
  nginx_cpu    = 256
  nginx_memory = 512
  app_cpu      = 256
  app_memory   = 512

  # Auto Scaling
  desired_count           = 2
  min_capacity            = 2
  max_capacity            = 4
  cpu_scale_out_threshold = 80

  # ログ
  log_retention_days = 30
}