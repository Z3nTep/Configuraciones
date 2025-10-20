output "alb_dns" {
  value = aws_lb.wp_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress.endpoint
}

output "efs_id" {
  value = aws_efs_file_system.wp.id
}

output "route53_zone_id" {
  value = length(aws_route53_zone.wp_zone) > 0 ? aws_route53_zone.wp_zone[0].id : "No Route53 zone created"
}