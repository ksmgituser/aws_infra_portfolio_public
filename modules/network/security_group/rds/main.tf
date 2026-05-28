# ------------------------------------------------
# Security Group naming
# ------------------------------------------------
module "sg_naming" {
  source = "../../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "rds-sg"
  department = var.department
}

# ------------------------------------------------
# Security Group
# ------------------------------------------------
resource "aws_security_group" "this" {
  name   = module.sg_naming.name
  vpc_id = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = var.allowed_sg_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    module.sg_naming.tags,
    {
      Resource = "rds"
    }
  )

  lifecycle {
    ignore_changes = [ingress]
  }
}