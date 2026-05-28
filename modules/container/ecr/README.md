# Container module - ecr

## What this module does
- Creates one or more ECR repositories using `for_each`
- Configures image scanning on push per repository
- Applies a lifecycle policy to keep the last N images

## Design decisions
- Repository definitions are passed as a map — multiple repos can be created in a single call
- `image_tag_mutability` defaults to `MUTABLE` (allows overwriting tags like `latest`)
- Lifecycle policy retains the last 10 images by default to control storage costs
- Scan on push is enabled by default

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |
| repositories | Map of ECR repository definitions | map(object) | {} | no |
| lifecycle_policy_count | Number of images to keep per repository | number | 10 | no |

## Important Inputs
- `repositories`: Each entry can specify `image_tag_mutability` and `scan_on_push`.

## Outputs

| Name | Description |
|------|-------------|
| repository_urls | ECR repository URLs keyed by repository name |
| repository_arns | ECR repository ARNs keyed by repository name |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Lifecycle policy enforcement (AWS-managed behavior)

## Example: Usage from Root Module
```
module "ecr" {
  source = "../../modules/container/ecr"

  env        = "dev"
  system     = "sample"
  department = "infra"

  repositories = {
    app = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
    }
    nginx = {
      scan_on_push = true
    }
  }

  lifecycle_policy_count = 10
}
```
