module "naming" {
  source     = "../../../common/naming"
  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "ecs-sg"
  department = var.department
}

resource "aws_security_group" "this" {
  name   = module.naming.name
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Allow HTTPS for ECR/SSM/CloudWatch"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.naming.tags

  lifecycle {
    ignore_changes = [egress]
  }
}