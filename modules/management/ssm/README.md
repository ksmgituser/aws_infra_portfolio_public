# Management module - ssm

## What this module does
- Creates SSM Parameter Store parameters from a map input
- Supports both `String` and `SecureString` types
- Sets `overwrite = true` so re-running apply updates the value

## Design decisions
- Parameters are passed as a map — multiple parameters can be created in a single call
- Type defaults to `SecureString` for safety
- Parameter names (keys) are used directly as the SSM path (e.g. `/dev/portfolio/rds/mariadb/host`)
- `overwrite = true` is set intentionally — SSM parameters are managed by Terraform

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name | string | n/a | yes |
| system | System name | string | n/a | yes |
| department | Department name | string | n/a | yes |
| parameters | Map of SSM parameters to create | map(object) | {} | no |

## Important Inputs
- `parameters`: Each entry supports `value`, `type` (default: `SecureString`), and `description`.

## Outputs

| Name | Description |
|------|-------------|
| parameter_arns | SSM parameter ARNs keyed by parameter name |
| parameter_names | SSM parameter names keyed by parameter name |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - SecureString encryption (KMS-managed by AWS)

## Example: Usage from Root Module
```
module "ssm" {
  source = "../../modules/management/ssm"

  env        = "dev"
  system     = "sample"
  department = "infra"

  parameters = {
    "/dev/portfolio/rds/mariadb/host" = {
      value       = module.rds_mariadb.address
      type        = "String"
      description = "RDS host address"
    }
    "/dev/portfolio/rds/mariadb/password" = {
      value       = module.rds_mariadb.password
      type        = "SecureString"
      description = "RDS master password"
    }
  }
}
```
