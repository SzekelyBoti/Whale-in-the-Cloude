locals {
  project = "whale"
  region  = var.region

  common_tags = {
    Project     = local.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # CIDR blocks in one place
  vpc_cidr        = "10.0.0.0/16"
  public_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
  db_cidrs        = ["10.0.20.0/24", "10.0.21.0/24"]
  azs             = ["${local.region}a", "${local.region}b"]
}