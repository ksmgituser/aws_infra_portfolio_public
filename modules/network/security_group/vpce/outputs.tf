output "security_group_id" {
  description = "VPC endpoint security group ID"
  value       = aws_security_group.this.id
}