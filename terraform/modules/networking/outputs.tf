output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_cache_subnet_ids" {
  description = "Private cache subnet IDs"
  value       = aws_subnet.private_cache[*].id
}
output "sg_alb_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID"
}

output "sg_backend_id" {
  value       = aws_security_group.backend.id
  description = "Backend EC2 security group ID"
}

output "sg_redis_id" {
  value       = aws_security_group.redis.id
  description = "Redis security group ID"
}
