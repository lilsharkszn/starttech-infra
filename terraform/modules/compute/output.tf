output "alb_dns_name" {
  value       = aws_lb.backend.dns_name
  description = "ALB public DNS name"
}

output "alb_arn_suffix" {
  value       = aws_lb.backend.arn_suffix
  description = "ALB ARN suffix for CloudWatch metrics"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.backend.name
  description = "Auto Scaling Group name"
}
