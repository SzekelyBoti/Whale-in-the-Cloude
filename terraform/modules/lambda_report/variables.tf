variable "project" {}
variable "function_name" {}
variable "filename" {}
variable "bucket_name" {}
variable "vpc_id" {}

variable "subnet_ids" {
  type = list(string)
}

variable "server_ips" {
  type        = list(string)
  description = "Private IPs of EC2 instances"
}

variable "common_tags" {
  type = map(string)
}

variable "ec2_sg_id" {
  type = string
}