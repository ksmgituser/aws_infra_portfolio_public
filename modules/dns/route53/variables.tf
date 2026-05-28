variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "domain" {
  description = "Subdomain to manage in Route53 (e.g. portfolio.infra-nikki.com)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for Alias record"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for Alias record"
  type        = string
}