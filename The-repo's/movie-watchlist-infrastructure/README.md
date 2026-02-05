# Movie Watchlist Infrastructure

Infrastructure as Code (IaC) for deploying the Movie Watchlist application on AWS EKS using Terraform.

## 🏗️ Overview

This repository contains all Terraform configurations to provision a production-ready Kubernetes cluster on AWS with monitoring, logging, and GitOps capabilities.

## 📁 Repository Structure

```
movie-watchlist-infrastructure/
├── modules/                    # Terraform modules
│   ├── vpc/                   # VPC, subnets, NAT gateways
│   ├── eks/                   # EKS cluster and node groups
│   ├── iam-roles/             # IAM roles for service accounts
│   ├── security-groups/       # Network security
│   ├── alb-controller/        # AWS Load Balancer Controller
│   ├── external-secrets/      # External Secrets Operator
│   ├── argocd/               # ArgoCD GitOps controller
│   └── k8s-operators/        # Kubernetes operators
├── environments/              # Environment-specific variables
│   └── dev.tfvars
├── main.tf                    # Root module
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider versions
└── backend.tf                 # S3 backend configuration
```

## 🚀 Quick Start

### Prerequisites

**Required Tools:**
- Terraform >= 1.6
- AWS CLI v2
- kubectl >= 1.28
- helm >= 3.x

**AWS Permissions:**
- Administrator access or equivalent IAM permissions
- Access to create VPC, EKS, IAM, EC2, S3

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/jawna10/movie-watchlist-infrastructure.git
cd movie-watchlist-infrastructure

# Configure AWS credentials
aws configure
# Or use environment variables:
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="ap-south-1"

# Initialize Terraform
terraform init

# Select workspace (environment)
terraform workspace select dev || terraform workspace new dev

# Review the plan
terraform plan -var-file=environments/dev.tfvars

# Apply infrastructure
terraform apply -var-file=environments/dev.tfvars
```

## 📦 Infrastructure Components

### 1. VPC Module (`modules/vpc/`)

**Resources:**
- VPC with DNS support
- 3 Public subnets (one per AZ)
- 3 Private subnets (one per AZ)
- Internet Gateway
- 3 NAT Gateways (high availability)
- Route tables and associations
- Elastic IPs for NAT gateways

**Features:**
- Multi-AZ for high availability
- Public subnets tagged for ELB
- Private subnets tagged for internal ELB
- CIDR: 10.0.0.0/16 (customizable)

### 2. EKS Module (`modules/eks/`)

**Resources:**
- EKS Cluster (Kubernetes 1.28)
- Managed node group
- OIDC provider for IRSA
- Cluster IAM role
- Node IAM role

**Configuration:**
- **Nodes:** 3 x t3.medium
- **Scaling:** Min 2, Max 5, Desired 3
- **Location:** Private subnets
- **Access:** Public + Private API endpoints

### 3. IAM Roles Module (`modules/iam-roles/`)

**Service Account Roles (IRSA):**
- **EBS CSI Driver:** Manages EBS volumes
- **ALB Controller:** Creates Application Load Balancers
- **External Secrets:** Reads AWS Secrets Manager

**Trust Relationships:**
- Uses OIDC provider for federated authentication
- Scoped to specific namespaces and service accounts

### 4. Security Groups Module (`modules/security-groups/`)

**Node Security Group:**
- Allows all outbound traffic
- Allows node-to-node communication
- Allows API server communication (port 443)

### 5. Kubernetes Operators Module (`modules/k8s-operators/`)

**Deployed Operators:**
- **MongoDB Community Operator:** Manages MongoDB clusters
- **Cert-Manager:** Manages TLS certificates
- **Nginx Ingress Controller:** Ingress traffic routing

### 6. ArgoCD Module (`modules/argocd/`)

**Components:**
- ArgoCD Helm chart deployment
- ClusterSecretStore for AWS Secrets Manager
- External Secret for GitOps repository credentials
- Root App of Apps

**Configuration:**
- Insecure mode (HTTP)
- Nginx ingress enabled
- Auto-sync enabled
- Admin password: Configurable via variable

### 7. External Secrets Module (`modules/external-secrets/`)

**Resources:**
- External Secrets Operator Helm chart
- IAM role with SecretsManager permissions
- ClusterSecretStore configuration

### 8. ALB Controller Module (`modules/alb-controller/`)

**Resources:**
- AWS Load Balancer Controller Helm chart
- IAM role with EC2/ELB permissions
- Integrated with VPC

## 🔧 Configuration

### Environment Variables

**environments/dev.tfvars:**
```hcl
# AWS Configuration
aws_region = "ap-south-1"
project_name = "movie-watchlist"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = [
  "ap-south-1a",
  "ap-south-1b", 
  "ap-south-1c"
]

# EKS Configuration
cluster_version = "1.28"
node_instance_type = "t3.medium"
node_desired_size = 3
node_min_size = 2
node_max_size = 5

# ArgoCD Configuration
argocd_admin_password = "admin123"
domain_name = ""
enable_tls = false

# GitOps Configuration
gitops_repo = "jawna10/movie-watchlist-gitops"
github_secret_name = "movie-watchlist/github-credentials"
```

### Backend Configuration

**backend.tf:**
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-jawna"
    key            = "movie-watchlist/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}
```

**Setup Backend:**
```bash
# Create S3 bucket
aws s3 mb s3://terraform-state-jawna --region ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-jawna \
  --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

## 🎯 Deployment Workflow

### 1. Infrastructure Provisioning

```bash
# Initialize and plan
terraform init
terraform workspace select dev
terraform plan -var-file=environments/dev.tfvars

# Apply changes
terraform apply -var-file=environments/dev.tfvars

# Expected duration: 15-20 minutes
```

### 2. Configure kubectl

```bash
# Get kubeconfig
aws eks update-kubeconfig \
  --name movie-watchlist-dev \
  --region ap-south-1

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

### 3. Verify Components

```bash
# Check ArgoCD
kubectl get pods -n argocd

# Check operators
kubectl get pods -n mongodb-operator-system
kubectl get pods -n ingress-nginx
kubectl get pods -n external-secrets

# Get ArgoCD URL
kubectl get ingress -n argocd
```

### 4. Access ArgoCD

```bash
# Get LoadBalancer URL
ARGOCD_URL=$(kubectl get ingress argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ArgoCD URL: http://$ARGOCD_URL"

# Login credentials
# Username: admin
# Password: admin123 (or from tfvars)
```

## 📊 Outputs

After successful apply, Terraform outputs:

```bash
# Cluster information
terraform output cluster_name
terraform output cluster_endpoint
terraform output cluster_region

# Network information
terraform output vpc_id
terraform output private_subnet_ids

# IAM roles
terraform output ebs_csi_role_arn
terraform output alb_controller_role_arn
terraform output external_secrets_role_arn

# kubectl configuration command
terraform output configure_kubectl
```

## 🔄 Updates and Changes

### Update EKS Version

```bash
# Update variable
# Edit environments/dev.tfvars: cluster_version = "1.29"

# Plan and apply
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Update kubeconfig
aws eks update-kubeconfig --name movie-watchlist-dev --region ap-south-1
```

### Scale Node Group

```bash
# Update variables
# Edit environments/dev.tfvars:
# node_desired_size = 5

terraform apply -var-file=environments/dev.tfvars
```

### Add New Module

```bash
# Create module directory
mkdir -p modules/new-module

# Add main.tf, variables.tf, outputs.tf

# Reference in main.tf
module "new_module" {
  source = "./modules/new-module"
  # ... variables
}

# Apply
terraform apply -var-file=environments/dev.tfvars
```

## 🗑️ Destroy Infrastructure

**⚠️ Warning:** This will delete all resources including data!

```bash
# Delete workloads first (via ArgoCD or kubectl)
kubectl delete applications --all -n argocd

# Wait for cleanup
sleep 60

# Destroy Terraform resources
terraform destroy -var-file=environments/dev.tfvars

# Confirm with 'yes'
```

## 🛡️ Security Best Practices

**IAM:**
- ✅ Least privilege IAM roles
- ✅ IRSA for service accounts (no static credentials)
- ✅ Separate roles per service

**Network:**
- ✅ Private subnets for workloads
- ✅ NAT gateways for outbound traffic
- ✅ Security groups with minimal access

**Secrets:**
- ✅ AWS Secrets Manager for sensitive data
- ✅ External Secrets Operator syncs to K8s
- ✅ No hardcoded secrets in code

**Cluster:**
- ✅ Private EKS API endpoint option
- ✅ Encryption at rest (EBS volumes)
- ✅ Pod security standards

## 🐛 Troubleshooting

### EKS Cluster Not Accessible

```bash
# Check cluster status
aws eks describe-cluster --name movie-watchlist-dev --region ap-south-1

# Update kubeconfig
aws eks update-kubeconfig --name movie-watchlist-dev --region ap-south-1

# Check IAM permissions
aws sts get-caller-identity
```

### Node Group Not Scaling

```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name movie-watchlist-dev \
  --nodegroup-name movie-watchlist-dev-node-group \
  --region ap-south-1

# Check node status
kubectl get nodes
kubectl describe nodes
```

### IAM Role Issues

```bash
# Check OIDC provider
aws eks describe-cluster --name movie-watchlist-dev \
  --query "cluster.identity.oidc.issuer" --output text

# Check service account annotations
kubectl get sa -n kube-system ebs-csi-controller-sa -o yaml

# Test IAM role assumption
kubectl exec -n kube-system <ebs-csi-pod> -- \
  aws sts get-caller-identity
```

### ArgoCD Not Deploying

```bash
# Check ArgoCD status
kubectl get pods -n argocd

# Check application status
kubectl get applications -n argocd

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## 📚 Module Documentation

### VPC Module

**Inputs:**
- `project_name` - Project name for tagging
- `environment` - Environment (dev/staging/prod)
- `vpc_cidr` - VPC CIDR block
- `availability_zones` - List of AZs

**Outputs:**
- `vpc_id` - VPC identifier
- `public_subnet_ids` - Public subnet IDs
- `private_subnet_ids` - Private subnet IDs

### EKS Module

**Inputs:**
- `cluster_name` - EKS cluster name
- `cluster_version` - Kubernetes version
- `vpc_id` - VPC to deploy into
- `private_subnet_ids` - Subnets for nodes
- `node_instance_type` - EC2 instance type
- `node_desired_size` - Desired node count

**Outputs:**
- `cluster_endpoint` - API server endpoint
- `cluster_certificate_authority_data` - CA certificate
- `oidc_provider_arn` - OIDC provider ARN

### IAM Roles Module

**Inputs:**
- `cluster_name` - EKS cluster name
- `oidc_provider_arn` - OIDC provider ARN
- `oidc_issuer_url` - OIDC issuer URL

**Outputs:**
- `ebs_csi_role_arn` - EBS CSI IAM role
- `alb_controller_role_arn` - ALB controller IAM role
- `external_secrets_role_arn` - External Secrets IAM role

## 🔗 Related Repositories

- **Application:** [movie-watchlist-app](https://github.com/jawna10/movie-watchlist-app)
- **GitOps:** [movie-watchlist-gitops](https://github.com/jawna10/movie-watchlist-gitops)

## 📝 Cost Estimation

**Monthly AWS Costs (us-east-1):**
- EKS Cluster: $73
- EC2 (3 x t3.medium): ~$75
- NAT Gateways (3): ~$100
- EBS Volumes: ~$20
- Load Balancers: ~$25
- Data Transfer: ~$10

**Total: ~$300/month**

*Note: Actual costs may vary by region and usage*

## 👤 Author

**Jawna Khatib**
- Email: jawnakhatib@gmail.com
- GitHub: [@jawna10](https://github.com/jawna10)

## 📄 License

This project is part of a portfolio demonstration.
