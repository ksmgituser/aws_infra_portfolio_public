# Security Group module - rds

## What this module does
- Creates a Security Group for RDS
- Allows inbound TCP on the specified DB port from specified security groups
- Allows all outbound traffic

## Design decisions
- Inbound rules are defined via `allowed_sg_ids` (SG-to-SG reference, not CIDR)
- `lifecycle { ignore_changes = [ingress] }` is set to prevent Terraform drift when cross-module SG rules are managed separately
- DB port defaults to 3306 (MariaDB/MySQL)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| vpc_id | VPC ID where security group is created | string | n/a | yes |
| db_port | DB port to allow inbound | number | 3306 | no |
| allowed_sg_ids | List of security group IDs allowed to connect | list(string) | n/a | yes |

## Important Inputs
- `allowed_sg_ids`: Must contain at least one ID. Typically the ECS security group ID.
- `db_port`: Must be between 1 and 65535.

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | RDS security group ID |
| security_group_ids | RDS security group IDs (list) |
| security_group_name | RDS security group name |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Cross-module SG rule injection (managed outside this module)

## Example: Usage from Root Module
```
module "sg_rds" {
  source = "../../modules/network/security_group/rds"

  env        = "dev"
  system     = "sample"
  department = "infra"
  vpc_id     = module.vpc.vpc_id

  db_port        = 3306
  allowed_sg_ids = [module.sg_ecs.security_group_id]
}
```
