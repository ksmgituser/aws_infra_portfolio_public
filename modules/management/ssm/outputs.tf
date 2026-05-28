output "parameter_arns" {
  description = "SSM parameter ARNs keyed by parameter name"
  value = {
    for k, v in aws_ssm_parameter.this : k => v.arn
  }
}

output "parameter_names" {
  description = "SSM parameter names keyed by parameter name"
  value = {
    for k, v in aws_ssm_parameter.this : k => v.name
  }
}