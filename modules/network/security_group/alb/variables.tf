variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_cidr" {
  description = "Allowed CIDR for ALB ingress"
  type        = string
  default     = "0.0.0.0/0"
}
