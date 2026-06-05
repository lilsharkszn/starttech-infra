resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.environment}-redis-subnet-group"

  subnet_ids = var.private_cache_subnet_ids

  tags = {
    Name = "${var.environment}-redis-subnet-group"
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.environment}-redis-params"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.environment}-redis"

  description = "Redis replication group"

  engine         = "redis"
  engine_version = "7.0"
  node_type      = "cache.t3.micro"
  port           = 6379

  automatic_failover_enabled = true
  multi_az_enabled           = true

  num_cache_clusters = 2

  subnet_group_name = aws_elasticache_subnet_group.redis.name

  security_group_ids = [
    var.redis_security_group_id
  ]

  parameter_group_name = aws_elasticache_parameter_group.redis.name

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name = "${var.environment}-redis"
  }
}
