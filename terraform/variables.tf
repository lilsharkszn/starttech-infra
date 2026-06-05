variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "mongo_uri" {
  description = "MongoDB Atlas connection URI"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "MongoDB database name"
  type        = string
  default     = "much_todo_db"
}

variable "jwt_secret_key" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution — requires verified AWS account"
  type        = bool
  default     = false
}
