terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region
}

module "vpc" {
  source        = "./modules/vpc"
  project       = local.project
  vpc_cidr      = local.vpc_cidr
  public_cidrs  = local.public_cidrs
  private_cidrs = local.private_cidrs
  db_cidrs      = local.db_cidrs
  azs           = local.azs
  common_tags   = local.common_tags
}

module "ecr" {
  source      = "./modules/ecr"
  project     = local.project
  common_tags = local.common_tags
}

module "iam" {
  source      = "./modules/iam"
  project     = local.project
  common_tags = local.common_tags
}

module "alb" {
  source            = "./modules/alb"
  project           = local.project
  public_subnet_ids = module.vpc.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  common_tags       = local.common_tags
}

module "ec2" {
  source             = "./modules/ec2"
  project            = local.project
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  alb_sg_id          = module.alb.alb_sg_id
  instance_profile   = module.iam.instance_profile_name
  key_pair_name      = var.key_pair_name
  instance_type      = var.instance_type
  account_id         = var.account_id
  region             = local.region
  target_group_arn   = module.alb.target_group_arn
  common_tags        = local.common_tags
  db_host            = module.rds.db_host
  db_name            = module.rds.db_name
  db_username        = module.rds.db_username
  db_password        = var.db_password
}

module "rds" {
  source        = "./modules/rds"
  project       = local.project
  vpc_id        = module.vpc.vpc_id
  db_subnet_ids = module.vpc.db_subnet_ids
  ec2_sg_id     = module.ec2.ec2_sg_id
  db_password   = var.db_password
  common_tags   = local.common_tags
}

module "bastion" {
  source           = "./modules/bastion"
  project          = local.project
  public_subnet_id = module.vpc.public_subnet_ids[0]
  key_pair_name    = var.key_pair_name
  vpc_id           = module.vpc.vpc_id
  common_tags      = local.common_tags
}

module "lambda_seed" {
  source      = "./modules/lambda_seed"
  project     = local.project
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  rds_sg_id   = module.rds.rds_sg_id
  db_host     = module.rds.db_host
  db_name     = module.rds.db_name
  db_username = module.rds.db_username
  db_password = var.db_password
  common_tags = local.common_tags
}

resource "random_id" "suffix" {
  byte_length = 4
}

module "whale_reports_bucket" {
  source      = "./modules/s3"
  bucket_name = local.reports_bucket_name
  tags        = local.common_tags
}

module "lambda_report" {
  source        = "./modules/lambda_report"
  project       = local.project
  function_name = "whale-report-lambda"
  filename      = "lambda/report.zip"
  bucket_name   = module.whale_reports_bucket.bucket_name
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids
  server_ips    = module.ec2.private_ips
  ec2_sg_id     = module.ec2.ec2_sg_id
  common_tags   = local.common_tags
}