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