# DNS module - route53

## What this module does
- Creates a Route53 public hosted zone for the specified domain
- Creates an A record (Alias) pointing to the ALB

## Design decisions
- One hosted zone per module call (no multi-domain support)
- The ALB Alias record uses `evaluate_target_health = true`
- Name servers output for registration in the external DNS registrar (e.g. Xserver)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| domain | Subdomain to manage (e.g. portfolio.example.com) | string | n/a | yes |
| alb_dns_name | ALB DNS name for Alias record | string | n/a | yes |
| alb_zone_id | ALB hosted zone ID for Alias record | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | Route53 hosted zone ID |
| name_servers | NS records to register in the external registrar |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - DNS resolution (requires actual propagation)

## Example: Usage from Root Module
```
module "route53" {
  source = "../../modules/dns/route53"

  env        = "dev"
  system     = "sample"
  department = "infra"

  domain       = "portfolio.example.com"
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}
```
