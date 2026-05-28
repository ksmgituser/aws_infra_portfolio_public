output "security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.this.id
}

output "security_group_ids" {
  description = "RDS security group IDs"
  value       = [aws_security_group.this.id]
}

output "security_group_name" {
  description = "RDS security group name"
  value       = aws_security_group.this.name
}
