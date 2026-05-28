# Security Group module - vpce

## What this module does
- Creates a Security Group for VPC Interface Endpoints
- Allows inbound HTTPS (port 443) from ECS and bastion security groups
- No egress rules (Interface endpoints do not need outbound rules)

## Design decisions
- Only ECS and bastion are allowed to use the VPC endpoints
- No egress rules — VPC endpoints are passive listeners
- This SG is shared across all Interface endpoints (ECR, SSM, CloudWatch Logs, etc.)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| vpc_id | VPC ID | string | n/a | yes |
| ecs_security_group_id | ECS security group ID | string | n/a | yes |
| bastion_security_group_id | Bastion security group ID | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | VPC endpoint security group ID |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Endpoint reachability from ECS / bastion

## Example: Usage from Root Module
```
module "sg_vpce" {
  source = "../../modules/network/security_group/vpce"

  env        = "dev"
  system     = "sample"
  department = "infra"
  vpc_id     = module.vpc.vpc_id

  ecs_security_group_id     = module.sg_ecs.security_group_id
  bastion_security_group_id = module.sg_bastion.security_group_id
}
```
