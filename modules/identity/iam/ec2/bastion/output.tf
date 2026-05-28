output "role_name" {
  description = "IAM role name for EC2"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "IAM role ARN for EC2"
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "IAM instance profile name for EC2"
  value       = aws_iam_instance_profile.this.name
}
