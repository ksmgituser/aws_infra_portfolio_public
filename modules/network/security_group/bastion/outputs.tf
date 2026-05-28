output "id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}

output "name" {
  description = "Security group name"
  value       = aws_security_group.this.name
}

output "security_group_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.this.id
}