variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

# ========================================
# APPLICATION CONFIGURATION
# ========================================

variable "admin_email" {
  description = "Admin email for Let's Encrypt certificates"
  type        = string
}

variable "domain_name" {
  description = "Base domain name (e.g., ddns.net)"
  type        = string
}

variable "gitops_repo" {
  description = "GitOps repository in org/repo format"
  type        = string
}

variable "github_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub credentials"
  type        = string
}

variable "argocd_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
}

variable "enable_tls" {
  description = "Enable TLS/HTTPS with Let's Encrypt"
  type        = bool
}

