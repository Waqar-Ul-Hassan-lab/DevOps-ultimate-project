# VPC inputs: `vpc_cidr`, `availability_zones`, `public_subnet_cidrs`, `private_subnet_cidrs`, and `cluster_name`. Lists must align in length.
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}
variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

# us-east-1 which is I am using

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}
variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}
variable "cluster_name" {
  description = "Name of EKS Cluster"
  type        = string
}