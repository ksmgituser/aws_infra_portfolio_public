# ELB module - alb

## What this module does
- Creates an internet-facing Application Load Balancer
- Creates Blue and Green target groups (for CodeDeploy Blue/Green)
- Creates three listeners:
  - HTTP (80) → HTTPS redirect (301)
  - HTTPS (443) → Blue target group (production traffic)
  - HTTP (8080) → Green target group (test traffic for Blue/Green validation)
- Enables ALB access logging to S3

## Design decisions
- Blue/Green target groups are always created together — this module assumes CodeDeploy
- `ignore_changes = [default_action]` on HTTPS and test listeners to avoid conflicts with CodeDeploy traffic shifting
- TLS policy: `ELBSecurityPolicy-TLS13-1-2-2021-06` (TLS 1.2+ with TLS 1.3 support)
- Health check defaults to `/login` (suitable for Laravel apps)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name | string | n/a | yes |
| system | System name | string | n/a | yes |
| department | Department name | string | n/a | yes |
| vpc_id | VPC ID | string | n/a | yes |
| public_subnet_ids | Public subnet IDs for ALB | list(string) | n/a | yes |
| certificate_arn | ACM certificate ARN for HTTPS listener | string | n/a | yes |
| security_group_id | Security group ID for ALB | string | n/a | yes |
| access_logs_bucket | S3 bucket name for access logs | string | n/a | yes |
| health_check_path | Health check path for target groups | string | /login | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ALB ARN |
| alb_dns_name | ALB DNS name |
| alb_zone_id | ALB hosted zone ID |
| security_group_id | ALB security group ID |
| blue_target_group_arn | Blue target group ARN |
| green_target_group_arn | Green target group ARN |
| https_listener_arn | HTTPS listener ARN |
| test_listener_arn | Test listener ARN (port 8080) |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Blue/Green traffic shifting behavior (managed by CodeDeploy)
  - TLS termination

## Example: Usage from Root Module
```
module "alb" {
  source = "../../modules/elb/alb"

  env        = "dev"
  system     = "sample"
  department = "infra"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = values(module.vpc.public_subnet_ids)
  certificate_arn    = module.acm.certificate_arn
  security_group_id  = module.sg_alb.security_group_id
  access_logs_bucket = module.alb_logs.bucket_id

  health_check_path = "/login"
}
```
