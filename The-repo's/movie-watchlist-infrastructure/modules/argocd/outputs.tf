output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = helm_release.argocd.namespace
}

output "argocd_server_url" {
  description = "ArgoCD server URL (after DNS configuration)"
  value       = var.enable_tls ? "https://argocd.${var.domain_name}" : "http://argocd.${var.domain_name}"
}

output "argocd_admin_username" {
  description = "ArgoCD admin username"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = var.admin_password
  sensitive   = true
}

output "root_app_created" {
  description = "Root App of Apps creation status"
  value       = "Root application deployed - ArgoCD is syncing from ${var.gitops_repo}"
}