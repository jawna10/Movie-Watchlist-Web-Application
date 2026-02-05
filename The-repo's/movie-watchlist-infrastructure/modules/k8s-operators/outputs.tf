output "nginx_ingress_lb_hostname" {
  description = "NGINX Ingress LoadBalancer hostname (available after deployment)"
  value       = "Check with: kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "mongodb_operator_namespace" {
  description = "MongoDB operator namespace"
  value       = helm_release.mongodb_operator.namespace
}

output "cert_manager_namespace" {
  description = "Cert-manager namespace"
  value       = helm_release.cert_manager.namespace
}

output "nginx_ingress_installed" {
  description = "NGINX Ingress installation status"
  value       = helm_release.nginx_ingress.status
}
