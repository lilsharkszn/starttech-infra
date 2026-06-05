resource "aws_cloudwatch_log_group" "backend" {
  name              = "/starttech/backend"
  retention_in_days = 14

  tags = {
    Environment = var.environment
  }
}
