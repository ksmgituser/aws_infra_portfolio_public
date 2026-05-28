# Security Group module - bastion

## What this module does
- Creates a Security Group for the bastion host
- Allows all outbound traffic (required for SSM Session Manager)
- No inbound rules (SSH is not required because access is via SSM)

## Design decisions
- No inbound rules by design — access is via SSM, not SSH
- All egress allowed so the SSM agent can reach AWS endpoints
- If SSH access is needed later, add a rule in the calling root module

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| vpc_id | VPC ID where security group is created | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| id | Security group ID |
| name | Security group name |
| security_group_id | Bastion security group ID (alias for id) |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Inbound rule absence (SSH not used)

## Example: Usage from Root Module
```
module "sg_bastion" {
  source = "../../modules/network/security_group/bastion"

  env        = "dev"
  system     = "sample"
  department = "infra"
  vpc_id     = module.vpc.vpc_id
}
```
