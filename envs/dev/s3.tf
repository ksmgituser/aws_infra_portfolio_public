module "s3_alb_logs" {
  source     = "../../modules/storage/s3/alb_logs"
  env        = var.env
  system     = var.system
  department = var.department

  account_id    = data.aws_caller_identity.current.account_id
  org_prefix    = var.org_prefix
  bucket_suffix = var.bucket_suffix
}
