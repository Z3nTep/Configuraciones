resource "aws_db_subnet_group" "rds" {
  name       = "wp-ae-sg-rds"
  subnet_ids = [aws_subnet.private[2].id, aws_subnet.private[3].id]
  tags = {
    Name = "wp-ae-sg-rds"
  }
}

resource "aws_db_instance" "wordpress" {
  identifier           = "wp-ae-rds"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Ultr4ins3gur4!"
  db_name              = "wordpressdb01"
  allocated_storage    = 20
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.rds.name
  skip_final_snapshot  = true
  tags = {
    Name = "wp-ae-rds"
  }
}