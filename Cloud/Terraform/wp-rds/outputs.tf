output "ec2_public_ip" {
  value = aws_eip.wp_eip.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.wp_db.endpoint
}
