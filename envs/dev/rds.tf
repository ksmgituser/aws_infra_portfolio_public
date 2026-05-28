# ------------------------------------------------
# RDS (MariaDB)
# ------------------------------------------------
module "rds_mariadb" {
  source = "../../modules/database/rds/mariadb"

  env        = var.env
  system     = var.system
  department = var.department

  subnet_ids = module.vpc.private_db_subnet_ids


  engine_version = "10.11"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  multi_az = true

  backup_retention_period = 1
  backup_window           = "18:00-19:00"
  maintenance_window      = "Sun:19:00-Sun:20:00"
  skip_final_snapshot     = true


  db_name  = "appdb"
  username = "admin"

  # 指定しなければ random_password が使われる
  db_password = null

  security_group_ids = [
    module.rds_sg.security_group_id
  ]
}
