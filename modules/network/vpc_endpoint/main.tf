# ------------------------------------------------
# naming
# ------------------------------------------------
module "naming" {
  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "vpce"
  department = var.department
}

# ------------------------------------------------
# Interface型エンドポイント定義
# ・ECR API / ECR DKR / SSM / CloudWatch Logs
# ・1AZのみ配置（コスト削減）
# ------------------------------------------------
locals {
  interface_endpoints = {
    ecr-api     = "com.amazonaws.${var.region}.ecr.api"
    ecr-dkr     = "com.amazonaws.${var.region}.ecr.dkr"
    ssm         = "com.amazonaws.${var.region}.ssm"
    ssmmessages = "com.amazonaws.${var.region}.ssmmessages"
    logs        = "com.amazonaws.${var.region}.logs"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = merge(module.naming.tags, {
    Resource = each.key
    Name     = "${module.naming.tags["Name"]}-${each.key}"
  })
}

# ------------------------------------------------
# Gateway型エンドポイント（S3）
# ・追加料金なし
# ・ルートテーブルへの関連付けが必要
# ------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = merge(module.naming.tags, { Resource = "s3" })
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  for_each = var.route_table_ids

  route_table_id  = each.value
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}