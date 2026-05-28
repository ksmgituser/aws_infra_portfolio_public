variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to place Interface endpoints (1AZ only for cost savings)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Interface endpoints"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "route_table_ids" {
  description = "Route table IDs to associate with S3 Gateway endpoint"
  type        = map(string)
}