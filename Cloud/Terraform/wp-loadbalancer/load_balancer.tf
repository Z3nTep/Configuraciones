resource "aws_lb" "wp_alb" {
  name               = "wp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.wp_sg.id]
  subnets            = aws_subnet.wp_subnet[*].id

  tags = { Name = "wp-alb" }
}

resource "aws_lb_target_group" "wp_tg" {
  name     = "wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.wp_vpc.id

  health_check {
    path                = "/index.php"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "wp_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "wp_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.wp_tg.arn
  target_id        = aws_instance.wp_instance[count.index].id
  port             = 80
}
