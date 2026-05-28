# Common module - naming

## What this module does
- Generates a standardized resource name from the given inputs
- Generates a common tag map for AWS resources

## Design decisions
- Name format: `{env}-{system}-{service}-{resource}[-{az}][-{no}]`
- `az` and `no` are optional; omitted parts are excluded via `compact()`
- All modules use this module internally to ensure consistent naming and tagging
- This module is a pure function — no AWS resources are created

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name (e.g. portfolio) | string | n/a | yes |
| service | AWS service or logical layer (e.g. vpc, ecs, alb) | string | n/a | yes |
| resource | Resource type or role (e.g. subnet, cluster, sg) | string | n/a | yes |
| department | Department name for tagging | string | n/a | yes |
| az | Availability Zone identifier (e.g. a, c). Optional. | string | null | no |
| no | Sequential number (e.g. 01, 02). Optional. | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| name | Generated resource name |
| tags | Common tag map (Name, Env, System, ManagedBy, Department) |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Name generation logic (treated as a pure function with no side effects)

## Example: Usage from another module
```
module "naming" {
  source = "../../common/naming"

  env        = "dev"
  system     = "portfolio"
  service    = "vpc"
  resource   = "public-subnet"
  az         = "a"
  no         = "01"
  department = "infra"
}

# module.naming.name => "dev-portfolio-vpc-public-subnet-a-01"
```
