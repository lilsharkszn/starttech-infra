output "alb_arn_suffix" {
  value       = module.compute.alb_arn_suffix
  description = "ALB ARN suffix for CloudWatch metrics"
}

output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "ALB DNS name — used as backend API endpoint"
}

output "redis_replication_group_id" {
  value       = module.cache.redis_replication_group_id
  description = "Redis replication group ID"
}

output "redis_endpoint" {
  value       = module.cache.redis_primary_endpoint
  description = "Redis primary endpoint"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL for Docker image pushes"
}

output "frontend_bucket_name" {
  value       = module.storage.bucket_name
  description = "S3 bucket name for frontend deployment"
}

output "cloudfront_domain_name" {
  value       = module.storage.cloudfront_domain_name
  description = "CloudFront domain — use this as your frontend URL"
}

output "cloudfront_distribution_id" {
  value       = module.storage.cloudfront_distribution_id
  description = "CloudFront distribution ID — needed for cache invalidation"
}

output "backend_log_group_name" {
  value       = module.monitoring.backend_log_group_name
  description = "CloudWatch log group for backend logs"
}
