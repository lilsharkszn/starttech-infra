variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "backend_security_group_id" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "mongo_uri" {
  type = string
}

variable "db_name" {
  type = string
}

variable "jwt_secret_key" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ecr_repository_url" {
  type        = string
  description = "URL of the ECR repository"
}

variable "redis_endpoint" {
  type        = string
  description = "Redis primary endpoint"
}
