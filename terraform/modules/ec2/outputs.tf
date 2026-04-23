output "instance_ids"  { value = aws_instance.servers[*].id }
output "private_ips"   { value = aws_instance.servers[*].private_ip }