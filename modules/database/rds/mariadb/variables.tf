variable "env" {
  type = string
}

variable "system" {
  type = string
}

variable "department" {
  type = string
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs are required for an RDS subnet group."
  }
}

variable "engine_version" {
  description = "MariaDB engine version"
  type        = string
  default     = "10.6"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "storage_type" {
  type    = string
  default = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Invalid storage_type"
  }
}

locals {
  min_storage_by_engine = {
    mariadb    = 20
    mysql      = 20
    postgres   = 20
  }
}

variable "allocated_storage" {
  type    = number
  default = 20

  validation {
    condition = var.allocated_storage >= local.min_storage_by_engine["mariadb"]
    error_message = "allocated_storage is smaller than minimum required for this engine."
  }
}

variable "multi_az" {
  description = "Enable Multi-AZ. Should be enabled only for production due to additional cost."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention days (0 disables automated backups)"
  type        = number
  default     = 0

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35 days."
  }
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "auto_minor_version_upgrade" {
  description = "Whether to automatically upgrade minor engine versions"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Initial database name. Must not be empty."
  type        = string

  validation {
    condition     = length(trimspace(var.db_name)) > 0
    error_message = "db_name must not be an empty string."
  }
}

variable "username" {
  type = string 
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_password" {
  description = "Optional DB password. If null, random password will be generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "backup_window" {
  description = "Preferred backup window (UTC). e.g. '18:00-19:00'"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC). e.g. 'Sun:19:00-Sun:20:00'"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs for RDS"
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security group ID must be specified for RDS."
  }
}
