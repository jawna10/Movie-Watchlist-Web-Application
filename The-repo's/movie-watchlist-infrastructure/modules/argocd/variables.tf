variable "gitops_repo" {
  description = "GitOps repository (org/repo format)"
  type        = string
}

variable "github_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub credentials"
  type        = string
}

variable "admin_password" {
  description = "ArgoCD admin password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Base domain name for ingress"
  type        = string
}

variable "enable_tls" {
  description = "Enable TLS for ArgoCD ingress"
  type        = bool
}

variable "aws_region" {
  description = "AWS region for External Secrets"
  type        = string
}

variable "require_domain" {
  description = "Whether ingress requires a domain or accepts any host"
  type        = bool
  default     = false
}