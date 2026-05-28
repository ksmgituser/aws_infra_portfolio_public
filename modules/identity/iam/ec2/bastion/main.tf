# iam role naming
module "iam_role_naming" {
  source = "../../../../common/naming"

  env        = var.env
  system     = var.system
  service    = "bastion"
  resource   = "iamrole"
  department = var.department
  
}


# iam role
resource "aws_iam_role" "this" {
  name = module.iam_role_naming.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = module.iam_role_naming.tags
}


resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# インスタンスプロファイル
resource "aws_iam_instance_profile" "this" {
  name = "${module.iam_role_naming.name}-instance-profile"
  role = aws_iam_role.this.name

  tags = module.iam_role_naming.tags
}