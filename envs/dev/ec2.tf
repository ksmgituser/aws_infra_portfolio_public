# ------------------------------------------------
# EC2 for bastion
# ------------------------------------------------
module "bastion_ec2" {
  source = "../../modules/compute/ec2/bastion"

  env        = var.env
  system     = var.system
  department = var.department

  role = "bastion"

  ami_id = "ami-06126d6d169482f5b"
  # ami_id        = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  # subnet_id            = module.vpc.private_subnet_ids["ap-northeast-1a-db"]
  subnet_id = module.vpc.public_subnet_ids["ap-northeast-1a-public"]

  security_group_ids   = [module.bastion_sg.id]
  iam_instance_profile = module.bastion_iam.instance_profile_name

  root_volume_size = 30 # 30が最低
  #root_volume_type = "gp3" #デフォルト値gp3なので不要

}

# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023*-kernel-*-x86_64"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }
