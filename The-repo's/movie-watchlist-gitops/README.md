# Movie Watchlist GitOps Repository

GitOps configuration repository for deploying the Movie Watchlist application using ArgoCD with the App of Apps pattern.

## 🎯 Overview

This repository serves as the **single source of truth** for all Kubernetes deployments. ArgoCD continuously monitors this repository and automatically syncs the desired state to the cluster.

## 📁 Repository Structure

```
movie-watchlist-gitops/
├── apps/
│   └── root.yaml                  # Root App of Apps (managed by Terraform)
├── applications/                   # Application definitions
│   └── movie-watchlist.yaml       # Main application
├── infrastructure/                 # Infrastructure applications
│   ├── monitoring.yaml            # Prometheus + Grafana stack
│   ├── nginx-ingress.yaml         # Nginx Ingress Controller
│   ├── cert-manager.yaml          # Certificate management
│   └── cluster-issuers.yaml       # Let's Encrypt issuers
├── helm/                           # Helm charts
│   └── movie-watchlist/           # Application Helm chart
│       ├── Chart.yaml             # Chart metadata
│       ├── values.yaml            # Default values
│       └── templates/             # Kubernetes manifests
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── configmap.yaml
│           ├── mongodb.yaml
│           ├── mongodb-secret.yaml
│           ├── rbac.yaml
│           └── servicemonitor.yaml
└── environments/                   # Environment-specific values
    ├── dev/
    │   └── values.yaml            # Dev overrides (Jenkins updates this)
```

## 🔄 How It Works

### App of Apps Pattern

```
root-app (ArgoCD Application)
  │
  ├─→ applications/ (watches this directory)
  │    └─→ movie-watchlist
  │         ├─ Helm Chart: helm/movie-watchlist/
  │         └─ Values: environments/dev/values.yaml
  │
  └─→ infrastructure/ (watches this directory)
       ├─→ monitoring (Prometheus + Grafana)
       ├─→ nginx-ingress
       └─→ cert-manager
```

### Deployment Flow

```
1. Developer pushes code → App Repository
2. Jenkins builds image → ECR
3. Jenkins updates image tag → environments/dev/values.yaml
4. Jenkins commits & pushes → This Repository
5. ArgoCD detects change (polling every 3 min)
6. ArgoCD syncs Helm chart with new values
7. Kubernetes pulls new image & updates pods
```

## 🚀 Quick Start

### Prerequisites

- EKS cluster with ArgoCD installed (via Terraform)
- kubectl configured for cluster access
- GitHub Personal Access Token (for private repos)

### Bootstrap ArgoCD

**Note:** The root-app is automatically deployed by Terraform's ArgoCD module.

To manually verify or redeploy:

```bash
# Clone this repository
git clone https://github.com/jawna10/movie-watchlist-gitops.git
cd movie-watchlist-gitops

# Check root-app status
kubectl get application root-app -n argocd

# Manually apply root-app (if needed)
kubectl apply -f apps/root.yaml

# Watch applications deploy
kubectl get applications -n argocd -w
```

### Verify Deployment

```bash
# Check all ArgoCD applications
kubectl get applications -n argocd

# Check application pods
kubectl get pods -n movie-watchlist
kubectl get pods -n monitoring

# Get application URLs
kubectl get ingress -n movie-watchlist
kubectl get ingress -n argocd
```

## 📦 Applications

### 1. Movie Watchlist (`applications/movie-watchlist.yaml`)

**Purpose:** Main application deployment

**Configuration:**
```yaml
source:
  repoURL: https://github.com/jawna10/movie-watchlist-gitops.git
  path: helm/movie-watchlist
  helm:
    valueFiles:
      - ../../environments/dev/values.yaml
```

**Components:**
- Flask application (2 replicas)
- MongoDB StatefulSet
- Nginx ingress
- ServiceMonitor for Prometheus
- ConfigMap & Secrets

**Sync Policy:**
- Auto-sync: Enabled
- Self-heal: Enabled
- Prune: Enabled

### 2. Monitoring (`infrastructure/monitoring.yaml`)

**Purpose:** Prometheus + Grafana stack for observability

**Components:**
- Prometheus Operator
- Prometheus Server (10GB persistent storage)
- Grafana (5GB persistent storage)
- Alertmanager (2GB persistent storage)
- Node Exporter (DaemonSet)
- Kube-state-metrics

**Access Grafana:**
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 --address=0.0.0.0
# Open: http://<EC2-IP>:3000
# Login: admin / admin123
```

### 3. Nginx Ingress (`infrastructure/nginx-ingress.yaml`)

**Purpose:** Ingress traffic routing

**Configuration:**
- AWS NLB (Network Load Balancer)
- Internet-facing
- Metrics enabled for Prometheus

**LoadBalancer:**
```bash
kubectl get svc -n ingress-nginx | grep LoadBalancer
```

### 4. Cert-Manager (`infrastructure/cert-manager.yaml`)

**Purpose:** TLS certificate management

**Components:**
- Cert-manager operator
- ClusterIssuers (staging & production)

**Issuers:**
- `letsencrypt-staging` - For testing
- `letsencrypt-prod` - For production

## 🎨 Helm Chart

### Chart Structure

**helm/movie-watchlist/Chart.yaml:**
```yaml
apiVersion: v2
name: movie-watchlist
description: Movie tracking application
type: application
version: 0.1.0
appVersion: "1.0.0"
```

### Default Values

**helm/movie-watchlist/values.yaml:**
```yaml
replicaCount: 2

image:
  repository: 435073375959.dkr.ecr.ap-south-1.amazonaws.com/movie-watchlist
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 5000

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: movie-watchlist.ddns.net
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

mongodb:
  host: mongodb-svc
  port: 27017
  database: movie_watchlist
```

### Environment Overrides

**environments/dev/values.yaml:**
```yaml
replicaCount: 2

image:
  repository: 435073375959.dkr.ecr.ap-south-1.amazonaws.com/movie-watchlist
  tag: "44cda05"  # ← Jenkins updates this
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

app:
  env: development

autoscaling:
  enabled: false
```

## 🔄 Update Process

### Automated Updates (Jenkins)

**Jenkins Pipeline automatically:**
1. Builds new Docker image
2. Pushes to ECR with commit hash tag
3. Updates `environments/dev/values.yaml`
4. Commits with message: `"Update image to <TAG> [skip ci]"`
5. Pushes to this repository

**Example commit:**
```bash
commit b2193ec
Author: Jenkins CI <jenkins@ci.local>
Date:   Mon Oct 14 12:00:00 2025

    Update image to 44cda05 [skip ci]
    
    diff --git a/environments/dev/values.yaml b/environments/dev/values.yaml
    -  tag: "abc1234"
    +  tag: "44cda05"
```

**ArgoCD detects change within 3 minutes and auto-syncs.**

### Manual Updates

**Update Image Tag:**
```bash
cd movie-watchlist-gitops

# Edit values file
vim environments/dev/values.yaml
# Change: tag: "old-tag" → tag: "new-tag"

# Commit and push
git add environments/dev/values.yaml
git commit -m "chore: update image to new-tag"
git push origin main

# ArgoCD auto-syncs within 3 minutes
# Or manually sync:
kubectl patch application movie-watchlist -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

**Update Application Config:**
```bash
# Edit Helm chart values
vim helm/movie-watchlist/values.yaml

# Commit and push
git add helm/movie-watchlist/values.yaml
git commit -m "feat: increase replica count to 3"
git push origin main
```

## 🔍 Troubleshooting

### Application Not Syncing

```bash
# Check application status
kubectl get application movie-watchlist -n argocd

# Describe for errors
kubectl describe application movie-watchlist -n argocd

# Check sync status
kubectl get application movie-watchlist -n argocd -o yaml | grep -A 10 status

# Force hard refresh
kubectl patch application movie-watchlist -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### ArgoCD Not Detecting Changes

```bash
# Check what revision ArgoCD is tracking
kubectl get application movie-watchlist -n argocd -o jsonpath='{.status.sync.revision}'

# Check latest Git commit
cd ~/movie-watchlist-gitops
git rev-parse HEAD

# If different, force refresh
kubectl patch application movie-watchlist -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Repository Connection Issues

```bash
# Check repository secret
kubectl get secret gitops-repo -n argocd

# Check external secret status
kubectl get externalsecret gitops-repo -n argocd
kubectl describe externalsecret gitops-repo -n argocd

# Restart ArgoCD components
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout restart statefulset argocd-application-controller -n argocd
```

### MongoDB Not Starting

```bash
# Check MongoDB status
kubectl get mongodbcommunity -n movie-watchlist
kubectl describe mongodbcommunity mongodb -n movie-watchlist

# Check MongoDB pods
kubectl get pods -n movie-watchlist -l app.kubernetes.io/name=mongodb

# Check service account exists
kubectl get serviceaccount mongodb-database -n movie-watchlist

# Check PVC status
kubectl get pvc -n movie-watchlist
```

### Monitoring OutOfSync

```bash
# Check monitoring app
kubectl get application monitoring -n argocd

# Common issue: Prometheus Operator drift
# Solution: Disable auto-sync or add ignoreDifferences

# Manual sync
kubectl patch application monitoring -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## 📊 Monitoring Integration

### ServiceMonitor

The application exposes metrics at `/metrics` endpoint.

**ServiceMonitor configuration:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: movie-watchlist
  namespace: movie-watchlist
spec:
  selector:
    matchLabels:
      app: movie-watchlist
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

### Prometheus Queries

**Request Rate:**
```promql
rate(flask_http_request_total[5m])
```

**Error Rate:**
```promql
sum(rate(flask_http_request_total{status=~"4..|5.."}[5m])) / 
sum(rate(flask_http_request_total[5m]))
```

**Request Duration:**
```promql
histogram_quantile(0.95, 
  rate(flask_http_request_duration_seconds_bucket[5m])
)
```

## 🔐 Secrets Management

### GitHub Credentials

**Stored in AWS Secrets Manager:**
```json
{
  "username": "jawna10",
  "token": "ghp_xxxxxxxxxxxx"
}
```

**Secret name:** `movie-watchlist/github-credentials`

**Synced to Kubernetes via External Secrets:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: gitops-repo
  namespace: argocd
spec:
  secretStoreRef:
    name: aws-secrets
    kind: ClusterSecretStore
  data:
    - secretKey: username
      remoteRef:
        key: movie-watchlist/github-credentials
        property: username
    - secretKey: token
      remoteRef:
        key: movie-watchlist/github-credentials
        property: token
```

### MongoDB Credentials

**Defined in Helm chart:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: movie-watchlist-mongodb-credentials
stringData:
  username: "admin"
  password: "admin123"
  connection-string: "mongodb://admin:admin123@mongodb-svc:27017/?authSource=admin"
```

## 🚀 Promotion Workflow

### Dev → Staging

```bash
# Get current dev image tag
DEV_TAG=$(yq '.image.tag' environments/dev/values.yaml)

# Update staging
yq -i ".image.tag = \"$DEV_TAG\"" environments/staging/values.yaml

# Commit and push
git add environments/staging/values.yaml
git commit -m "chore: promote $DEV_TAG to staging"
git push origin main
```

### Staging → Production

```bash
# Get current staging image tag
STAGING_TAG=$(yq '.image.tag' environments/staging/values.yaml)

# Update production
yq -i ".image.tag = \"$STAGING_TAG\"" environments/production/values.yaml

# Commit and push
git add environments/production/values.yaml
git commit -m "chore: promote $STAGING_TAG to production"
git push origin main

# Production requires manual approval/sync
```

## 📝 Best Practices

### DO ✅

- **Use semantic versioning** for production releases
- **Test in dev** before promoting to staging/production
- **Keep values minimal** - only override what's necessary
- **Use meaningful commit messages** for audit trail
- **Review ArgoCD diff** before approving sync
- **Monitor after deployment** - check Grafana dashboards

### DON'T ❌

- **Never commit secrets** to this repository
- **Don't use `latest` tag** in production
- **Don't skip environments** - always test in lower env first
- **Don't modify running pods** - always update via Git
- **Don't disable auto-sync** in production without reason

## 🔗 Integration Points

### Jenkins Integration

**Jenkins updates this repo:**
- File: `environments/dev/values.yaml`
- Field: `image.tag`
- Trigger: Successful build on main branch
- Commit: `[skip ci]` to prevent loops

**Required Jenkins credentials:**
- Credential ID: `github-token`
- Type: Username with password
- Username: GitHub username
- Password: Personal Access Token

### ArgoCD Integration

**ArgoCD monitors:**
- Repository: This GitOps repo
- Branch: `main`
- Polling: Every 3 minutes
- Sync: Automatic on change detection

**Root-app configuration:**
```yaml
spec:
  source:
    repoURL: https://github.com/jawna10/movie-watchlist-gitops.git
    targetRevision: main
    path: .
    directory:
      recurse: true
      include: '{applications/*.yaml,infrastructure/*.yaml}'
```

## 📚 Additional Resources

### ArgoCD UI Access

```bash
# Get LoadBalancer URL
kubectl get ingress argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Login: admin / admin123
```

### Useful Commands

```bash
# Watch all applications
watch kubectl get applications -n argocd

# Check application health
kubectl get application movie-watchlist -n argocd -o jsonpath='{.status.health.status}'

# View sync history
kubectl describe application movie-watchlist -n argocd | grep -A 20 "History"

# Force sync all applications
kubectl get applications -n argocd -o name | xargs -I {} kubectl patch {} -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## 🤝 Contributing

### Adding New Application

1. Create Helm chart in `helm/new-app/`
2. Create ArgoCD application in `applications/new-app.yaml`
3. Create environment values in `environments/dev/new-app-values.yaml`
4. Commit and push
5. Root-app auto-deploys it!

### Modifying Existing Application

1. Clone repository
2. Create feature branch
3. Make changes to Helm chart or values
4. Test in dev environment first
5. Create Pull Request
6. Review and merge
7. ArgoCD auto-syncs

## 👤 Author

**Jawna Khatib**
- Email: jawnakhatib@gmail.com
- GitHub: [@jawna10](https://github.com/jawna10)

## 🔗 Related Repositories

- **Application:** [movie-watchlist-app](https://github.com/jawna10/movie-watchlist-app)
- **Infrastructure:** [movie-watchlist-infrastructure](https://github.com/jawna10/movie-watchlist-infrastructure)

## 📄 License

This project is part of a portfolio demonstration.

---

**Questions or Issues?**

Check ArgoCD documentation: https://argo-cd.readthedocs.io/
Or open an issue in this repository.