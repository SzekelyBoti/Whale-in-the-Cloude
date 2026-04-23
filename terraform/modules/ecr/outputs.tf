output "app_repo_url" {
  value = aws_ecr_repository.repos["${var.project}-app"].repository_url
}
output "nginx_repo_url" {
  value = aws_ecr_repository.repos["${var.project}-nginx"].repository_url
}