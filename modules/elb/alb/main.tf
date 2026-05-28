# ------------------------------------------------
# naming
# ------------------------------------------------
module "naming" {
  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "network"
  resource   = "alb"
  department = var.department
}

locals {
  tg_blue_name  = "${var.env}-${var.system}-tg-blue"
  tg_green_name = "${var.env}-${var.system}-tg-green"
}

# ------------------------------------------------
# ALB本体
# ------------------------------------------------
resource "aws_lb" "this" {
  name               = module.naming.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.access_logs_bucket
    enabled = true
  }

  tags = module.naming.tags
}

# ------------------------------------------------
# Target Group（Blue）
# ------------------------------------------------
resource "aws_lb_target_group" "blue" {
  name        = local.tg_blue_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(module.naming.tags, { Resource = "tg-blue" })
}

# ------------------------------------------------
# Target Group（Green）
# ------------------------------------------------
resource "aws_lb_target_group" "green" {
  name        = local.tg_green_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(module.naming.tags, { Resource = "tg-green" })
}

# ------------------------------------------------
# リスナー① HTTP(80) → HTTPSリダイレクト
# ------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(module.naming.tags, { Resource = "listener-http" })
}

# ------------------------------------------------
# リスナー② HTTPS(443) → Blue TG
# ------------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = merge(module.naming.tags, { Resource = "listener-https" })

  lifecycle {
    ignore_changes = [default_action]
  }
}

# ------------------------------------------------
# リスナー③ HTTP(8080) → Green TG（Blue/Green検証用）
# ------------------------------------------------
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.this.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  tags = merge(module.naming.tags, { Resource = "listener-test" })

  lifecycle {
    ignore_changes = [default_action]
  }
}