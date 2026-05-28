# ------------------------------------------------
# Security Group for ALB
# ------------------------------------------------
module "alb_sg" {
  source = "../../modules/network/security_group/alb"

  env        = var.env
  system     = var.system
  department = var.department

  vpc_id       = module.vpc.vpc_id
  allowed_cidr = var.allowed_cidr
}

# ------------------------------------------------
# Security Group for bastion
# ------------------------------------------------
module "bastion_sg" {
  source = "../../modules/network/security_group/bastion"

  env        = var.env
  system     = var.system
  department = var.department

  vpc_id = module.vpc.vpc_id
}

# ------------------------------------------------
# RDS Security Group
# ------------------------------------------------
module "rds_sg" {
  source = "../../modules/network/security_group/rds"

  env        = var.env
  system     = var.system
  department = var.department

  vpc_id = module.vpc.vpc_id

  # RDS 用
  db_port = 3306
  allowed_sg_ids = [
    module.bastion_sg.security_group_id, # bastion用
  ]
}

# ------------------------------------------------
# Security Group - ECS
# ------------------------------------------------
module "sg_ecs" {
  source     = "../../modules/network/security_group/ecs"
  env        = var.env
  system     = var.system
  department = var.department

  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.security_group_id
}

# ECS → RDS の egress / RDS ← ECS の ingress
# 循環参照を避けるため、モジュール外で独立したルールとして定義する
resource "aws_security_group_rule" "ecs_to_rds_egress" {
  type                     = "egress"
  description              = "Allow to RDS"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = module.sg_ecs.security_group_id
  source_security_group_id = module.rds_sg.security_group_id
}

resource "aws_security_group_rule" "rds_from_ecs_ingress" {
  type                     = "ingress"
  description              = "Allow from ECS"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = module.rds_sg.security_group_id
  source_security_group_id = module.sg_ecs.security_group_id
}