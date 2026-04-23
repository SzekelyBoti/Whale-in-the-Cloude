variable "region" {
  default = "eu-north-1"
}

variable "environment" {
  default = "dev"
}

variable "account_id" {
  description = "AWS account ID"
}

variable "key_pair_name" {
  description = "EC2 SSH key pair name"
}

variable "instance_type" {
  default = "t3.micro"
}