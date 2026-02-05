output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "get_nginx_lb" {
  description = "Command to get NGINX LoadBalancer hostname"
  value       = "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "application_urls" {
  description = "Application URLs (after DNS configuration)"
  value = {
    app        = "${var.enable_tls ? "https" : "http"}://movie-watchlist.${var.domain_name}"
    argocd     = "${var.enable_tls ? "https" : "http"}://argocd.${var.domain_name}"
    grafana    = "${var.enable_tls ? "https" : "http"}://grafana.${var.domain_name}"
    prometheus = "${var.enable_tls ? "https" : "http"}://prometheus.${var.domain_name}"
  }
}

output "argocd_credentials" {
  description = "ArgoCD credentials"
  value = {
    username = "admin"
    password = var.argocd_password
  }
  sensitive = true
}

output "deployment_status" {
  description = "Deployment instructions"
  value = <<-EOT
    ====================================
    🚀 Deployment Complete!
    ====================================
    
    1. Configure kubectl:
       ${module.eks.cluster_name != "" ? "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}" : "Run terraform output configure_kubectl"}
    
    2. Get NGINX LoadBalancer hostname:
       kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    3. Point your DNS records to the LoadBalancer hostname:
       movie-watchlist.${var.domain_name} → NLB hostname
       argocd.${var.domain_name}          → NLB hostname
       grafana.${var.domain_name}         → NLB hostname
       prometheus.${var.domain_name}      → NLB hostname
    
    4. Check ArgoCD sync status:
       kubectl get applications -n argocd
    
    5. Get ArgoCD password:
       terraform output -json argocd_credentials | jq -r '.password'
    
    ====================================
  EOT
}
