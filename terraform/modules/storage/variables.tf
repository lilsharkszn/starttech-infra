variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "enable_cloudfront" {
  type        = bool
  description = "Enable CloudFront distribution — requires verified AWS account"
  default     = true
}
