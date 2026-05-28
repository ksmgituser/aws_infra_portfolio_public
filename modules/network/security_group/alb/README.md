# Security Group module - alb

## What this module does
- Creates a Security Group for the Application Load Balancer
- Allows inbound HTTP (80), HTTPS (443), and test listener (8080) from the specified CIDR
- Allows all outbound traffic

## Design decisions
- Port 8080 is opened for Blue/Green deployment traffic validation via CodeDeploy
- `allowed_cidr` defaults to `0.0.0.0/0` but should be restricted in production environments
- HTTP (80) is allowed so ALB can redirect to HTTPS

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| vpc_id | VPC ID | string | n/a | yes |
| allowed_cidr | Allowed CIDR for ALB ingress | string | 0.0.0.0/0 | no |

## Important Inputs
- `allowed_cidr`: Restrict to a specific IP range (e.g. home IP) to limit ALB exposure.

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | ALB security group ID |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - CIDR restriction behavior

## Example: Usage from Root Module
```
module "sg_alb" {
  source = "../../modules/network/security_group/alb"

  env        = "dev"
  system     = "sample"
  department = "infra"
  vpc_id     = module.vpc.vpc_id

  allowed_cidr = "203.0.113.0/32"
}
```
