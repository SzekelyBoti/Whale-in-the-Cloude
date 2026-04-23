variable "project"       {}
variable "vpc_cidr"      {}
variable "public_cidrs"  { type = list(string) }
variable "private_cidrs" { type = list(string) }
variable "db_cidrs"      { type = list(string) }
variable "azs"           { type = list(string) }
variable "common_tags"   { type = map(string) }