# ------------------------------------------------
# naming
# ------------------------------------------------
module "naming" {
  for_each = var.repositories

  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "container"
  resource   = "ecr-${each.key}"
  department = var.department
}

# ------------------------------------------------
# ECRリポジトリ
# ------------------------------------------------
resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = module.naming[each.key].name
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  tags = module.naming[each.key].tags
}

# ------------------------------------------------
# ライフサイクルポリシー（直近N世代を保持）
# ------------------------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.repositories

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_policy_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_policy_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}