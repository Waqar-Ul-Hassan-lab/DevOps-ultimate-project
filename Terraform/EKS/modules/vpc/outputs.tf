# Exports VPC and subnet IDs for use by other modules (for example, the EKS module expects `private_subnet_id`).
output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet id"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet ids"
  value       = aws_subnet.private[*].id
}

# what is aws_subnet.public[*].id? expression is doing ?
# It is basically a way to get the IDs of all the public subnets created by the aws_subnet.public resource. The [*] syntax is used to access all elements of the list of subnets, and .id retrieves the ID of each subnet. So, this output will return a list of IDs for all the public subnets created in the VPC.
# e.g in numerical form, if there are 3 public subnets created, the output will be something like:
# public_subnet_id = [
#   "subnet-0123456789abcdef0",
#   "subnet-0123456789abcdef1",
#   "subnet-0123456789abcdef2"
# ]
