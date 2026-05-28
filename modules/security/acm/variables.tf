variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "domain" {
  description = "Domain name for the certificate"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
}