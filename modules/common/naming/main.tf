locals {

  # リソース名用文字列生成
  # compact() は リストから空文字や null を除外する関数
  name_parts = compact([
    var.env,
    var.system,
    var.service,
    var.resource,
    var.az,
    var.no
  ])

  name = join("-", local.name_parts)

  # タグ
  tags = {
    Name       = local.name
    Env        = var.env
    System     = var.system
    ManagedBy  = "Terraform"
    Department = var.department
  }

  /*
    共通タグ例:
    Name       = dev-portfolio-vpc-public-subnet-a-01
    Env        = dev
    System     = portfolio
    ManagedBy  = Terraform
    Department = it_operation
  */

}
