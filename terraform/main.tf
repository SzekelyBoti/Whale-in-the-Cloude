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

module "security_groups" {
  source      = "./modules/security_groups"
  project     = local.project
  vpc_id      = module.vpc.vpc_id
  common_tags = local.common_tags
}

module "alb" {
  source            = "./modules/alb"
  project           = local.project
  public_subnet_ids = module.vpc.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  alb_sg_id         = module.security_groups.alb_sg_id
  common_tags       = local.common_tags
}

module "ec2" {
  source              = "./modules/ec2"
  project             = local.project
  private_subnet_ids  = module.vpc.private_subnet_ids
  ec2_sg_id           = module.security_groups.ec2_sg_id
  instance_profile    = module.iam.instance_profile_name
  key_pair_name       = var.key_pair_name
  instance_type       = var.instance_type
  account_id          = var.account_id
  region              = local.region
  target_group_arn    = module.alb.target_group_arn
  common_tags         = local.common_tags
}