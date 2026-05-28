variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "repositories" {
  description = "Map of ECR repository definitions"
  type = map(object({
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
  }))
  default = {}
}

variable "lifecycle_policy_count" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 10
}