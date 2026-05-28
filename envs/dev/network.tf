# ------------------------------------------------
# VPC
# ------------------------------------------------
module "vpc" {
  source = "../../modules/network/vpc"

  env        = var.env
  system     = var.system
  department = var.department

  vpc_cidr = "10.0.0.0/16"

  azs = [
    "ap-northeast-1a",
    "ap-northeast-1c"
  ]

  public_subnets = {
    ap-northeast-1a = {
      public = "10.0.10.0/24"
    }
    ap-northeast-1c = {
      public = "10.0.11.0/24"
    }
  }

  private_subnets = {
    ap-northeast-1a = {
      app = "10.0.20.0/24"
      db  = "10.0.40.0/24"
    }
    ap-northeast-1c = {
      app = "10.0.21.0/24"
      db  = "10.0.41.0/24"
    }
  }

  enable_nat_gateway = false
}

