output "name" {
  description = "Generated resource name based on naming convention"
  value       = local.name
}

output "tags" {
  description = "Common tags for AWS resources"
  value       = local.tags
}
