mock_provider "aws" {}

run "nat_enabled" {
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

    enable_nat_gateway = true
  }

  # NAT Gateway は 1 つだけ
  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Exactly one NAT Gateway must be created"
  }

  # NAT Gateway が Public Subnet 上にある
  assert {
    condition = contains(
      values(aws_subnet.public)[*].id,
      one(aws_nat_gateway.this[*].subnet_id)
    )
    error_message = "NAT Gateway must be placed in a public subnet"
  }

  # Private Route Table に default route がある
  assert {
    condition = length(
      aws_route_table.private.route
    ) == 1
    error_message = "Private route table must have one default route when NAT is enabled"
  }
}
