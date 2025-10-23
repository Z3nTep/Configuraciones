variable "region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  description = "The AWS account ID to assume role in"
  type        = string
}

variable "domain_name" {
  description = "Dominio para Route53 (ej: aws.midominio.com)"
  type        = string
  default     = ""
}

variable "wordpress_subdomain" {
  description = "Subdominio para WordPress (ej: wordpress.aws.midominio.com)"
  type        = string
  default     = ""
}
