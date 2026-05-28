output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.task.arn
}

output "exec_role_arn" {
  description = "ECS execution role ARN"
  value       = aws_iam_role.exec.arn
}