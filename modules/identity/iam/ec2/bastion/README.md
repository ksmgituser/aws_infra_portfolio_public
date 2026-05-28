# IAM module - ec2/bastion

## What this module does
- Creates an IAM role for the bastion EC2 instance
- Attaches `AmazonSSMManagedInstanceCore` (SSM Session Manager access)
- Attaches `AmazonS3ReadOnlyAccess` (for downloading DB dumps from S3)
- Creates an IAM instance profile for the role

## Design decisions
- Only managed policies are attached — no inline policies
- S3 access is read-only (sufficient for DB dump download use case)
- SSM managed policy enables Session Manager without SSH

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| role_name | IAM role name |
| role_arn | IAM role ARN |
| instance_profile_name | IAM instance profile name |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Policy attachment verification

## Example: Usage from Root Module
```
module "iam_bastion" {
  source = "../../modules/identity/iam/ec2/bastion"

  env        = "dev"
  system     = "sample"
  department = "infra"
}
```
