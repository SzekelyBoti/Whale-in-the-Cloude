variable "project"           {}
variable "vpc_id"            {}
variable "public_subnet_ids" { type = list(string) }
variable "common_tags"       { type = map(string) }

variable "alb_port" {
  type    = number
  default = 80
}

variable "alb_protocol" {
  type    = string
  default = "HTTP"
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "health_check_healthy_threshold" {
  type    = number
  default = 2
}

variable "health_check_unhealthy_threshold" {
  type    = number
  default = 3
}

variable "health_check_interval" {
  type    = number
  default = 30
}