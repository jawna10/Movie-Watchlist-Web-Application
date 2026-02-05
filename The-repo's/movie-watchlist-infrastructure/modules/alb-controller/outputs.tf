output "helm_release_name" {
  description = "Helm release name"
  value       = helm_release.alb_controller.name
}

output "helm_release_namespace" {
  description = "Helm release namespace"
  value       = helm_release.alb_controller.namespace
}