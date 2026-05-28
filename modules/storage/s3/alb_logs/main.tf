# ------------------------------------------------
# naming
# ------------------------------------------------
module "naming" {
  source     = "../../../common/naming"
  env        = var.env
  system     = var.system
  service    = "s3"
  resource   = "alb-logs"
  department = var.department
}

# ------------------------------------------------
# S3バケット
# ------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = "${var.org_prefix}-${module.naming.name}-${var.bucket_suffix}"
  force_destroy = true

  tags = module.naming.tags
}

# ------------------------------------------------
# パブリックアクセスブロック
# ------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------
# バケットポリシー（ALBアクセスログ用）
# ------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBAccountPutObject"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.elb_account_id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.this.arn}/AWSLogs/${var.account_id}/*"
      },
      {
        Sid    = "AllowLogDeliveryPutObject"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.this.arn}/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowLogDeliveryGetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.this.arn
      }
    ]
  })
}

# ------------------------------------------------
# ライフサイクル（自動削除）
# ------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.expiration_days
    }
  }
}
