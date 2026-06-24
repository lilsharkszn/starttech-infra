terraform {
  backend "s3" {
    bucket       = "hassan-starttech-tf-state"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
