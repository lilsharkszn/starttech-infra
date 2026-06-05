output "bucket_name" {
  value       = aws_s3_bucket.frontend.bucket
  description = "Frontend S3 bucket name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.frontend.arn
  description = "Frontend S3 bucket ARN"
}

output "cloudfront_domain_name" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.frontend[0].domain_name : null
  description = "CloudFront distribution domain — null when CloudFront is disabled"
}

output "cloudfront_distribution_id" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.frontend[0].id : null
  description = "CloudFront distribution ID — null when CloudFront is disabled"
}
