variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "ecs_security_group_id" {
  description = "ECS security group ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "exec_role_arn" {
  description = "ECS execution role ARN"
  type        = string
}

variable "nginx_image_uri" {
  description = "nginx container image URI"
  type        = string
}

variable "app_image_uri" {
  description = "php-fpm container image URI"
  type        = string
}

variable "blue_target_group_arn" {
  description = "Blue target group ARN"
  type        = string
}

variable "green_target_group_arn" {
  description = "Green target group ARN"
  type        = string
}

variable "https_listener_arn" {
  description = "HTTPS listener ARN"
  type        = string
}

variable "test_listener_arn" {
  description = "Test listener ARN for Blue/Green"
  type        = string
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Task-level CPU units (e.g. 512 = 0.5vCPU)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task-level memory (MB)"
  type        = number
  default     = 1024
}

variable "nginx_cpu" {
  description = "nginx container CPU units"
  type        = number
  default     = 256
}

variable "nginx_memory" {
  description = "nginx container memory (MB)"
  type        = number
  default     = 512
}

variable "app_cpu" {
  description = "php-fpm container CPU units"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "php-fpm container memory (MB)"
  type        = number
  default     = 512
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for Auto Scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for Auto Scaling"
  type        = number
  default     = 4
}

variable "cpu_scale_out_threshold" {
  description = "CPU utilization threshold for scale out (%)"
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix"
  type        = string
  default     = "/dev/portfolio/rds/mariadb"
}

variable "domain" {
  description = "Application domain for APP_URL"
  type        = string
}

variable "app_key_ssm_arn" {
  description = "SSM Parameter ARN for APP_KEY"
  type        = string
}

variable "db_host_ssm_arn" {
  description = "SSM Parameter ARN for DB_HOST"
  type        = string
}

variable "db_database_ssm_arn" {
  description = "SSM Parameter ARN for DB_DATABASE"
  type        = string
}

variable "db_username_ssm_arn" {
  description = "SSM Parameter ARN for DB_USERNAME"
  type        = string
}

variable "db_password_ssm_arn" {
  description = "SSM Parameter ARN for DB_PASSWORD"
  type        = string
}

