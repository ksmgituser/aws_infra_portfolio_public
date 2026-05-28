variable "env" {
  type = string
}

variable "system" {
  type = string
}

variable "department" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID where security group is created"
  type        = string
}

variable "db_port" {
  type    = number
  default = 3306

  validation {
    condition     = var.db_port > 0 && var.db_port <= 65535
    error_message = "db_port must be between 1 and 65535"
  }
}

variable "allowed_sg_ids" {
  type = list(string)

  validation {
    condition     = length(var.allowed_sg_ids) > 0
    error_message = "allowed_sg_ids must contain at least one security group ID"
  }
}