provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/LabRole"
  }
}

data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
