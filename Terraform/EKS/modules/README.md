EKS modules overview

- eks: Creates an Amazon EKS cluster, node IAM roles, policy attachments, and node groups.
- vpc: Creates VPC, public/private subnets, internet gateway, route tables, and associations.

Quick usage examples (minimal):

- VPC module (explicit CIDRs and AZs):
module "vpc" { source = "./modules/vpc"; vpc_cidr = "10.0.0.0/16"; availability_zones = ["us-east-1a","us-east-1b"]; private_subnet_cidrs = ["10.0.1.0/24","10.0.2.0/24"]; public_subnet_cidrs = ["10.0.101.0/24","10.0.102.0/24"]; cluster_name = "demo-cluster" }

- VPC module (using variables):
module "vpc" { source = "./modules/vpc"; vpc_cidr = var.vpc_cidr; availability_zones = var.availability_zones; private_subnet_cidrs = var.private_subnet_cidrs; public_subnet_cidrs = var.public_subnet_cidrs; cluster_name = var.cluster_name }

- EKS module (basic, using VPC outputs):
module "eks" { source = "./modules/eks"; cluster_name = "demo-cluster"; cluster_version = "1.24"; vpc_id = module.vpc.vpc_id; subnet_ids = module.vpc.private_subnet_id; node_groups = { default = { instance_types = ["t3.medium"], capacity_type = "ON_DEMAND", scaling_config = { desired_size = 2, max_size = 3, min_size = 1 } } } }

- EKS module (inline subnets and simple node group):
module "eks" { source = "./modules/eks"; cluster_name = "demo2"; cluster_version = "1.25"; vpc_id = "vpc-012345"; subnet_ids = ["subnet-aaa","subnet-bbb"]; node_groups = { workers = { instance_types = ["t3.small"], capacity_type = "ON_DEMAND", scaling_config = { desired_size = 1, max_size = 2, min_size = 1 } } } }

Notes:
- Keep CIDR and AZ lists the same length when creating subnets.
- Adjust `node_groups` map to add/remove worker groups and change instance types or scaling.
