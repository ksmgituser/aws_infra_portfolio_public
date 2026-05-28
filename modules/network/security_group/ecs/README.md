# Security Group module - ecs

## What this module does
- Creates a Security Group for ECS Fargate tasks
- Allows inbound HTTP (port 80) from the ALB security group only
- Allows outbound HTTPS (port 443) to reach ECR, SSM, and CloudWatch

## Design decisions
- Inbound is locked to ALB SG only — direct internet access to ECS is not allowed
- Egress is limited to HTTPS 443 (required for ECR image pull, SSM Parameter Store, CloudWatch Logs)
- `lifecycle { ignore_changes = [egress] }` is set to avoid drift when egress rules are extended by the root module (e.g., adding RDS egress)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| vpc_id | VPC ID | string | n/a | yes |
| alb_security_group_id | ALB security group ID | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | ECS security group ID |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Egress extension for RDS (managed outside this module)

## Example: Usage from Root Module
```
module "sg_ecs" {
  source = "../../modules/network/security_group/ecs"

  env        = "dev"
  system     = "sample"
  department = "infra"
  vpc_id     = module.vpc.vpc_id

  alb_security_group_id = module.sg_alb.security_group_id
}
```
