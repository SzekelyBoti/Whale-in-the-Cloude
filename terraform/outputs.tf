output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Hit this URL to test your setup"
}

output "ecr_app_url" {
  value = module.ecr.app_repo_url
}

output "ecr_nginx_url" {
  value = module.ecr.nginx_repo_url
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "bastion_ssh" {
  value = module.bastion.ssh_command
}

output "server_ips" {
  value = module.ec2.private_ips
}

output "lambda_seed_name" {
  value = module.lambda_seed.function_name
}