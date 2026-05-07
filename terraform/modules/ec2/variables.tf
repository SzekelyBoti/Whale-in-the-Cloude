variable "project"            {}
variable "private_subnet_ids" { type = list(string) }
variable "vpc_id"             {}
variable "alb_sg_id"          {}
variable "instance_profile"   {}
variable "key_pair_name"      {}
variable "instance_type"      {}
variable "account_id"         {}
variable "region"             {}
variable "target_group_arn"   {}
variable "common_tags"        { type = map(string) }
variable "db_host"            {}
variable "db_name"            {}
variable "db_username"        {}
variable "db_password"        { sensitive = true }

variable "app_port" {
  type    = number
  default = 80
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}