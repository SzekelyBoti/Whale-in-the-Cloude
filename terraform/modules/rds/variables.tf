variable "project"       {}
variable "vpc_id"        {}
variable "db_subnet_ids" { type = list(string) }
variable "ec2_sg_id"     {}
variable "common_tags"   { type = map(string) }
variable "db_password"   { sensitive = true }

variable "db_name" {
  type    = string
  default = "whaledb"
}

variable "db_username" {
  type    = string
  default = "whaleadmin"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "15"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = true
}