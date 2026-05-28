# ------------------------------------------------
# naming
# ------------------------------------------------
module "naming" {
  source     = "../../common/naming"
  env        = var.env
  system     = var.system
  service    = "container"
  resource   = "ecs"
  department = var.department
}

# ------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/${var.env}-${var.system}-nginx"
  retention_in_days = var.log_retention_days
  tags              = module.naming.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.env}-${var.system}-php-fpm"
  retention_in_days = var.log_retention_days
  tags              = module.naming.tags
}

# ------------------------------------------------
# ECS Cluster
# ------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${module.naming.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = module.naming.tags
}

# ------------------------------------------------
# Task Definition
# ------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "${module.naming.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.exec_role_arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = var.nginx_image_uri
      essential = true
      cpu       = var.nginx_cpu
      memory    = var.nginx_memory

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nginx.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "nginx"
        }
      }
    },
    {
      name      = "php-fpm"
      image     = var.app_image_uri
      essential = true
      cpu       = var.app_cpu
      memory    = var.app_memory

      portMappings = [
        {
          containerPort = 9000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "APP_ENV",        value = "production" },
        { name = "APP_DEBUG",      value = "false" },
        { name = "APP_URL",        value = "https://${var.domain}" },
        { name = "DB_CONNECTION",  value = "mysql" },
        { name = "DB_PORT",        value = "3306" }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = var.db_host_ssm_arn
        },
        {
          name      = "DB_DATABASE"
          valueFrom = var.db_database_ssm_arn
        },
        {
          name      = "DB_USERNAME"
          valueFrom = var.db_username_ssm_arn
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = var.db_password_ssm_arn
        },
        {
          name      = "APP_KEY"
          valueFrom = var.app_key_ssm_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "php-fpm"
        }
      }
    }
  ])

  tags = module.naming.tags
}

# ------------------------------------------------
# ECS Service
# ------------------------------------------------
resource "aws_ecs_service" "this" {
  name            = "${module.naming.name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.blue_target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer
    ]
  }

  tags = module.naming.tags
}

# ------------------------------------------------
# Auto Scaling
# ------------------------------------------------
resource "aws_appautoscaling_target" "this" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${module.naming.name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_scale_out_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ------------------------------------------------
# CodeDeploy
# ------------------------------------------------
resource "aws_codedeploy_app" "this" {
  name             = "${module.naming.name}-codedeploy"
  compute_platform = "ECS"
  tags             = module.naming.tags
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_group_name  = "${module.naming.name}-deploy-group"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.this.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.https_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
      target_group {
        name = split("/", var.blue_target_group_arn)[1]
      }
      target_group {
        name = split("/", var.green_target_group_arn)[1]
      }
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 15
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# ------------------------------------------------
# CodeDeploy用IAMロール
# ------------------------------------------------
data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = "${module.naming.name}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
  tags               = module.naming.tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

