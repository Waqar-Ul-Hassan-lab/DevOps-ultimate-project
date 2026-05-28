
# 🚀 DevOps Ultimate Project — EKS Terraform

This repository provisions an Amazon EKS cluster and the networking it needs using modular Terraform code. The configuration is split into reusable modules under `EKS/modules/` (`vpc` and `eks`).

## 🎯 Project goal
- Create a repeatable, modular Terraform configuration to provision:
	- VPC with public and private subnets, Internet Gateway, and route tables
	- Amazon EKS control plane and managed node groups
- Keep module interfaces (inputs/outputs) clear so the root can reuse them across environments.

## 📁 Repository layout (key files)
- `EKS/main.tf` — root entry: provider, backend, and module instantiation.
- `EKS/variables.tf` — root-level configuration variables.
- `EKS/WORKFLOW.md` — visual flowchart and variable/module flow.
- `EKS/modules/vpc/` — VPC module (`main.tf`, `variables.tf`, `outputs.tf`).
- `EKS/modules/eks/` — EKS module (`main.tf`, `variables.tf`, `outputs.tf`).
- `EKS/modules/README.md` — quick module usage examples.

Explore the `EKS/` folder for Terraform code and `modules/` for implementations.

## 🔁 How variables flow (short)
1. Root variables are declared in `EKS/variables.tf` (e.g., `cluster_name`, `vpc_cidr`, `node_groups`).
2. `EKS/main.tf` passes root variables into module blocks, e.g.:
	 - `module "vpc" { vpc_cidr = var.vpc_cidr }`
	 - `module "eks" { cluster_name = var.cluster_name }`
3. Each module declares inputs in `modules/<name>/variables.tf` and uses `var.<name>` in `modules/<name>/main.tf`.
4. Modules export values via `modules/<name>/outputs.tf` (e.g., `vpc_id`, `private_subnet_id`) and the root accesses them as `module.<name>.<output>`.

Example chain: `EKS/variables.tf` → `EKS/main.tf` (module block) → `modules/vpc/variables.tf` → `modules/vpc/main.tf` → `modules/vpc/outputs.tf` → `EKS/main.tf` uses `module.vpc.private_subnet_id` for the EKS module.

## 🚀 Quick start (from `EKS/`)
Prerequisites:
- Install Terraform (v1.x compatible), AWS CLI, and `kubectl`.
- Configure AWS credentials with permissions for S3, DynamoDB, VPC, IAM, and EKS.

Run:
```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

> ⚠️ Ensure the S3 backend bucket and DynamoDB lock table referenced in `EKS/main.tf` exist and are accessible by your credentials.

## ⚙️ Common variables to edit
- `region` — AWS region (default `us-east-1`).
- `vpc_cidr` — VPC CIDR block.
- `availability_zones` — AZs for subnets.
- `private_subnet_cidrs` / `public_subnet_cidrs` — lists; MUST match the length of `availability_zones`.
- `cluster_name` / `cluster_version` — EKS cluster name and Kubernetes version.
- `node_groups` — map of worker groups (each becomes a managed node group).

See `EKS/variables.tf` for defaults and full specs.

## 🧩 Module responsibilities
- `modules/vpc`:
	- Builds VPC, public/private subnets (per AZ), Internet Gateway, and route tables.
	- Tags subnets for Kubernetes discovery.
	- Exports `vpc_id`, `public_subnet_id`, and `private_subnet_id`.
- `modules/eks`:
	- Creates IAM roles and attaches EKS-required policies.
	- Creates `aws_eks_cluster` and managed node groups from `node_groups` map.
	- Exports `name` and `endpoint`.

## 🛠 Troubleshooting (quick)
- `terraform validate` fails: run `terraform init` first to install providers.
- Backend errors: verify the S3 bucket and DynamoDB lock table exist and are reachable.
- Subnet/AZ mismatch: ensure `availability_zones` and subnet CIDR lists are the same length.
- IAM issues: verify your AWS identity has permissions to create IAM roles and policies.

## 📊 Workflow & diagram
See `EKS/WORKFLOW.md` for a Mermaid flowchart visualizing root → module variable and output flow.

## ✅ Next steps / optional improvements
- Add `validation` blocks in module `variables.tf` to assert list lengths.
- Add extra outputs (e.g., cluster security group, node role ARN) if needed.
- Add CI to run `terraform fmt`, `validate`, and `tflint` on PRs.

If you want, I can add a sample `terraform.tfvars`, validation blocks, or CI config — tell me which you'd like next.

