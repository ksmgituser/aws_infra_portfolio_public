module "naming" {
  source     = "../../../common/naming"
  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "vpce-sg"
  department = var.department
}

resource "aws_security_group" "this" {
  name   = module.naming.name
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow HTTPS from ECS and Bastion"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id, var.bastion_security_group_id]
  }

  tags = module.naming.tags
}