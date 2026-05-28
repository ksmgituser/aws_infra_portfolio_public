variable "env" {
  type = string
}

variable "system" {
  type = string
}

variable "department" {
  type = string
}

variable "role" {
  description = "Role of EC2 instance (e.g. bastion, app)"
  type        = string

  validation {
    condition     = contains(["bastion", "app", "web", "db"], var.role)
    error_message = "role must be one of: bastion, app, web, db"
  }
}

variable "ami_id" {
  description = "AMI ID for bastion EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where bastion EC2 is deployed"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to bastion EC2"
  type        = list(string)
  default     = null
}

variable "iam_instance_profile" {
  description = "IAM instance profile name for bastion EC2 (SSM)"
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size (GiB)"
  type        = number
  default     = 8
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"

  validation {
    condition = contains(
      ["gp2", "gp3", "io1", "io2", "standard", "st1", "sc1"],
      var.root_volume_type
    )
    error_message = "root_volume_type must be a valid EBS volume type"
  }
}
