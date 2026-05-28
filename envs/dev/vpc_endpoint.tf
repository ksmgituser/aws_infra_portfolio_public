# ------------------------------------------------
# Security Group - VPC Endpoint
# ------------------------------------------------
module "sg_vpce" {
  source     = "../../modules/network/security_group/vpce"
  env        = var.env
  system     = var.system
  department = var.department

  vpc_id                    = module.vpc.vpc_id
  ecs_security_group_id     = module.sg_ecs.security_group_id
  bastion_security_group_id = module.bastion_sg.security_group_id
}

# ------------------------------------------------
# VPC Endpoint
# ------------------------------------------------
module "vpc_endpoint" {
  source     = "../../modules/network/vpc_endpoint"
  env        = var.env
  system     = var.system
  department = var.department

  vpc_id            = module.vpc.vpc_id
  security_group_id = module.sg_vpce.security_group_id

  # 1AZのみ配置（ap-northeast-1aのappサブネット）
  subnet_ids = [module.vpc.private_subnet_ids["ap-northeast-1a-app"]]

  # S3 GatewayエンドポイントのルートテーブルにPrivate RTを関連付け
  route_table_ids = {
    private = module.vpc.private_route_table_id
  }
}