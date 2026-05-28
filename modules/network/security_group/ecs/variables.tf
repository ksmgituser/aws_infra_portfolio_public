variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}
