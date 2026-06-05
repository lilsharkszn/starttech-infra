output "backend_log_group_name" {
  value       = aws_cloudwatch_log_group.backend.name
  description = "Backend log group"
}
