output "vpc_owner_id" {
  value       = aws_vpc.vpc.owner_id
  description = "The owner ID of the VPC."
}

output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The ID of the VPC."
}

output "private_subnets" {
  value       = aws_subnet.aws_subnet_private_subnet.*.id
  description = "IDs of all Private subnets."
}
output "public_subnets" {
  value       = aws_subnet.aws_subnet_public.*.id
  description = "IDs of all Public subnets."
}

output "private_routing_tables_id" {
  value       = aws_route_table.aws_route_table_private.*.id
  description = "IDs of private routing tables."
}

output "eks_node_group_sg_id" {
  value       = aws_security_group.node_group_sg.id
  description = "ID of the security group for the EKS node group."
}
