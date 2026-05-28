# EC2 module - bastion

## What this module does
- Creates an EC2 instance for use as a bastion host
- Enables and starts the SSM agent via user_data
- Installs mariadb105 client (for direct DB access via SSM session)
- Configures the root EBS volume with the specified size and type

## Design decisions
- Access is via SSM Session Manager only — no SSH key pair is set
- `role` variable enforces a limited set of valid values (bastion, app, web, db)
- No public IP is assigned by this module; subnet routing determines reachability
- EBS defaults to gp3 8GiB (minimum for most AMIs)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| role | Role of EC2 instance (bastion / app / web / db) | string | n/a | yes |
| ami_id | AMI ID | string | n/a | yes |
| instance_type | EC2 instance type | string | t3.micro | no |
| subnet_id | Subnet ID where EC2 is deployed | string | n/a | yes |
| security_group_ids | Security group IDs | list(string) | null | no |
| iam_instance_profile | IAM instance profile name (SSM) | string | null | no |
| root_volume_size | Root EBS volume size (GiB) | number | 8 | no |
| root_volume_type | Root EBS volume type | string | gp3 | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| private_ip | Private IP address |
| public_ip | Public IP address (if exists) |
| subnet_id | Subnet ID where EC2 is deployed |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - SSM agent startup (requires running instance)

## Example: Usage from Root Module
```
module "bastion" {
  source = "../../modules/compute/ec2/bastion"

  env        = "dev"
  system     = "sample"
  department = "infra"

  role                 = "bastion"
  ami_id               = "ami-xxxxxxxxxxxxxxxxx"
  instance_type        = "t3.micro"
  subnet_id            = module.vpc.public_subnet_ids["ap-northeast-1a"]["web"]
  security_group_ids   = [module.sg_bastion.security_group_id]
  iam_instance_profile = module.iam_bastion.instance_profile_name
}
```
