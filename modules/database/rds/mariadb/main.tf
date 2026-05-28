# naming
module "rds_naming" {
  source = "../../../common/naming"

  env        = var.env
  system     = var.system
  service    = "database"
  resource   = "rds"
  department = var.department
}

# サブネットグループ
resource "aws_db_subnet_group" "this" {
  name       = "${module.rds_naming.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    module.rds_naming.tags,
    {
      Resource = "subnet-group"
    }
  )
}

# ランダムパスワード
resource "random_password" "this" {
  count = var.db_password == null ? 1 : 0

  length  = 20
  special = true
  override_special = "!#$%&*()-_=+[]{}<>?"  # / @ " スペースを除外
}

locals {
  final_db_password = coalesce(
    var.db_password,
    try(random_password.this[0].result, null)
  )
}

# # SSM Parameter Store に保存
# resource "aws_ssm_parameter" "db_password" {
#   name  = "/${var.env}/${var.system}/rds/mariadb/password"
#   type  = "SecureString"
#   value = local.final_db_password

#   tags = merge(
#     module.rds_naming.tags,
#     {
#       Resource = "ssm-parameter"
#     }
#   )
# }

# DB本体
resource "aws_db_instance" "this" {
  identifier = module.rds_naming.name

  engine         = "mariadb"
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type

  multi_az = var.multi_az

  db_name  = var.db_name
  username = var.username
  password = local.final_db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = module.rds_naming.tags
}

# # DBエンドポイント
# resource "aws_ssm_parameter" "db_endpoint" {
#   name  = "/${var.env}/${var.system}/rds/mariadb/endpoint"
#   type  = "String"
#   value = aws_db_instance.this.endpoint

#   tags = merge(
#     module.rds_naming.tags,
#     {
#       Resource = "ssm-parameter"
#     }
#   )
# }