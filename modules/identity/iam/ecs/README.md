# IAM module - ecs

## What this module does
- Creates an ECS **task role** (used by the application container)
  - Allows SSM Parameter Store read (`GetParameter`, `GetParameters`, `GetParametersByPath`)
  - Allows ECS Exec via SSM messages (`ssmmessages:*`)
- Creates an ECS **execution role** (used by the ECS agent)
  - Attaches `AmazonECSTaskExecutionRolePolicy` (ECR pull + CloudWatch Logs)
  - Allows SSM Parameter Store read (for injecting secrets into container env)

## Design decisions
- Task role and execution role are separated by responsibility
- Task role: what the **app** can do at runtime
- Execution role: what the **ECS agent** can do at startup
- SSM Parameter Store access is granted to both roles:
  - Execution role: to inject secrets via `secrets` in task definition
  - Task role: to allow runtime reads from the app itself

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| env | Environment name (e.g. dev, stg, prod) | string | n/a | yes |
| system | System name used for resource naming | string | n/a | yes |
| department | Department or team name used for tagging | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| task_role_arn | ECS task role ARN |
| exec_role_arn | ECS execution role ARN |

## Testing policy
- Tested:
  - (not yet implemented)
- Not tested:
  - Actual IAM permission evaluation

## Example: Usage from Root Module
```
module "iam_ecs" {
  source = "../../modules/identity/iam/ecs"

  env        = "dev"
  system     = "sample"
  department = "infra"
}
```
