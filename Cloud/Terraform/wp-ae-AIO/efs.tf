resource "aws_efs_file_system" "wp" {
  creation_token = "wp-ae-efs"
  tags = {
    Name = "wp-ae-efs"
  }
}

resource "aws_efs_mount_target" "mounts" {
  count           = 2
  file_system_id  = aws_efs_file_system.wp.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}