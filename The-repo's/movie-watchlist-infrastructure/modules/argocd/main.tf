# modules/argocd/main.tf
# Replaces k8s/argocd/install.sh

# ========================================
# 1. ArgoCD Helm Installation
# ========================================
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  create_namespace = true
  
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  
  values = [
    yamlencode({
      server = {
        extraArgs = ["--insecure"]
        ingress = {
          enabled = true
          ingressClassName = "nginx"
          hosts = var.require_domain ? ["argocd.${var.domain_name}"] : []
          tls = var.enable_tls && var.require_domain ? [{
            secretName = "argocd-tls"
            hosts      = ["argocd.${var.domain_name}"]
          }] : []
          annotations = var.enable_tls && var.require_domain ? {
            "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
          } : {
            "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
          }
        }
      }
      configs = {
        params = {
          "server.insecure" = "true"
        }
        secret = {
          argocdServerAdminPassword = bcrypt(var.admin_password)
        }
      }
    })
  ]
}

# ========================================
# 2. External Secrets for GitOps Repo
# ========================================
resource "kubectl_manifest" "gitops_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "gitops-repo"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secrets"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "gitops-repo"
        creationPolicy = "Owner"
        template = {
          type = "Opaque"
          metadata = {
            labels = {
              "argocd.argoproj.io/secret-type" = "repository"
            }
          }
          data = {
            type     = "git"
            url      = "https://github.com/${var.gitops_repo}.git"
            username = "{{ .username }}"
            password = "{{ .token }}"
          }
        }
      }
      data = [{
        secretKey = "username"
        remoteRef = {
          key      = var.github_secret_name
          property = "username"
        }
      }, {
        secretKey = "token"
        remoteRef = {
          key      = var.github_secret_name
          property = "token"
        }
      }]
    }
  })
  
  depends_on = [helm_release.argocd]
}

# ========================================
# 3. Root App of Apps
# ========================================
resource "kubectl_manifest" "root_app" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-app"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/${var.gitops_repo}.git"
        targetRevision = "main"
        path           = "."
        directory = {
          recurse = true
          include = "{applications/*.yaml,infrastructure/*.yaml}"
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  })
  
  depends_on = [
    helm_release.argocd,
    kubectl_manifest.gitops_external_secret
  ]
}

# Wait for root app to be healthy
resource "null_resource" "wait_for_argocd" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for ArgoCD to sync applications..."
      sleep 60
    EOT
  }
  
  depends_on = [kubectl_manifest.root_app]
}
# ========================================
# 0. ClusterSecretStore for AWS Secrets Manager
# ========================================
resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  })
  
  depends_on = [helm_release.argocd]
}
