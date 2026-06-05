provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "StartTech-project-karatu"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

