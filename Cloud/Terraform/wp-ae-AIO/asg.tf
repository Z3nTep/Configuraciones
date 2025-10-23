data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    rds_endpoint = aws_db_instance.wordpress.endpoint
    efs_dns_name = aws_efs_file_system.wp.dns_name
  }
}

resource "aws_launch_template" "wp" {
  name          = "wp-ac-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.lab_profile.name
  }
  vpc_security_group_ids = [aws_security_group.ec2.id]
  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wp-ae-instance"
    }
  }
}

resource "aws_autoscaling_group" "wp" {
  launch_template {
    id      = aws_launch_template.wp.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  target_group_arns   = [aws_lb_target_group.wp_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "wp-ac-ac"
    propagate_at_launch = true
  }
}
