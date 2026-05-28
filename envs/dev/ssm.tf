module "ssm" {
  source     = "../../modules/management/ssm"
  env        = var.env
  system     = var.system
  department = var.department

  parameters = {
    "/dev/portfolio/rds/mariadb/host" = {
      value       = module.rds_mariadb.address
      type        = "String"
      description = "RDS MariaDB endpoint"
    }
    "/dev/portfolio/rds/mariadb/database" = {
      value       = "appdb"
      type        = "String"
      description = "RDS MariaDB database name"
    }
    "/dev/portfolio/rds/mariadb/username" = {
      value       = "admin"
      type        = "String"
      description = "RDS MariaDB username"
    }
    "/dev/portfolio/rds/mariadb/password" = {
      value       = module.rds_mariadb.password
      type        = "SecureString"
      description = "RDS MariaDB password"
    }
    "/dev/portfolio/app/key" = {
      value       = var.app_key
      type        = "SecureString"
      description = "Laravel application key"
    }
  }
}