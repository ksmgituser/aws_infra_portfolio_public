# ---------------------------------------------
# VPC リソース用の命名・タグ生成モジュール
# ・環境 / システム / 部署を共通ルールで統一
# ・テストでは「tags が正しく評価される」ことを確認可能
# ---------------------------------------------
module "vpc_naming" {
  source = "../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "vpc"
  department = var.department
}

# ---------------------------------------------
# VPC 本体
# ・VPC は条件分岐せず常に 1 つ作成される設計
# ・terraform test では plan/apply が常に成功することを確認する
# ---------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = module.vpc_naming.tags
}

# ---------------------------------------------
# Public Subnet 定義の正規化
# ・入力変数 public_subnets は「AZ → tier → CIDR」のネスト構造
# ・flatten + for により for_each 用の map に変換する
# ・module / resource 側では AZ や tier の構造を意識せず扱えるようにする
# ・key は「AZ-tier」で一意になるよう設計
#
# テスト観点:
# ・入力に対して期待した数の subnet 定義が生成されるか
# ・for_each が空にならないか
# ---------------------------------------------
locals {
  public_subnet_defs = {
    for item in flatten([
      for az, subnets in var.public_subnets : [
        for tier, cidr in subnets : {
          key       = "${az}-${tier}"
          az        = az
          az_suffix = regex("[a-z]$", az)
          tier      = tier
          cidr      = cidr
        }
      ]
    ]) :
    item.key => item
  }
}

# ---------------------------------------------
# Public Subnet 用の命名・タグ
# ・local.public_subnet_defs を for_each でループ
# ・各 Subnet 定義（AZ + tier）ごとに命名・タグを生成
# ・aws_subnet.public リソースと 1:1 で対応する
# ---------------------------------------------
module "subnet_public_naming" {
  for_each = local.public_subnet_defs
  source   = "../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "subnet-public"
  az         = each.value.az_suffix
  department = var.department
}

# ---------------------------------------------
# Public Subnet
# ・VPC に紐づく Public Subnet を AZ 単位で作成
# ・map_public_ip_on_launch = true により Public として振る舞う
#
# テスト観点:
# ・すべての Subnet が map_public_ip_on_launch = true であること
# ・VPC ID が aws_vpc.this と一致すること
# ---------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.public_subnet_defs

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = module.subnet_public_naming[each.key].tags
}


# ---------------------------------------------
# Private Subnet 定義
# ・入力変数 private_subnets は「AZ → tier → CIDR」のネスト構造
# ・flatten + for により for_each 用の map に変換する
# ・module / resource 側では AZ や tier の構造を意識せず扱えるようにする
# ・key は「AZ-tier」で一意になるよう設計
#
# テスト観点:
# ・入力に対して期待した数の subnet 定義が生成されるか
# ・for_each が空にならないか
# ---------------------------------------------
locals {
  private_subnet_defs = {
    for item in flatten([
      for az, subnets in var.private_subnets : [
        for tier, cidr in subnets : {
          key       = "${az}-${tier}"
          az        = az
          az_suffix = regex("[a-z]$", az)
          tier      = tier
          cidr      = cidr
        }
      ]
    ]) :
    item.key => item
  }
}

# ---------------------------------------------
# Private Subnet 用の命名・タグ
# ・local.private_subnet_defs を for_each でループ
# ・各 Subnet 定義（AZ + tier）ごとに命名・タグを生成
# ・aws_subnet.private リソースと 1:1 で対応する
# ---------------------------------------------
module "subnet_private_naming" {
  for_each = local.private_subnet_defs
  source   = "../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "subnet-private-${each.value.tier}"
  az         = each.value.az_suffix
  department = var.department
}

# ---------------------------------------------
# Private Subnet
# ・VPC に紐づく Private Subnet を AZ / tier 単位で作成
# ・Public IP の自動割り当てを行わない Subnet
# ・インターネット接続は NAT Gateway 経由を前提とする
#
# テスト観点:
# ・map_public_ip_on_launch が false（または未設定）であること
# ・Private Route Table と関連付けられていること
# ---------------------------------------------
resource "aws_subnet" "private" {
  for_each = local.private_subnet_defs

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = module.subnet_private_naming[each.key].tags
}

# ---------------------------------------------
# Internet Gateway
# ・VPC に 1 つだけアタッチされる前提
# ・Public Route Table から参照される
#
# テスト方針:
# ・IGW 単体の存在は Public Route Table のテストで間接的に保証する
# ---------------------------------------------
module "igw_naming" {
  source = "../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "igw"
  department = var.department
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = module.igw_naming.tags
}

# ---------------------------------------------
# NAT Gateway 制御
#
# 設計方針:
# ・enable_nat_gateway = true の場合のみ NAT Gateway を作成する
# ・本モジュールでは NAT Gateway は 1 個のみ作成する前提
# ・配置先は「指定した AZ の Public Subnet」
#
# 実装方針:
# ・for_each 用に map を生成し、0 or 1 個の NAT を表現
# ・NAT / EIP / Naming をすべて同じキーで制御する
#
# テスト観点:
# ・enable_nat_gateway = false の場合、NAT / EIP が作成されないこと
# ・enable_nat_gateway = true の場合、NAT が 1 つだけ作成されること
# ・VPC / Subnet は NAT の有無に影響されないこと
#
# NOTE:
# ・NAT Gateway は Public Subnet にのみ配置可能
# ・public_subnet_defs の key 設計（AZ 名）が前提条件となる
# ---------------------------------------------
# NAT Gateway の作成可否フラグ
# ・true の場合のみ NAT 関連リソースを作成する
locals {
  nat_enabled = var.enable_nat_gateway

  # NAT Gateway を配置する AZ
  # ・複数 AZ 構成でも、最初の AZ に 1 つだけ配置する設計
  nat_az = local.nat_enabled ? var.azs[0] : null

  # for_each 用の map
  # ・有効時: { nat = "<az>" }
  # ・無効時: {}
  nat_map = local.nat_enabled ? {
    nat = local.nat_az
  } : {}
}

# ---------------------------------------------
# NAT Gateway 用の命名・タグ
# ・NAT 関連リソース（EIP / NAT Gateway）で共通利用
# ・for_each のキーを NAT リソースと揃える
# ---------------------------------------------
module "nat_naming" {
  for_each = local.nat_map

  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "nat"
  az         = each.value
  department = var.department
}

# ---------------------------------------------
# NAT Gateway 用 Elastic IP
# ・NAT Gateway に必須のパブリック IP
# ・NAT Gateway と 1:1 で作成される
# ---------------------------------------------
resource "aws_eip" "nat" {
  for_each = local.nat_map

  domain = "vpc"
  tags   = module.nat_naming[each.key].tags
}

# ---------------------------------------------
# NAT Gateway
# ・Private Subnet からのアウトバウンド通信を提供
# ・Public Subnet 上に配置する必要がある
# ・本モジュールでは 1 つのみ作成する設計
#
# テスト観点:
# ・enable_nat_gateway = false の場合、リソースが作成されない
# ・enable_nat_gateway = true の場合、Public Subnet に配置される
# ---------------------------------------------
resource "aws_nat_gateway" "this" {
  for_each = local.nat_map

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value].id
  tags          = module.nat_naming[each.key].tags
}

# ---------------------------------------------
# Public Route Table
# ・Public Subnet 用の Route Table
# ・デフォルトルート (0.0.0.0/0) を Internet Gateway に向ける
# ・Public Subnet からインターネットへ直接通信できるようにする
# ---------------------------------------------
module "rt_public_naming" {
  source = "../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "rt-public"
  department = var.department
}

# ---------------------------------------------
# Public Route Table 本体
# ・VPC に紐づく Route Table
# ・IGW をデフォルトゲートウェイとして設定
# ---------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = module.rt_public_naming.tags
}

# ---------------------------------------------
# Public Subnet と Route Table の関連付け
# ・for_each により、すべての Public Subnet に同一の Route Table を関連付け
# ・これにより Public Subnet は IGW 経由で外部通信可能となる
# ---------------------------------------------
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------
# Private Route Table
# ・NAT Gateway が有効な場合のみデフォルトルートを追加
# ・dynamic block を使い、NAT の有無で route 定義自体を生成 / 非生成に切り替える
# ・NAT 無効時は Private Subnet がインターネットに出られない構成となる
#
# テスト観点:
# ・NAT 無効時に route ブロックが生成されないこと
# ---------------------------------------------
module "rt_private_naming" {
  source = "../../common/naming"

  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "rt-private"
  department = var.department
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = local.nat_map
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[route.key].id
    }
  }

  tags = module.rt_private_naming.tags
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}


