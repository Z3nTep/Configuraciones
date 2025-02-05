resource "aws_db_subnet_group" "wp_db_subnet_group" {
  name       = "wp-db-subnet-group-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  subnet_ids = [aws_subnet.wp_subnet_1.id, aws_subnet.wp_subnet_2.id]

  tags = { Name = "wp_db_subnet_group" }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_db_instance" "wp_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "wordpressdb"
  username               = "admin"
  password               = "P4ssw0rd123!"
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.wp_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = { Name = "wp_db" }
}
