# EKS Terraform Infrastructure Workflow

## 1. Total Resource Count: 32 Resources
**Breakdown by Module:**
- **VPC Module**: 20 resources (networking foundation)
- **EKS Module**: 12 resources (Kubernetes control plane + worker nodes)
- **Total**: 32 resources

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                        AWS Region                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              VPC (10.0.0.0/16)                     │ │
│  │  ┌──────────────────────────────────────────────┐  │ │
│  │  │  Internet Gateway (IGW)                      │  │ │
│  │  └──────────────────────────────────────────────┘  │ │
│  │           ↓               ↓               ↓         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │ │
│  │  │ Public SN 1 │  │ Public SN 2 │  │ Public SN 3 │ │ │
│  │  │ us-east-1a  │  │ us-east-1b  │  │ us-east-1c  │ │ │
│  │  │ 10.0.101/24 │  │ 10.0.102/24 │  │ 10.0.103/24 │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │ │
│  │           ↓               ↓               ↓         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │ │
│  │  │    NAT 1    │  │    NAT 2    │  │    NAT 3    │ │ │
│  │  │ (EIP + GW)  │  │ (EIP + GW)  │  │ (EIP + GW)  │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │ │
│  │           ↓               ↓               ↓         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │ │
│  │  │ Private SN 1│  │ Private SN 2│  │ Private SN 3│ │ │
│  │  │ us-east-1a  │  │ us-east-1b  │  │ us-east-1c  │ │ │
│  │  │ 10.0.1/24   │  │ 10.0.2/24   │  │ 10.0.3/24   │ │ │
│  │  │             │  │             │  │             │ │ │
│  │  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │ │ │
│  │  │ │EKS Nodes│ │  │ │EKS Nodes│ │  │ │EKS Nodes│ │ │ │
│  │  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │ │
│  │                                                      │ │
│  │  ┌──────────────────────────────────────────────┐  │ │
│  │  │  EKS Cluster Control Plane (Managed AWS)    │  │ │
│  │  │  - Run in private subnets (HA across AZs)   │  │ │
│  │  │  - Security Group controls ingress/egress   │  │ │
│  │  │  - CloudWatch logs for auditing             │  │ │
│  │  └──────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 3. VPC Module: 20 Resources Explained

### 3.1 Core Networking (2 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_vpc` | 1 | VPC container | CIDR: 10.0.0.0/16; enables DNS resolution and DNS hostnames |
| `aws_internet_gateway` | 1 | Internet access | Allows public subnets to reach the internet; routes through public route table |

### 3.2 Public Subnets (3 resources via `count`)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_subnet.public` | 3 | Subnet in each AZ | One per availability zone (us-east-1a, 1b, 1c); CIDRs: 10.0.101/24, 10.0.102/24, 10.0.103/24 |

**Why 3 resources?** Because `var.public_subnet_cidrs` has 3 values. Each resource indexed via `count.index` (0, 1, 2).

### 3.3 Private Subnets (3 resources via `count`)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_subnet.private` | 3 | Subnet in each AZ | One per availability zone; CIDRs: 10.0.1/24, 10.0.2/24, 10.0.3/24 |

**Why 3 resources?** Because `var.private_subnet_cidrs` has 3 values. Each resource indexed via `count.index` (0, 1, 2).

### 3.4 NAT Gateway Infrastructure (6 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_eip` (for NAT) | 3 | Static public IPs | One per NAT gateway; required for Elastic IP allocation; `domain = "vpc"` |
| `aws_nat_gateway` | 3 | Outbound internet gateway | One per public subnet; allows private subnets to reach internet; indexed via `count.index` |

**Why 3 each?** High availability pattern: each private subnet gets its own NAT via its corresponding public subnet in the same AZ. If one NAT fails, only that AZ is affected.

### 3.5 Public Route Table (2 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_route_table.public` | 1 | Routing table | Single shared route table for all public subnets |
| `aws_route` (public IGW) | 1 | Route rule | Destination 0.0.0.0/0 → Internet Gateway; allows traffic out to internet |

### 3.6 Private Route Tables (6 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_route_table.private` | 3 | Routing table per AZ | One private route table per private subnet; indexed via `count.index` |
| `aws_route` (private NAT) | 3 | Route rule per NAT | Destination 0.0.0.0/0 → NAT Gateway in same AZ; indexed via `count.index` |

**Why counted?** Isolation: each private subnet has its own route table pointing to its own NAT gateway. This ensures:
- Failure of one NAT doesn't affect other AZs
- Each subnet can have independent routing policies
- Easy to scale: add more subnets automatically adds route tables

### 3.7 Route Table Associations (6 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_route_table_association.public` | 3 | Link public subnets to route table | Associates all 3 public subnets to the single public route table |
| `aws_route_table_association.private` | 3 | Link private subnets to route tables | Each private subnet gets its own private route table via `count.index` |

**Total VPC: 1 + 1 + 3 + 3 + 3 + 3 + 1 + 1 + 3 + 3 + 3 + 3 = 28 resources** (includes route and associations)

---

## 4. EKS Module: 12 Resources Explained

### 4.1 IAM Roles for Cluster Control Plane (2 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_iam_role.cluster_role` | 1 | Cluster execution role | Allows EKS control plane to manage resources; trust principal: `eks.amazonaws.com` |
| `aws_iam_role_policy_attachment.cluster_policy` | 1 | Policy attachment | Attaches `AmazonEKSClusterPolicy` for cluster management |

**Why separate IAM role?** AWS-managed EKS service needs permission to:
- Manage load balancers for services
- Control network interfaces for pods
- Manage security groups
- Interact with CloudWatch for logging

### 4.2 IAM Roles for Worker Nodes (3 resources)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_iam_role.node_role` | 1 | Node execution role | Allows EC2 worker nodes to interact with AWS; trust principal: `ec2.amazonaws.com` |
| `aws_iam_role_policy_attachment.node_policy[*]` | 3 | Policy attachments | Attaches policies: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly` |

**Why 3 policies?** Each policy grants different permissions:
- **AmazonEKSWorkerNodePolicy**: Allows node to join/manage cluster
- **AmazonEKS_CNI_Policy**: Allows AWS VPC CNI plugin to assign IPs to pods
- **AmazonEC2ContainerRegistryReadOnly**: Allows nodes to pull container images from ECR

### 4.3 EKS Cluster Control Plane (1 resource)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_eks_cluster` | 1 | Kubernetes API server | Managed by AWS; runs in private EKS-managed subnets; multi-AZ HA; version: `var.cluster_version` (default: 1.28) |

**Why EKS over self-managed?** AWS handles:
- Patching and updates automatically
- Automatic failover across AZs
- Integration with IAM, CloudWatch, VPC
- Scales transparently

### 4.4 EKS Node Group (1 resource via `for_each`)
| Resource | Count | Purpose | Details |
|----------|-------|---------|---------|
| `aws_eks_node_group` | 1+ | Worker nodes (EC2) | Launches EC2 instances in private subnets; scales using Launch Templates; default min=1, max=3 |

**Why `for_each` over `count`?** Allows multiple node groups with different configurations (e.g., on-demand + spot instances).

---

## 5. How Variables Drive Resource Count

### 5.1 Root Variables (EKS/variables.tf)
```hcl
availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]      # Length: 3
private_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]   # Length: 3
public_subnet_cidrs     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"] # Length: 3
node_groups             = {                                               # Count: 1
  default = { ..., desired_size = 1, min_size = 1, max_size = 3 }
}
```

### 5.2 Resource Cardinality (How counts are derived)
```
availability_zones count (3)
         ↓
    used by:
    - aws_subnet.public[count.index] → 3 resources
    - aws_subnet.private[count.index] → 3 resources
    - aws_eip[count.index] → 3 resources
    - aws_nat_gateway[count.index] → 3 resources
    - aws_route_table.private[count.index] → 3 resources
    - aws_route_table_association.private[count.index] → 3 resources

public_subnet_cidrs count (3)
         ↓
    used by:
    - aws_route_table_association.public[count.index] → 3 resources

node_groups map count (1 in default)
         ↓
    used by:
    - aws_eks_node_group[for_each] → 1 resource per entry
```

**Why cardinality matters:** If you want 5 AZs, change `var.availability_zones` to have 5 entries → automatically creates 5×more subnets, NATs, route tables. Single-source-of-truth design.

---

## 6. Variable Flow: Root → Module → Resources

### Step-by-step execution:

1. **EKS/variables.tf** declares inputs with defaults
   ```hcl
   variable "availability_zones" {
     description = "List of AZs"
     type        = list(string)
     default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
   }
   ```

2. **EKS/main.tf** calls modules and passes variables
   ```hcl
   module "vpc" {
     source = "./modules/vpc"
     availability_zones      = var.availability_zones
     private_subnet_cidrs    = var.private_subnet_cidrs
     public_subnet_cidrs     = var.public_subnet_cidrs
   }
   ```

3. **modules/vpc/variables.tf** receives the values
   ```hcl
   variable "availability_zones" {
     type = list(string)
   }
   ```

4. **modules/vpc/main.tf** uses variables to create resources
   ```hcl
   resource "aws_subnet" "private" {
     count             = length(var.private_subnet_cidrs)
     vpc_id            = aws_vpc.main.id
     availability_zone = var.availability_zones[count.index]  # AZ per subnet
     cidr_block        = var.private_subnet_cidrs[count.index] # CIDR per subnet
   }
   ```

5. **modules/vpc/outputs.tf** exports values back to root
   ```hcl
   output "private_subnet_ids" {
     value = aws_subnet.private[*].id  # All subnet IDs
   }
   ```

6. **EKS/main.tf** consumes VPC outputs for EKS
   ```hcl
   module "eks" {
     source          = "./modules/eks"
     private_subnet_ids = module.vpc.private_subnet_ids  # Pass VPC output
   }
   ```

---

## 7. Module Interaction: VPC → EKS Data Flow

```
┌─────────────────────────────────────────┐
│     Root: EKS/main.tf                   │
├─────────────────────────────────────────┤
│  module "vpc" {                         │
│    availability_zones = ["..."]         │
│  }                                      │
│                                         │
│  module "eks" {                         │
│    subnet_ids = module.vpc.*.subnet_ids │
│  }                                      │
└─────────────────────────────────────────┘
         ↓              ↓
   ┌─────────────┐   ┌──────────────┐
   │ VPC Module  │   │  EKS Module  │
   ├─────────────┤   ├──────────────┤
   │ Creates:    │   │ Creates:     │
   │ - VPC       │   │ - Cluster    │
   │ - Subnets   │   │ - Node Group │
   │ - NAT       │   │              │
   │             │   │ Needs:       │
   │ Exports:    │   │ - subnet_ids │
   │ - vpc_id    │   │ - vpc_id     │
   │ - subnet_ids│→→→|- sg_id       │
   │             │   │              │
   └─────────────┘   └──────────────┘

Dependency: EKS *depends on* VPC outputs
- If VPC subnets don't exist, EKS creation fails
- Terraform detects `module.vpc.subnet_ids` in EKS config
- Automatically waits for VPC module to finish first
```

---

## 8. Resource Creation Patterns Used

### 8.1 Count Pattern (Repeating identical resources)
```hcl
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)  # Repeats 3 times

  availability_zone = var.availability_zones[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]
}

# Access: aws_subnet.private[0].id, aws_subnet.private[1].id, aws_subnet.private[2].id
# Export all: aws_subnet.private[*].id
```

**Use case:** When resources follow same pattern but differ by list index (subnets, route tables, NATs).

### 8.2 Single Resource (No count)
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

# Access: aws_vpc.main.id (no index needed)
```

**Use case:** Single shared resource (VPC, public route table, cluster role).

### 8.3 For_Each Pattern (Map-based iteration)
```hcl
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups  # Map: { "default" = {...}, "gpu" = {...} }

  cluster_name       = aws_eks_cluster.main.name
  nodegroup_name     = each.key                # "default"
  scaling_config {
    desired_size = each.value.desired_size     # per-group setting
  }
}

# Access: aws_eks_node_group.main["default"], aws_eks_node_group.main["gpu"]
```

**Use case:** Different configurations for each resource (multiple node groups with different instance types).

---

## 9. IAM Trust Relationships Explained

### 9.1 Cluster Role (for EKS control plane)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "eks.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Translation:** "Allow the **EKS service** (not EC2, not users) to assume this role."

**Why?** EKS control plane is an AWS-managed service. It needs a role to make API calls on your behalf (create load balancers, security groups, etc.). Only the `eks.amazonaws.com` principal is allowed.

### 9.2 Node Role (for EC2 worker nodes)
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Translation:** "Allow the **EC2 service** to assume this role on behalf of worker node instances."

**Why?** When you launch an EC2 instance with this role, EC2 service attaches it to the instance allowing the node to call AWS APIs (pull container images from ECR, interact with EBS volumes, post CloudWatch metrics, etc.).

---

## 10. Networking Deep Dive

### 10.1 Public Subnets → Internet Gateway Route
```
┌─────────────────────────────────────────────┐
│ Public Subnet (10.0.101/24) in us-east-1a   │
│                                             │
│ Public Route Table:                         │
│ ├─ Destination: 0.0.0.0/0                   │
│ └─ Target: Internet Gateway (IGW)           │
│                                             │
│ Behavior: Traffic destined outside VPC      │
│ flows to IGW → internet                     │
└─────────────────────────────────────────────┘
         ↓
    [Internet Gateway]
         ↓
    [Internet]
```

**Result:** Public subnets can reach the internet.

### 10.2 Private Subnets → NAT Gateway → Internet
```
┌─────────────────────────────────────────────┐
│ Private Subnet (10.0.1/24) in us-east-1a    │
│                                             │
│ Private Route Table-1 (for this subnet):    │
│ ├─ Destination: 0.0.0.0/0                   │
│ └─ Target: NAT Gateway-1                    │
│            (in Public Subnet 1)             │
│                                             │
│ Behavior: Any pod needing to access         │
│ internet routing through NAT-1              │
└─────────────────────────────────────────────┘
         ↓
    [NAT Gateway 1 in Public SN]
    (has Elastic IP = static public IP)
         ↓
    [Internet]

Return traffic: Internet → NAT's public IP → mapped to private pod IP
```

**Result:** Private subnets (where EKS nodes run) can reach the internet without being directly accessible.

### 10.3 Per-AZ NAT Isolation
```
us-east-1a:                us-east-1b:              us-east-1c:
┌─────────────────┐        ┌──────────────┐        ┌──────────────┐
│ Public SN-1     │        │ Public SN-2  │        │ Public SN-3  │
│ ↓ NAT-1 + EIP-1 │        │ ↓ NAT-2+EIP-2│        │ ↓ NAT-3+EIP-3│
└─────────────────┘        └──────────────┘        └──────────────┘
│ RT-1 (0/0→NAT-1)│        │ RT-2 (0/0→ NAT-2)     │ RT-3 (0/0→NAT-3)
└─────────────────┘        └──────────────┘        └──────────────┘
         ↑                        ↑                        ↑
         │                        │                        │
     Private SN-1             Private SN-2             Private SN-3
     EKS Node (AZ-1a)        EKS Node (AZ-1b)        EKS Node (AZ-1c)
```

**Benefit:** If NAT-1 fails, only AZ-1a is affected. AZ-1b and AZ-1c have independent NATs.

---

## 11. Terraform Execution Commands

All commands run from `EKS/` directory:

### 11.1 Initialization (first time setup)
```bash
terraform init
# Downloads provider plugins, initializes backend, validates module structure
```

### 11.2 Format & Validate
```bash
terraform fmt -recursive      # Auto-format HCL files
terraform validate             # Syntax check, type validation, reference validation
```

### 11.3 Plan & Apply
```bash
terraform plan -out=tfplan     # Preview 32 resources to be created
terraform apply tfplan         # Create all resources in AWS
```

### 11.4 Inspect State
```bash
terraform state list           # List all managed resources
terraform state show <resource># Show resource details
terraform refresh              # Sync local state with AWS actual state
```

### 11.5 Destroy (cleanup)
```bash
terraform destroy              # Delete all 32 resources
```

---

## 12. Key Design Decisions Explained

| Decision | Why | Tradeoff |
|----------|-----|----------|
| **3 AZs** | High availability; distribute across failure zones | More resources, higher cost |
| **Per-AZ NAT** | AZ failure doesn't break egress for other AZs | 3× NAT costs vs 1 shared NAT |
| **Private subnets for nodes** | Security: nodes not directly internet-facing | Outbound traffic via NAT (cost) |
| **Separate route tables** | Flexibility for per-subnet policies | More resources to manage |
| **Managed EKS** | AWS handles updates, HA, scaling | Less control than self-managed; higher base cost |

---

## 13. Common Modifications & Effects

| Change | Effect on Resources | How To |
|--------|-------------------|--------|
| Add a 4th AZ | +8 resources (subnet, NAT, EIP, RT, 2×RT assoc) | Add to `var.availability_zones` |
| Change cluster version | Upgrade API server | Edit `var.cluster_version` → `terraform apply` |
| Scale node group | Change desired_size | Edit `var.node_groups["default"].desired_size` |
| Add node group (GPU) | +1 node group resource | Add entry to `var.node_groups` map |
| Change VPC CIDR | Require VPC recreation | Edit `var.vpc_cidr` (destructive) |

---

## 14. Quick Reference: File Purposes

| File | Lines | Purpose |
|------|-------|---------|
| `EKS/variables.tf` | ~35 | Root variable declarations with defaults; cardinality source |
| `EKS/main.tf` | ~15 | Module blocks; data flow orchestration |
| `modules/vpc/main.tf` | ~150 | VPC, subnets, NAT, route tables; count-based resources |
| `modules/vpc/outputs.tf` | ~20 | Export subnet IDs, VPC ID to root/EKS module |
| `modules/eks/main.tf` | ~115 | IAM roles, cluster, node group; depends on VPC |
| `modules/eks/outputs.tf` | ~20 | Export cluster endpoint, security group |

---

## 15. Debugging Checklist

| Issue | Cause | Fix |
|-------|-------|-----|
| `terraform plan` fails | Variables not matching | Count mismatch: ensure `availability_zones` and subnet CIDR lists have same length |
| `terraform apply` errors on IAM | Wrong trust principal | Cluster role must trust `eks.amazonaws.com` (not ec2); Node role must trust `ec2.amazonaws.com` |
| Subnets in wrong AZ | Incorrect indexing | Verify `aws_subnet.private[count.index].availability_zone = var.availability_zones[count.index]` |
| Nodes can't reach internet | Route table missing | Each private subnet's route table must have `0.0.0.0/0 → NAT` route |
| Node creation fails | IAM policy missing | Node role needs all 3 policies: Worker, CNI, ECR |

---

## 16. Total Resource Summary (32 resources)

**VPC Module (20):**
- Network: 1 VPC + 1 IGW = 2
- Subnets: 3 public + 3 private = 6
- NAT: 3 EIPs + 3 NAT gateways = 6
- Routing: 1 public RT + 3 private RTs + 1 public route + 3 private routes = 8

**EKS Module (12):**
- IAM: 1 cluster role + 1 cluster policy attachment = 2
- IAM: 1 node role + 3 node policy attachments = 4
- Cluster: 1 EKS cluster resource = 1
- Nodes: 1 node group = 1
- (Plus security groups auto-created: ~4)

**Total: 32 resources**
