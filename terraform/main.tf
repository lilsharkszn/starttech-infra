module "networking" {
  source = "./modules/networking"

  environment = var.environment

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_app_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]

  private_cache_subnet_cidrs = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}

module "storage" {
  source = "./modules/storage"

  environment = var.environment

  # ── will  Set to true once AWS verifies my account ───
  enable_cloudfront = var.enable_cloudfront
}

module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
}

module "cache" {
  source = "./modules/cache"

  environment = var.environment

  private_cache_subnet_ids = module.networking.private_cache_subnet_ids
  redis_security_group_id  = module.networking.sg_redis_id
}

module "compute" {
  source = "./modules/compute"

  environment = var.environment

  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  backend_security_group_id = module.networking.sg_backend_id
  alb_security_group_id     = module.networking.sg_alb_id
  instance_type             = "t3.micro"
  ami_id                    = "ami-084568db4383264d4"
  key_name                  = "adejare"

  mongo_uri      = var.mongo_uri
  db_name        = var.db_name
  jwt_secret_key = var.jwt_secret_key

  aws_region         = var.aws_region
  ecr_repository_url = module.ecr.repository_url
  redis_endpoint     = module.cache.redis_primary_endpoint
}

module "monitoring" {
  source = "./modules/monitoring"

  environment = var.environment

  autoscaling_group_name     = module.compute.autoscaling_group_name
  alb_arn_suffix             = module.compute.alb_arn_suffix
  redis_replication_group_id = module.cache.redis_replication_group_id
}
