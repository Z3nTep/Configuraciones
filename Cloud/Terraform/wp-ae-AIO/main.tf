provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  }
}

data "aws_caller_identity" "current" {}

provider "template" {
  version = "~> 2.2"
}