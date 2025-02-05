output "alb_dns" {
  value = aws_lb.wp_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.wp_db.endpoint
}
