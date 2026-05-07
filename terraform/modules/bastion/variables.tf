variable "project"          {}
variable "public_subnet_id" {}
variable "key_pair_name"    {}
variable "vpc_id"           {}
variable "common_tags"      { type = map(string) }

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}