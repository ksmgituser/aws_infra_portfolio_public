module "ecr" {
  source     = "../../modules/container/ecr"
  env        = var.env
  system     = var.system
  department = var.department

  repositories = {
    nginx = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
    }
    app = {
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
    }
  }

  lifecycle_policy_count = 10
}