variable "project"          {}
variable "public_subnet_id" {}
variable "key_pair_name"    {}
variable "ec2_sg_id"        {}
variable "common_tags"      { type = map(string) }