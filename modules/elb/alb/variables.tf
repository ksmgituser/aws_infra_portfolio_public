variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for target groups"
  type        = string
  default     = "/login"
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  type        = string
}