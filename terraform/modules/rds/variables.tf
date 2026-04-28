variable "project"          {}
variable "vpc_id"           {}
variable "db_subnet_ids"    { type = list(string) }
variable "ec2_sg_id"        {}
variable "common_tags"      { type = map(string) }
variable "db_name"          { default = "whaledb" }
variable "db_username"      { default = "whaleadmin" }
variable "db_password"      { sensitive = true }