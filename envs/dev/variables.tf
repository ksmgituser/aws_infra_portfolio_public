variable "env" {
  type = string
}

variable "system" {
  type = string
}

variable "department" {
  type = string
}

variable "domain" {
  description = "Subdomain managed by Route53 (e.g. portfolio.infra-nikki.com)"
  type        = string
}

variable "app_key" {
  description = "Laravel application key"
  type        = string
  sensitive   = true
}

variable "allowed_cidr" {
  description = "Allowed CIDR for ALB ingress (e.g. home IP)"
  type        = string
}

variable "org_prefix" {
  description = "組織固有のバケット名プレフィックス（例: com-infra-nikki）"
  type        = string
}

variable "bucket_suffix" {
  description = "S3バケット名のサフィックス（作成時の日時。例: 202603062236）"
  type        = string
}

