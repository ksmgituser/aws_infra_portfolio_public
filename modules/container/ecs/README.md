# Container module - ecs

## What this module does
- Creates an ECS Cluster (Fargate)
- Creates a Task Definition with nginx + php-fpm containers
- Creates an ECS Service with CodeDeploy Blue/Green deployment controller
- Configures Auto Scaling based on CPU utilization
- Creates CloudWatch Log Groups for nginx and php-fpm
- Creates a CodeDeploy application and deployment group for ECS Blue/Green

## Design decisions
- Deployment controller is `CODE_DEPLOY` — `force-new-deployment` cannot be used
- `task_definition` and `load_balancer` are in `ignore_changes` to avoid conflicts with CodeDeploy
- DB credentials are injected via SSM Parameter Store `secrets` (not hardcoded)
- ECS Exec is enabled (`enable_execute_command = true`) for debugging
- Auto Scaling: target tracking on CPU with scale-out cooldown of 60s, scale-in of 300s
- Blue/Green: timeout is 15 minutes; old (blue) tasks terminate 5 minutes after success

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name | string | n/a | yes |
| system | System name | string | n/a | yes |
| department | Department name | string | n/a | yes |
| ecs_security_group_id | ECS security group ID | string | n/a | yes |
| private_subnet_ids | Private subnet IDs for ECS tasks | list(string) | n/a | yes |
| task_role_arn | ECS task role ARN | string | n/a | yes |
| exec_role_arn | ECS execution role ARN | string | n/a | yes |
| nginx_image_uri | nginx container image URI | string | n/a | yes |
| app_image_uri | php-fpm container image URI | string | n/a | yes |
| blue_target_group_arn | Blue target group ARN | string | n/a | yes |
| green_target_group_arn | Green target group ARN | string | n/a | yes |
| https_listener_arn | HTTPS listener ARN | string | n/a | yes |
| test_listener_arn | Test listener ARN (port 8080) | string | n/a | yes |
| domain | Application domain for APP_URL | string | n/a | yes |
| app_key_ssm_arn | SSM ARN for APP_KEY | string | n/a | yes |
| db_host_ssm_arn | SSM ARN for DB_HOST | string | n/a | yes |
| db_database_ssm_arn | SSM ARN for DB_DATABASE | string | n/a | yes |
| db_username_ssm_arn | SSM ARN for DB_USERNAME | string | n/a | yes |
| db_password_ssm_arn | SSM ARN for DB_PASSWORD | string | n/a | yes |
| desired_count | Desired number of ECS tasks | number | 2 | no |
| task_cpu | Task-level CPU units | number | 512 | no |
| task_memory | Task-level memory (MB) | number | 1024 | no |
| nginx_cpu | nginx CPU units | number | 256 | no |
| nginx_memory | nginx memory (MB) | number | 512 | no |
| app_cpu | php-fpm CPU units | number | 256 | no |
| app_memory | php-fpm memory (MB) | number | 512 | no |
| min_capacity | Min tasks for Auto Scaling | number | 2 | no |
| max_capacity | Max tasks for Auto Scaling | number | 4 | no |
| cpu_scale_out_threshold | CPU threshold for scale out (%) | number | 80 | no |
| log_retention_days | CloudWatch log retention (days) | number | 30 | no |
| ssm_parameter_prefix | SSM Parameter Store prefix | string | /dev/portfolio/rds/mariadb | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | ECS cluster name |
| cluster_arn | ECS cluster ARN |
| service_name | ECS service name |
| task_definition_arn | ECS task definition ARN |
| codedeploy_app_name | CodeDeploy application name |
| codedeploy_deployment_group_name | CodeDeploy deployment group name |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - CodeDeploy deployment lifecycle
  - Auto Scaling behavior

## Example: Usage from Root Module
```
module "ecs" {
  source = "../../modules/container/ecs"

  env        = "dev"
  system     = "sample"
  department = "infra"

  ecs_security_group_id  = module.sg_ecs.security_group_id
  private_subnet_ids     = values(module.vpc.private_subnet_ids)
  task_role_arn          = module.iam_ecs.task_role_arn
  exec_role_arn          = module.iam_ecs.exec_role_arn

  nginx_image_uri        = "${module.ecr.repository_urls["nginx"]}:latest"
  app_image_uri          = "${module.ecr.repository_urls["app"]}:latest"

  blue_target_group_arn  = module.alb.blue_target_group_arn
  green_target_group_arn = module.alb.green_target_group_arn
  https_listener_arn     = module.alb.https_listener_arn
  test_listener_arn      = module.alb.test_listener_arn

  domain               = "portfolio.example.com"
  app_key_ssm_arn      = module.ssm.parameter_arns["/dev/portfolio/app_key"]
  db_host_ssm_arn      = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/host"]
  db_database_ssm_arn  = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/database"]
  db_username_ssm_arn  = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/username"]
  db_password_ssm_arn  = module.ssm.parameter_arns["/dev/portfolio/rds/mariadb/password"]
}
```
