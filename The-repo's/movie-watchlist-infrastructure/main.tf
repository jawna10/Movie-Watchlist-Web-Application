locals {
  cluster_name = "${var.project_name}-${terraform.workspace}"
  common_tags = {
    Project     = var.project_name
    Environment = terraform.workspace
  }
}

# ========================================
# FETCH SECRETS FROM AWS SECRETS MANAGER
# ========================================
data "aws_secretsmanager_secret_version" "argocd_admin" {
  secret_id = "movie-watchlist/argocd-admin"
}

data "aws_secretsmanager_secret_version" "admin_config" {
  secret_id = "movie-watchlist/admin-config"
}

locals {
  argocd_secrets = jsondecode(data.aws_secretsmanager_secret_version.argocd_admin.secret_string)
  admin_config   = jsondecode(data.aws_secretsmanager_secret_version.admin_config.secret_string)
}

# ========================================
# NETWORKING
# ========================================
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = terraform.workspace
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  
  tags = local.common_tags
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = terraform.workspace
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  
  tags = local.common_tags
}

# ========================================
# EKS CLUSTER
# ========================================
module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = terraform.workspace
  cluster_name           = local.cluster_name
  cluster_version        = var.cluster_version
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr               = var.vpc_cidr
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_security_group_id = module.security_groups.node_security_group_id
  
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  
  tags = local.common_tags
  
  depends_on = [module.vpc, module.security_groups]
}

# ========================================
# IAM ROLES
# ========================================
module "iam_roles" {
  source = "./modules/iam-roles"

  cluster_name        = local.cluster_name
  oidc_provider_arn   = module.eks.oidc_provider_arn
  oidc_issuer_url     = module.eks.cluster_oidc_issuer_url
  
  tags = local.common_tags
  
  depends_on = [module.eks]
}

# ========================================
# KUBERNETES OPERATORS & CONTROLLERS
# ========================================
module "external_secrets" {
  source = "./modules/external-secrets"
  
  cluster_name              = local.cluster_name
  external_secrets_role_arn = module.iam_roles.external_secrets_role_arn
  
  depends_on = [module.iam_roles]
}

module "k8s_operators" {
  source = "./modules/k8s-operators"
  
  cluster_name      = local.cluster_name
  ebs_csi_role_arn  = module.iam_roles.ebs_csi_role_arn
  admin_email       = local.admin_config.email
  
  tags = local.common_tags
  
  depends_on = [
    module.eks,
    module.iam_roles,
    module.external_secrets
  ]
}

module "argocd" {
  source = "./modules/argocd"
   aws_region = var.aws_region
  
  gitops_repo         = var.gitops_repo
  github_secret_name  = var.github_secret_name
  admin_password      = local.argocd_secrets.password
  domain_name         = local.admin_config.domain
  enable_tls          = false
  require_domain      = false
  
  depends_on = [
    module.k8s_operators,
    module.external_secrets
  ]
}

# ========================================
# POST-DEPLOYMENT CONFIGURATION
# ========================================
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
  }
  
  depends_on = [module.eks]
}

resource "null_resource" "wait_for_argocd" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "======================================"
      echo "Waiting for ArgoCD to sync applications..."
      echo "======================================"
      sleep 90
      
      echo ""
      echo "Checking ArgoCD application status..."
      kubectl get applications -n argocd
      
      echo ""
      echo "Checking movie-watchlist deployment..."
      kubectl get pods -n movie-watchlist
      
      echo ""
      echo "======================================"
      echo "Deployment Complete!"
      echo "======================================"
      echo ""
      echo "Next steps:"
      echo "1. Update DNS records (see outputs)"
      echo "2. Wait for Let's Encrypt certificates (5-10 min)"
      echo "3. Access your application!"
      echo ""
    EOT
  }
  
  depends_on = [module.argocd]
}
