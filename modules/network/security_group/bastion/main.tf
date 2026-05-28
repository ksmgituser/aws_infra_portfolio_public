# ------------------------------------------------
# Security Group naming
# ------------------------------------------------
module "sg_naming" {
  source = "../../../common/naming"

  env        = var.env
  system     = var.system
  service    = "bastion"
  resource   = "sg"
  department = var.department
}

# ------------------------------------------------
# Security Group
# ------------------------------------------------
resource "aws_security_group" "this" {
  name        = module.sg_naming.name
  description = "Security group for bastion host (SSM access)"
  vpc_id      = var.vpc_id

  # SSM 前提なので inbound は作らない
  # （あとで SSH 開けたくなったら rule 追加）

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.sg_naming.tags
}
