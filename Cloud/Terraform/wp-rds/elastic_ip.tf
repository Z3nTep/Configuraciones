resource "aws_eip" "wp_eip" {
  instance = aws_instance.wp_instance.id
  domain   = "vpc"
  tags = { Name = "wp_eip" }
}
