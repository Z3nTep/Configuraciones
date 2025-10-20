variable "region" {
  default = "us-east-1"
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