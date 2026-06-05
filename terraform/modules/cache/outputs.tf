output "redis_primary_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Redis primary endpoint"
}

output "redis_reader_endpoint" {
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
  description = "Redis reader endpoint"
}

output "redis_replication_group_id" {
  value       = aws_elasticache_replication_group.redis.replication_group_id
  description = "Redis replication group ID"
}
