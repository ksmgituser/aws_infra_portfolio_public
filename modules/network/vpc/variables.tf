variable "env" {
  type = string
}

variable "system" {
  type = string
}

variable "department" {
  type = string
}

variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "azs" {
  type = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "azs must contain at least one AZ."
  }
}

variable "public_subnets" {
  type = map(map(string))
  # AZ -> subnet用途 -> CIDR
}

variable "private_subnets" {
  type = map(map(string))
  # AZ -> subnet用途 -> CIDR
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}
