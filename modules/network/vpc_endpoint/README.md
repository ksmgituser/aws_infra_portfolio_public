# Network module - vpc_endpoint

## What this module does
- Creates Interface VPC Endpoints for: ECR API, ECR DKR, SSM, SSM Messages, CloudWatch Logs
- Creates a Gateway VPC Endpoint for S3
- Associates the S3 Gateway endpoint with the specified route tables

## Design decisions
- Interface endpoints are placed in 1 AZ only to reduce costs (endpoints are charged per AZ per hour)
- S3 uses a Gateway endpoint (free of charge) instead of an Interface endpoint
- Private DNS is enabled for all Interface endpoints so existing SDK calls work without code changes
- All Interface endpoints share a single security group

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name | string | n/a | yes |
| system | System name | string | n/a | yes |
| department | Department name | string | n/a | yes |
| vpc_id | VPC ID | string | n/a | yes |
| subnet_ids | Subnet IDs for Interface endpoints (1 AZ) | list(string) | n/a | yes |
| security_group_id | Security group ID for Interface endpoints | string | n/a | yes |
| route_table_ids | Route table IDs to associate with S3 Gateway endpoint | map(string) | n/a | yes |
| region | AWS region | string | ap-northeast-1 | no |

## Important Inputs
- `subnet_ids`: Only 1 AZ placement is intentional for cost savings.
- `route_table_ids`: Should include both public and private route tables so all subnets can reach S3 via VPC endpoint.

## Outputs

| Name | Description |
|------|-------------|
| interface_endpoint_ids | Interface endpoint IDs keyed by service name |
| s3_endpoint_id | S3 Gateway endpoint ID |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Private DNS resolution from ECS / bastion

## Example: Usage from Root Module
```
module "vpc_endpoint" {
  source = "../../modules/network/vpc_endpoint"

  env        = "dev"
  system     = "sample"
  department = "infra"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = [module.vpc.private_subnet_ids["ap-northeast-1a"]["app"]]
  security_group_id = module.sg_vpce.security_group_id

  route_table_ids = {
    public  = module.vpc.public_route_table_id
    private = module.vpc.private_route_table_id
  }
}
```
