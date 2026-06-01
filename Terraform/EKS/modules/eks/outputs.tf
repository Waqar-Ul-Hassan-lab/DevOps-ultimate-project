# Exports the cluster `name` and API `endpoint` for kubeconfig or other modules to consume.
output "name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}
