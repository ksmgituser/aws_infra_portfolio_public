# VPC module

## What this module does
- Creates exactly one VPC
- Creates Public / Private Subnets per AZ
- Optionally creates one NAT Gateway
- Configures Route Tables for public and private traffic

## Design decisions
- VPC is always created (no count / for_each)
- Subnet definitions are normalized via locals
- NAT Gateway is optional and isolated from VPC/Subnet lifecycle
- Only one NAT Gateway is created (cost-aware design)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| vpc_cidr | CIDR block for the VPC | string | n/a | yes |
| azs | List of Availability Zones to use | list(string) | n/a | yes |
| public_subnets | Public subnet CIDRs grouped by AZ and purpose | map(map(string)) | n/a | yes |
| private_subnets | Private subnet CIDRs grouped by AZ and purpose | map(map(string)) | n/a | yes |
| enable_nat_gateway | Whether to create a NAT Gateway | bool | false | no |


## Important Inputs
- `enable_nat_gateway`: Enables outbound internet access for private subnets.
- `private_subnets`: Used to separate app and DB tiers.

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| vpc_cidr | CIDR block of the VPC |
| public_subnet_ids | Public subnet IDs keyed by AZ |
| public_subnet_cidrs | Public subnet CIDR blocks keyed by AZ |
| private_subnet_ids | Private subnet IDs keyed by AZ |
| private_db_subnet_ids | Private subnet IDs for DB subnets only |
| private_subnet_cidrs | Private subnet CIDR blocks keyed by AZ |
| public_route_table_id | Public route table ID |
| private_route_table_id | Private route table ID |
| internet_gateway_id | Internet Gateway ID |
| nat_gateway_id | NAT Gateway ID (null if disabled) |

## Testing policy
- Tested:
  - VPC existence
  - Public subnet properties
  - NAT enabled / disabled behavior
- Not tested:
  - Naming modules (treated as pure functions)
  - IGW existence (indirectly validated via route tables)

## Example: Usage from Root Module
This example shows how to call the VPC module from a root module.
It demonstrates a typical 2-AZ configuration with public and private subnets and a single NAT Gateway.
```
module "vpc" {
  source = "../../modules/network/vpc"

  env        = "dev"
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
      db  = "10.0.21.0/24"
    }
    ap-northeast-1c = {
      app = "10.0.12.0/24"
      db  = "10.0.22.0/24"
    }
  }

  enable_nat_gateway = true
}
```