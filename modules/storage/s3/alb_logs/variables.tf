variable "env"        { type = string }
variable "system"     { type = string }
variable "department" { type = string }

variable "account_id" {
  description = "AWSアカウントID（バケットポリシーのResource ARN用）"
  type        = string
}

variable "elb_account_id" {
  description = "ELBサービスアカウントID（リージョン固有。ap-northeast-1は582318560864）"
  type        = string
  default     = "582318560864"
}

variable "org_prefix" {
  description = "組織固有のバケット名プレフィックス（例: com-infra-nikki）"
  type        = string
}

variable "bucket_suffix" {
  description = "バケット名のサフィックス。グローバル一意性確保のため作成時の日時を使用（例: 202603062236）。terraform apply -var='bucket_suffix=$(date +%Y%m%d%H%M)' で渡す"
  type        = string
}

variable "expiration_days" {
  description = "ログの保持日数"
  type        = number
  default     = 90
}
