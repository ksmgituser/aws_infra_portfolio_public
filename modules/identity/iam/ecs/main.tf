# ------------------------------------------------
# naming
# ------------------------------------------------
module "task_role_naming" {
  source     = "../../../common/naming"
  env        = var.env
  system     = var.system
  service    = "identity"
  resource   = "ecs-task-role"
  department = var.department
}

module "exec_role_naming" {
  source     = "../../../common/naming"
  env        = var.env
  system     = var.system
  service    = "identity"
  resource   = "ecs-exec-role"
  department = var.department
}

# ------------------------------------------------
# 共通 assume role policy
# ------------------------------------------------
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ------------------------------------------------
# タスクロール
# アプリコンテナからAWSサービスへのアクセス用
# 現状はSSM Parameter Store読み取りのみ
# ------------------------------------------------
resource "aws_iam_role" "task" {
  name               = module.task_role_naming.name
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = module.task_role_naming.tags
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    sid    = "SSMParameterRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSExec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "task" {
  name   = "${module.task_role_naming.name}-policy"
  policy = data.aws_iam_policy_document.task_policy.json
  tags   = module.task_role_naming.tags
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

# ------------------------------------------------
# 実行ロール
# ECSエージェントがECRからイメージpull・
# CloudWatch Logsへのログ出力に使用
# ------------------------------------------------
resource "aws_iam_role" "exec" {
  name               = module.exec_role_naming.name
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = module.exec_role_naming.tags
}

resource "aws_iam_role_policy_attachment" "exec_ecr_logs" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 実行ロールにSSM読み取り権限を追加
data "aws_iam_policy_document" "exec_policy" {
  statement {
    sid    = "SSMParameterRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "exec" {
  name   = "${module.exec_role_naming.name}-policy"
  policy = data.aws_iam_policy_document.exec_policy.json
  tags   = module.exec_role_naming.tags
}

resource "aws_iam_role_policy_attachment" "exec_ssm" {
  role       = aws_iam_role.exec.name
  policy_arn = aws_iam_policy.exec.arn
}