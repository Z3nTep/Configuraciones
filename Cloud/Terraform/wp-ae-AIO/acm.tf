# wp-ac-terraform/acm.tf

resource "aws_acm_certificate" "wp_cert" {
  domain_name       = var.wordpress_subdomain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "wp-ac-cert"
  }
}

# Validación automática vía Route 53
resource "aws_acm_certificate_validation" "wp_cert" {
  certificate_arn = aws_acm_certificate.wp_cert.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}