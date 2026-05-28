# Database module - rds/mariadb

## What this module does
- Creates an RDS MariaDB instance
- Creates a DB subnet group from the specified subnets
- Generates a random password if no password is provided

## Design decisions
- Password is auto-generated if `db_password` is null (using `random_password`)
- `skip_final_snapshot` defaults to `true` for dev environments — set to `false` in production
- `multi_az` defaults to `false` (cost-aware; enable in production)
- `auto_minor_version_upgrade` defaults to `false` to avoid uncontrolled upgrades
- `backup_retention_period` defaults to 0 (no automated backups) — set for production use
- Minimum 2 subnets are required by the RDS subnet group constraint

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name | string | n/a | yes |
| system | System name | string | n/a | yes |
| department | Department name | string | n/a | yes |
| subnet_ids | Subnet IDs for RDS subnet group (min 2) | list(string) | n/a | yes |
| security_group_ids | Security group IDs for RDS | list(string) | n/a | yes |
| db_name | Initial database name | string | n/a | yes |
| username | Master username | string | n/a | yes |
| engine_version | MariaDB engine version | string | 10.6 | no |
| instance_class | DB instance class | string | db.t3.micro | no |
| storage_type | EBS storage type | string | gp3 | no |
| allocated_storage | Allocated storage (GiB, min 20) | number | 20 | no |
| multi_az | Enable Multi-AZ | bool | false | no |
| backup_retention_period | Backup retention days (0–35) | number | 0 | no |
| skip_final_snapshot | Skip final snapshot on deletion | bool | true | no |
| auto_minor_version_upgrade | Auto minor version upgrade | bool | false | no |
| db_password | Master password (null = auto-generated) | string | null | no |
| db_port | DB port | number | 3306 | no |
| backup_window | Preferred backup window (UTC) | string | null | no |
| maintenance_window | Preferred maintenance window (UTC) | string | null | no |

## Important Inputs
- `db_password`: If null, a 20-character random password is generated. The password is available via the `password` output (sensitive).
- `subnet_ids`: Must contain at least 2 subnets in different AZs (RDS requirement).

## Outputs

| Name | Description |
|------|-------------|
| endpoint | RDS endpoint (host:port) |
| address | RDS hostname only (without port) |
| port | RDS port |
| password | RDS master password (sensitive) |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Random password generation
  - Multi-AZ failover behavior

## Example: Usage from Root Module
```
module "rds_mariadb" {
  source = "../../modules/database/rds/mariadb"

  env        = "dev"
  system     = "sample"
  department = "infra"

  subnet_ids         = module.vpc.private_db_subnet_ids
  security_group_ids = [module.sg_rds.security_group_id]

  db_name  = "app"
  username = "admin"
}
```
