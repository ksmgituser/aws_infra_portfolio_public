variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ECS security group ID"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID"
  type        = string
}