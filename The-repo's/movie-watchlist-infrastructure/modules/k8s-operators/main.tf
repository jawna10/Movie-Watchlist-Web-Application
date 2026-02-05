# modules/k8s-operators/main.tf
# Replaces all bash installation scripts

# ========================================
# 1. EBS CSI Driver Addon
# ========================================
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.25.0-eksbuild.1"
  service_account_role_arn = var.ebs_csi_role_arn
  
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  
  tags = var.tags
}

# ========================================
# 2. MongoDB Community Operator
# ========================================
resource "helm_release" "mongodb_operator" {
  name       = "mongodb-kubernetes-operator"
  namespace  = "mongodb-operator-system"
  create_namespace = true
  
  repository = "https://mongodb.github.io/helm-charts"
  chart      = "community-operator"
  version    = "0.9.0"
  
  set {
    name  = "operator.watchNamespace"
    value = "*"
  }
  
  # Fixed: Make limits match or exceed requests
  set {
    name  = "operator.resources.requests.cpu"
    value = "100m"
  }
  
  set {
    name  = "operator.resources.limits.cpu"
    value = "200m"
  }
  
  set {
    name  = "operator.resources.requests.memory"
    value = "128Mi"
  }
  
  set {
    name  = "operator.resources.limits.memory"
    value = "256Mi"
  }
  
  depends_on = [aws_eks_addon.ebs_csi]
}

# ========================================
# 3. NGINX Ingress Controller
# ========================================
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true
  
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  
  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
        # Disable ServiceMonitor since Prometheus isn't installed yet (it's in GitOps)
        metrics = {
          enabled = false 
        }
      }
    })
  ]
  
  depends_on = [aws_eks_addon.ebs_csi]
}

# ========================================
# 4. Cert-Manager
# ========================================
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.3"
  
  set {
    name  = "installCRDs"
    value = "true"
  }
  
  values = [
    yamlencode({
      resources = {
        requests = {
          cpu    = "10m"
          memory = "32Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    })
  ]
  
  depends_on = [helm_release.nginx_ingress]
}

# ========================================
# 5. ClusterIssuers for Let's Encrypt
# ========================================
resource "kubectl_manifest" "letsencrypt_staging" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.admin_email
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })
  
  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_prod" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.admin_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })
  
  depends_on = [helm_release.cert_manager]
}

# ========================================
# Prometheus Operator CRDs (Dynamic)
# ========================================
locals {
  prometheus_operator_version = "v0.68.0"
  
  crd_urls = [
    "monitoring.coreos.com_servicemonitors",
    "monitoring.coreos.com_prometheuses",
    "monitoring.coreos.com_prometheusrules",
    "monitoring.coreos.com_alertmanagers",
    "monitoring.coreos.com_podmonitors",
    "monitoring.coreos.com_alertmanagerconfigs",
    "monitoring.coreos.com_probes",
    "monitoring.coreos.com_thanosrulers"
  ]
}

data "http" "prometheus_crds" {
  for_each = toset(local.crd_urls)
  
  url = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${local.prometheus_operator_version}/example/prometheus-operator-crd/${each.key}.yaml"
}

resource "kubectl_manifest" "prometheus_crds" {
  for_each = data.http.prometheus_crds
  
  yaml_body         = each.value.response_body
  server_side_apply = true
  wait              = true
  
  depends_on = [
    helm_release.mongodb_operator,
    helm_release.cert_manager
  ]
}
