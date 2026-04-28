variable "project"     {}
variable "vpc_id"      {}
variable "subnet_ids"  { type = list(string) }
variable "rds_sg_id"   {}
variable "db_host"     {}
variable "db_name"     {}
variable "db_username" {}
variable "db_password" { sensitive = true }
variable "common_tags" { type = map(string) }