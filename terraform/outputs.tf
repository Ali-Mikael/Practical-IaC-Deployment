output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_ip" {
  value = aws_instance.bastion_host.public_ip
  description = "Public IP of bastion host"
}

output "private_ip" {
  value = aws_instance.bastion_host.private_ip
  description = "Private IP of bastion host"
}