# Security module - acm

## What this module does
- Requests an ACM certificate for the specified domain
- Creates Route53 CNAME records for DNS validation
- Waits for certificate validation to complete before finishing

## Design decisions
- DNS validation is used (not email validation) — fully automated with Route53
- `create_before_destroy = true` prevents downtime during certificate rotation
- Validation CNAME records are created in the provided hosted zone

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| domain | Domain name for the certificate | string | n/a | yes |
| zone_id | Route53 hosted zone ID for DNS validation | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ACM certificate ARN |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Certificate issuance (requires actual DNS propagation)

## Example: Usage from Root Module
```
module "acm" {
  source = "../../modules/security/acm"

  env        = "dev"
  system     = "sample"
  department = "infra"

  domain  = "portfolio.example.com"
  zone_id = module.route53.zone_id
}
```
