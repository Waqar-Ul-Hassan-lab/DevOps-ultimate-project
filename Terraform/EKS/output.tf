output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
