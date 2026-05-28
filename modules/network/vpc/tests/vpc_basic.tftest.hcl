mock_provider "aws" {}

run "vpc_basic" {
  command = apply

  variables {
    env        = "test"
    system     = "sample"
    department = "infra"

    vpc_cidr = "10.0.0.0/16"
    azs      = ["ap-northeast-1a", "ap-northeast-1c"]

    public_subnets = {
      ap-northeast-1a = {
        web = "10.0.1.0/24"
      }
      ap-northeast-1c = {
        web = "10.0.2.0/24"
      }
    }

    private_subnets = {
      ap-northeast-1a = {
        app = "10.0.11.0/24"
      }
      ap-northeast-1c = {
        app = "10.0.12.0/24"
      }
    }

    enable_nat_gateway = false
  }

  # VPC が 1 つ評価されること
  assert {
    condition     = length(aws_vpc.this) == 1
    error_message = "VPC must be created exactly once"
  }

  # Public Subnet は public として振る舞う
  assert {
    condition = alltrue([
      for s in aws_subnet.public :
      s.map_public_ip_on_launch == true
    ])
    error_message = "All public subnets must enable public IP assignment"
  }

  # Public Subnet が VPC に属していること
  assert {
    condition = alltrue([
      for s in aws_subnet.public :
      s.vpc_id == aws_vpc.this.id
    ])
    error_message = "Public subnets must belong to the VPC"
  }
}
