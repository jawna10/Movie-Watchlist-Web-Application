# Helm Commands Cheat Sheet

## Setup

```bash
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Update dependencies
cd helm/movie-watchlist-stack
helm dependency update
helm dependency build
```

## Install

```bash
# Create namespace
kubectl create namespace movie-watchlist

# Install with default values
helm install movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist

# Install with custom image tag
helm install movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set movie-watchlist.image.tag=abc1234

# Dry run (test without installing)
helm install movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --dry-run --debug
```

## Upgrade

```bash
# Update image tag
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set movie-watchlist.image.tag=def5678

# Upgrade with values file
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --values custom-values.yaml

# Force recreation of pods
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --recreate-pods
```

## Status & Info

```bash
# List releases
helm list --namespace movie-watchlist

# Get release status
helm status movie-watchlist --namespace movie-watchlist

# Get values
helm get values movie-watchlist --namespace movie-watchlist

# Get all values (including defaults)
helm get values movie-watchlist --namespace movie-watchlist --all

# Get manifest
helm get manifest movie-watchlist --namespace movie-watchlist
```

## Rollback

```bash
# View history
helm history movie-watchlist --namespace movie-watchlist

# Rollback to previous version
helm rollback movie-watchlist --namespace movie-watchlist

# Rollback to specific revision
helm rollback movie-watchlist 2 --namespace movie-watchlist
```

## Uninstall

```bash
# Uninstall release
helm uninstall movie-watchlist --namespace movie-watchlist

# Uninstall and delete namespace
helm uninstall movie-watchlist --namespace movie-watchlist
kubectl delete namespace movie-watchlist
```

## Testing & Validation

```bash
# Lint chart
helm lint helm/movie-watchlist
helm lint helm/movie-watchlist-stack

# Template (render locally)
helm template movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist

# Test release
helm test movie-watchlist --namespace movie-watchlist
```

## Package & Push (for ArgoCD later)

```bash
# Package chart
helm package helm/movie-watchlist-stack

# Push to chart museum (if using)
helm push movie-watchlist-stack-0.1.0.tgz chartmuseum
```

## Common Scenarios

### Update Only Image Tag

```bash
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --reuse-values \
  --set movie-watchlist.image.tag=new-tag
```

### Scale Replicas

```bash
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --reuse-values \
  --set movie-watchlist.replicaCount=3
```

### Enable Autoscaling

```bash
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --reuse-values \
  --set movie-watchlist.autoscaling.enabled=true
```

### Disable MongoDB (use external)

```bash
helm upgrade movie-watchlist helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set mongodb.enabled=false \
  --set movie-watchlist.mongodb.host=external-mongo.example.com
```