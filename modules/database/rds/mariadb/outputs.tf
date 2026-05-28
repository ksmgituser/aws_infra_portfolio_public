output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "address" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "password" {
  description = "RDS master password"
  value       = local.final_db_password
  sensitive   = true
}

# output "security_group_id" {
#   value = aws_security_group.this.id
# }

