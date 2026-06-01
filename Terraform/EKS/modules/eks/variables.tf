# Module inputs: `cluster_name`, `cluster_version`, `vpc_id`, `subnet_ids`, and `node_groups` (map to configure worker groups).
variable "cluster_name" {
  description = "Name of EKS Cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes Version"
  type        = string
}

variable "vpc_id" {
  description = "value of vpc_id"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet Ids"
  type        = list(string)
}

variable "node_groups" {
  description = "EKS Node group configuration"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
  }))
}
