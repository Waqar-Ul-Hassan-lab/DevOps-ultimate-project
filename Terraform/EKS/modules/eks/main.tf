# Creates the EKS cluster, node IAM roles, policy attachments, and node groups — customize `node_groups` to change instance types and scaling.
#
# Summary: This file provisions the EKS control plane and managed node groups.
# It creates IAM roles for the cluster and for worker nodes, attaches AWS-managed
# policies required by EKS, then creates the `aws_eks_cluster` using the supplied
# `cluster_name`, `cluster_version`, and `subnet_ids`. The `node_groups` map is
# iterated to create one `aws_eks_node_group` per entry, applying instance types,
# capacity type, and scaling configuration. Dependencies ensure IAM policies are
# attached before creating the cluster and node groups.
# ================================================ #
resource "aws_iam_role" "cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# ================================================ #
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# ================================================ #
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster_role.arn


  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

}


# ================================================ #
# ================================================ #
# ================================================ #


resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


# ================================================ #
resource "aws_iam_role_policy_attachment" "node_policy" {
  # toset is the method to convert list to set. As we have to use for_each which only works with set or map. So we are converting list to set here. The purpose of using for_each is to avoid writing multiple aws_iam_role_policy_attachment resources for each policy. By using for_each, we can iterate over the list of policies and create a policy attachment for each one in a more efficient way.
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  policy_arn = each.value
  role       = aws_iam_role.node.name
}


# ================================================ #
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  depends_on = [aws_iam_role_policy_attachment.node_policy]

}
