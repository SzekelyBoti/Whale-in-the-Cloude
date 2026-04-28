output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "Full endpoint including port"
}

output "db_host" {
  value       = aws_db_instance.main.address
  description = "Hostname only, no port"
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_username" {
  value = aws_db_instance.main.username
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}