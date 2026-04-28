output "public_ip" {
  value = aws_instance.bastion.public_ip
}

output "ssh_command" {
  value = "ssh -i whale-key.pem ec2-user@${aws_instance.bastion.public_ip}"
}