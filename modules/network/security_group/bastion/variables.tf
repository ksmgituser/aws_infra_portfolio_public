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
