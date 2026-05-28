variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "parameters" {
  description = "Map of SSM parameters to create"
  type = map(object({
    value       = string
    type        = optional(string, "SecureString")
    description = optional(string, "")
  }))
  default = {}
}