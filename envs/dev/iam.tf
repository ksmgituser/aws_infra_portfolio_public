# ------------------------------------------------
# IAM role for bastion (SSM)
# ------------------------------------------------
module "bastion_iam" {
  source = "../../modules/identity/iam/ec2/bastion"

  env        = var.env
  system     = var.system
  department = var.department
}

# ------------------------------------------------
# IAM - ECS
# ------------------------------------------------
module "iam_ecs" {
  source     = "../../modules/identity/iam/ecs"
  env        = var.env
  system     = var.system
  department = var.department
}
