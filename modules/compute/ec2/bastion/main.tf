# EC2 naming
module "ec2_naming" {
  source = "../../../common/naming"

  env        = var.env
  system     = var.system
  service    = "bastion"
  resource   = "ec2"
  department = var.department
  
}

# Amazon EC2インスタンス
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    dnf install -y mariadb105
  EOF

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = merge(
    module.ec2_naming.tags,
    {
      Role = var.role
    }
  )
}


