# wp-ac-terraform/route53.tf

# Zona hospedada (ej: aws.midominio.com)
resource "aws_route53_zone" "wp_zone" {
  name = var.domain_name
}

# Registros DNS para validar el certificado
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wp_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.wp_zone.zone_id
}

# Registro CNAME: wordpress.aws.midominio.com → ALB
resource "aws_route53_record" "wordpress_cname" {
  zone_id = aws_route53_zone.wp_zone.zone_id
  name    = "wordpress"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.wp_alb.dns_name]
}