output "helm_release_name" {
  description = "Helm release name"
  value       = helm_release.external_secrets.name
}

output "helm_release_namespace" {
  description = "Helm release namespace"
  value       = helm_release.external_secrets.namespace
}