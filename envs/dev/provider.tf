# ----------------------------------------------------------
# Terraform configuration
# ----------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "com-infra-nikki-portfolio-artifact-bucket"
    key            = "tfstate/dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "portfolio-tfstate-lock"
    encrypt        = true
  }
}

# ----------------------------------------------------------
# Provider
# ----------------------------------------------------------
provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}