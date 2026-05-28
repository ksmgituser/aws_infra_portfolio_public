output "interface_endpoint_ids" {
  description = "Interface endpoint IDs"
  value = {
    for k, v in aws_vpc_endpoint.interface : k => v.id
  }
}

output "s3_endpoint_id" {
  description = "S3 Gateway endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}