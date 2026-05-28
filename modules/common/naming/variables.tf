variable "env" {
  description = "Environment name (e.g. dev, stg, prod)"
  type        = string
}

variable "system" {
  description = "System name (e.g. portfolio)"
  type        = string
}

variable "service" {
  description = "AWS service or logical service name (e.g. vpc, ecs, alb)"
  type        = string
}

variable "resource" {
  description = "Resource type or role (e.g. subnet, cluster, sg)"
  type        = string
}

variable "az" {
  description = "Availability Zone identifier (e.g. a, c). Optional."
  type        = string
  default     = null
}

variable "no" {
  description = "Sequential number (e.g. 01, 02). Optional."
  type        = string
  default     = null
}

variable "department" {
  description = "department name (e.g. it_operation)"
  type        = string
}
