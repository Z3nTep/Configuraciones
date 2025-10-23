resource "aws_lb_target_group" "wp" {
  name        = "wp-ae-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.wp_ae_vpc.id
  target_type = "instance"

  health_check {
    path                = "/ip-interna.php"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "wp_alb" {
  name               = "wp-ae-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  tags = {
    Name = "wp-ae-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp.arn
  }
}

resource "aws_acm_certificate" "wp_cert" {
  count             = var.domain_name != "" && var.wordpress_subdomain != "" ? 1 : 0
  domain_name       = var.wordpress_subdomain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "wp_zone" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

resource "aws_route53_record" "cert_validation" {
  count = length(aws_acm_certificate.wp_cert) > 0 ? length(aws_acm_certificate.wp_cert[0].domain_validation_options) : 0

  name    = aws_acm_certificate.wp_cert[0].domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.wp_cert[0].domain_validation_options[count.index].resource_record_type
  zone_id = aws_route53_zone.wp_zone[0].zone_id
  records = [aws_acm_certificate.wp_cert[0].domain_validation_options[count.index].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "wp_cert" {
  count           = length(aws_acm_certificate.wp_cert)
  certificate_arn = aws_acm_certificate.wp_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_lb_listener" "https" {
  count             = length(aws_acm_certificate_validation.wp_cert) > 0 ? 1 : 0
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.wp_cert[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp.arn
  }
}

resource "aws_route53_record" "wordpress_cname" {
  count = var.wordpress_subdomain != "" && length(aws_route53_zone.wp_zone) > 0 ? 1 : 0
  zone_id = aws_route53_zone.wp_zone[0].zone_id
  name    = "wordpress"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.wp_alb.dns_name]
}
