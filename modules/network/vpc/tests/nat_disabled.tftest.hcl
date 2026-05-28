mock_provider "aws" {}

run "nat_disabled" {
  command = apply

  variables {
    env        = "test"
    system     = "sample"
    department = "infra"

    vpc_cidr = "10.0.0.0/16"
    azs      = ["ap-northeast-1a"]

    public_subnets = {
      ap-northeast-1a = {
        web = "10.0.1.0/24"
      }
    }

    private_subnets = {
      ap-northeast-1a = {
        app = "10.0.11.0/24"
      }
    }

    enable_nat_gateway = false
  }

  # NAT Gateway が作成されない
  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "NAT Gateway must not be created when disabled"
  }

  # Private Route Table に default route が存在しない
  assert {
    condition = length(
      aws_route_table.private.route
    ) == 0
    error_message = "Private route table must not have default route when NAT is disabled"
  }
}
