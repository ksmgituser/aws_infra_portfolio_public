# Storage module - s3/alb_logs

## What this module does
- Creates an S3 bucket for ALB access logs
- Blocks all public access
- Applies a bucket policy allowing the ELB service account and delivery.logs to write logs
- Configures a lifecycle rule to automatically expire logs after the specified number of days

## Design decisions
- Bucket name format: `{org_prefix}-{env}-{system}-s3-alb-logs-{bucket_suffix}`
- `bucket_suffix` is passed externally (typically the date at apply time) for global uniqueness
- `force_destroy = true` — bucket contents are deleted on `terraform destroy`
- Log expiration defaults to 90 days (cost-aware)
- ELB account ID defaults to `582318560864` (ap-northeast-1 region-specific)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name | string | n/a | yes |
| system | System name | string | n/a | yes |
| department | Department name | string | n/a | yes |
| account_id | AWS account ID (for bucket policy) | string | n/a | yes |
| org_prefix | Organization-specific bucket name prefix | string | n/a | yes |
| bucket_suffix | Suffix for global uniqueness (e.g. timestamp) | string | n/a | yes |
| elb_account_id | ELB service account ID for the region | string | 582318560864 | no |
| expiration_days | Log retention days | number | 90 | no |

## Important Inputs
- `bucket_suffix`: Recommended to pass `$(date +%Y%m%d%H%M)` at apply time to ensure uniqueness.
- `elb_account_id`: Must be updated if deploying to a region other than ap-northeast-1.

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | S3 bucket name |
| bucket_arn | S3 bucket ARN |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - ALB log delivery (requires actual ALB traffic)

## Example: Usage from Root Module
```
module "alb_logs" {
  source = "../../modules/storage/s3/alb_logs"

  env        = "dev"
  system     = "sample"
  department = "infra"

  account_id    = "123456789012"
  org_prefix    = "com-example"
  bucket_suffix = "202603062236"
}
```
