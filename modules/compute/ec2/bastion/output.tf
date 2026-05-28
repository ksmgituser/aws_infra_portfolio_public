output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP address of EC2"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of EC2 (if exists)"
  value       = aws_instance.this.public_ip
}

output "subnet_id" {
  description = "Subnet ID where EC2 is deployed"
  value       = aws_instance.this.subnet_id
}
