# alb.tf

resource "aws_lb" "wp_alb" {
  name               = "wp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id 

  enable_deletion_protection = false

  tags = {
    Name = "wp-alb"
  }
}

resource "aws_lb_target_group" "wp_tg" {
  name     = "wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wp_ae_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "wp-tg"
  }
}

resource "aws_lb_listener" "wp_https_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.wp_cert.arn  # ← referencia, no definición

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}

# Opcional: redirección HTTP → HTTPS
resource "aws_lb_listener" "wp_http_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
