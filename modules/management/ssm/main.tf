module "naming" {
  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "ssm"
  resource   = "parameter"
  department = var.department
}

resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = each.key
  value       = each.value.value
  type        = each.value.type
  description = each.value.description
  overwrite   = true

  tags = module.naming.tags
}