output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

# Public Subnets
output "public_subnet_ids" {
  description = "Public subnet IDs (keyed by AZ)"
  value = {
    for az, subnet in aws_subnet.public :
    az => subnet.id
  }
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks (keyed by AZ)"
  value = {
    for az, subnet in aws_subnet.public :
    az => subnet.cidr_block
  }
}

# Private Subnets
output "private_subnet_ids" {
  description = "Private subnet IDs (keyed by AZ)"
  value = {
    for az, subnet in aws_subnet.private :
    az => subnet.id
  }
}

output "private_db_subnet_ids" {
  value = [
    for key, subnet in aws_subnet.private :
    subnet.id
    if can(regex("-db$", key))
  ]
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks (keyed by AZ)"
  value = {
    for az, subnet in aws_subnet.private :
    az => subnet.cidr_block
  }
}

# Route Tables
output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

# Internet Gateway
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

# NAT Gateway（optional）
output "nat_gateway_id" {
  description = "NAT Gateway ID (null if disabled)"
  value = try(
    one(aws_nat_gateway.this[*].id),
    null
  )
}

output "nat_eip_id" {
  description = "NAT Gateway EIP ID (null if disabled)"
  value = try(
    one(aws_eip.nat[*].id),
    null
  )
}
