# Helm Charts for Movie Watchlist

This directory contains Helm charts for deploying the Movie Watchlist application to Kubernetes.

## Structure

```
helm/
├── movie-watchlist/           # Application chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── movie-watchlist-stack/     # Umbrella chart (App + MongoDB via Community Operator)
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        └── mongodb.yaml       # MongoDB Community resource
```

## Prerequisites

1. **Kubernetes cluster** (EKS, Minikube, etc.)
2. **kubectl** configured
3. **Helm 3** installed
4. **AWS Load Balancer Controller** (for ALB Ingress)
5. **MongoDB Community Kubernetes Operator** installed

## Quick Start

### 1. Install MongoDB Community Operator

```bash
# Install the operator (one-time setup)
./k8s/mongodb-operator/install.sh

# Verify installation
kubectl get pods -n mongodb-operator-system
```

### 2. Deploy the Stack

```bash
# Create namespace
kubectl create namespace movie-watchlist

# Install the complete stack
helm install movie-watchlist ./helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set movie-watchlist.image.tag=latest \
  --timeout 10m
```

### 3. Check Deployment

```bash
# Check MongoDB
kubectl get mongodbcommunity -n movie-watchlist

# Check pods
kubectl get pods -n movie-watchlist

# Check services
kubectl get svc -n movie-watchlist

# Check ingress
kubectl get ingress -n movie-watchlist

# Get ALB URL
kubectl get ingress -n movie-watchlist -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

## MongoDB Community Operator

The stack uses the **MongoDB Community Kubernetes Operator** instead of Bitnami charts.

### Features:
- **Native Kubernetes integration** via CRDs
- **Automatic replica set setup**
- **Built-in backup support**
- **Security best practices**
- **Official MongoDB support**

### Created Resources:
- `MongoDBCommunity` custom resource
- StatefulSet for MongoDB pods
- Service (`mongodb-svc`)
- PersistentVolumeClaim (8Gi GP3)
- Secrets for authentication

## Configuration

### Update Image Tag

```bash
helm upgrade movie-watchlist ./helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set movie-watchlist.image.tag=abc1234
```

### Enable MongoDB Authentication

Edit `values.yaml`:

```yaml
mongodb:
  auth:
    enabled: true
    rootPassword: "your-root-password"
    username: "movieapp"
    password: "your-app-password"
    database: "movie_watchlist"

movie-watchlist:
  mongodb:
    auth:
      enabled: true
```

### Scale Application

```bash
# Manual scaling
helm upgrade movie-watchlist ./helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set movie-watchlist.replicaCount=3

# Enable autoscaling
helm upgrade movie-watchlist ./helm/movie-watchlist-stack \
  --namespace movie-watchlist \
  --set movie-watchlist.autoscaling.enabled=true \
  --set movie-watchlist.autoscaling.minReplicas=2 \
  --set movie-watchlist.autoscaling.maxReplicas=5
```

## Uninstall

```bash
helm uninstall movie-watchlist --namespace movie-watchlist
kubectl delete namespace movie-watchlist
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n movie-watchlist
kubectl logs <pod-name> -n movie-watchlist
```

### MongoDB connection issues

```bash
# Check MongoDB pod
kubectl get pod -n movie-watchlist -l app.kubernetes.io/name=mongodb

# Check MongoDB logs
kubectl logs <mongodb-pod-name> -n movie-watchlist

# Test connection from app pod
kubectl exec -it <app-pod-name> -n movie-watchlist -- \
  curl http://movie-watchlist-stack-mongodb:27017
```

### ALB not created

```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check ingress events
kubectl describe ingress movie-watchlist -n movie-watchlist
```

## Production Checklist

- [ ] Enable MongoDB authentication
- [ ] Use specific image tags (not `latest`)
- [ ] Configure resource limits
- [ ] Set up persistent volumes
- [ ] Enable TLS/HTTPS
- [ ] Configure network policies
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Use secrets for sensitive data
- [ ] Enable pod disruption budgets

## Secret Management

This project uses External Secrets Operator to sync secrets from AWS Secrets Manager:

- MongoDB credentials: `movie-watchlist/mongodb-credentials`
- Admin configuration: `movie-watchlist/admin-config`
- GitHub credentials: `movie-watchlist/github-credentials`

No secrets are stored in Git. All sensitive data is managed through AWS Secrets Manager and synchronized to Kubernetes secrets via External Secrets Operator.

### Adding New Secrets
1. Create secret in AWS Secrets Manager
2. Add ExternalSecret manifest
3. Reference in deployment