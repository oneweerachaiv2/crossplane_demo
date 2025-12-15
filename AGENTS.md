# Learning Crossplane

## Reference
- https://github.com/crossplane/crossplane
- https://github.com/crossplane/crossplane/tree/master/docs
- https://github.com/crossplane/crossplane/tree/master/docs/concepts
- https://github.com/crossplane/crossplane/tree/master/docs/concepts/agents
- https://github.com/crossplane/crossplane/tree/master/docs/concepts/claims

## Access VM
```bash
ssh -i eapi-gateway-api-poc_key.pem azureuser@172.188.120.75
```
# Subscription ID
3c6373fe-834d-4f88-bb56-539b8e02bd96

## Quick Start Guide

### 1. Install Crossplane on your K8s cluster
```bash
chmod +x install-crossplane.sh
./install-crossplane.sh
```

### 2. Install Azure Providers
```bash
kubectl apply -f providers/azure-provider.yaml
# Wait for providers to be healthy
kubectl get providers -w
```

### 3. Configure Azure Credentials
```bash
# Create service principal
az ad sp create-for-rbac --sdk-auth --role Contributor \
  --scopes /subscriptions/3c6373fe-834d-4f88-bb56-539b8e02bd96 > azure-creds.json

# Create K8s secret
kubectl create secret generic azure-creds \
  -n crossplane-system \
  --from-file=creds=./azure-creds.json

# Apply provider config
kubectl apply -f providers/azure-provider-config.yaml
```

### 4. Create Compositions (Platform Team)
```bash
kubectl apply -f compositions/storage-xrd.yaml
kubectl apply -f compositions/storage-composition.yaml
```

### 5. Create Claims (Application Teams)
```bash
kubectl apply -f claims/storage-claim.yaml
# Check status
kubectl get storage
kubectl get xstorages
```

### 6. Deploy Applications with Kubernetes Provider
```bash
# Install Kubernetes Provider
kubectl apply -f - << 'EOF'
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/upbound/provider-kubernetes:v0.11.0
EOF

# Wait for provider to be healthy
kubectl get providers -w

# Configure ProviderConfig
kubectl apply -f providers/kubernetes-provider-config.yaml

# Configure RBAC for provider
kubectl apply -f - << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: provider-kubernetes-admin
rules:
  - apiGroups: ['*']
    resources: ['*']
    verbs: ['*']
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: provider-kubernetes-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: provider-kubernetes-admin
subjects:
  - kind: ServiceAccount
    name: provider-kubernetes-0b6a1dd69062
    namespace: crossplane-system
EOF

# Deploy applications
kubectl apply -f examples/nginx-app.yaml
kubectl apply -f examples/httpbin-app.yaml
kubectl apply -f examples/redis-app.yaml

# Check status
kubectl get objects
kubectl get deployments
kubectl get services
```

## Project Structure
```
├── providers/           # Cloud provider configurations
│   ├── azure-provider.yaml
│   ├── azure-provider-config.yaml
│   └── kubernetes-provider-config.yaml
├── compositions/        # XRDs and Compositions
│   ├── storage-xrd.yaml
│   ├── storage-composition.yaml
│   ├── app-xrd.yaml
│   └── app-composition.yaml
├── claims/              # User-facing Claims
│   ├── storage-claim.yaml
│   ├── webapp-nginx.yaml
│   └── webapp-httpbin.yaml
├── examples/            # Learning examples
│   ├── nginx-app.yaml
│   ├── httpbin-app.yaml
│   ├── redis-app.yaml
│   ├── kubernetes-app-deployment.md
│   └── QUICKSTART-APPS.md
└── install-crossplane.sh
```

## Kubernetes Application Deployment

### Overview
Deploy applications (Deployments, Services, ConfigMaps, etc.) to Kubernetes clusters using Crossplane's Kubernetes Provider.

### Key Features
- **Declarative**: Define applications as Kubernetes manifests
- **Managed**: Crossplane tracks and syncs resources
- **Multi-cluster**: Deploy to multiple clusters from one control plane
- **GitOps Ready**: Version control and CI/CD integration

### Example: Deploy Nginx
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: nginx-deployment
spec:
  forProvider:
    manifest:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: nginx-app
        namespace: default
      spec:
        replicas: 2
        selector:
          matchLabels:
            app: nginx-app
        template:
          metadata:
            labels:
              app: nginx-app
          spec:
            containers:
              - name: nginx
                image: nginx:latest
                ports:
                  - containerPort: 80
  providerConfigRef:
    name: default
```

### Useful Commands
```bash
# List all Crossplane objects
kubectl get objects

# Describe a specific object
kubectl describe object nginx-deployment

# Check object status
kubectl get object nginx-deployment -o yaml

# Watch object status
kubectl get objects -w

# Delete an object
kubectl delete object nginx-deployment
```

### Current Status
✅ **Kubernetes Provider**: v0.11.0 (Healthy)
✅ **ProviderConfig**: Configured with InjectedIdentity
✅ **RBAC**: Configured for provider service account
✅ **Applications Deployed**:
  - Nginx (2 replicas, ClusterIP:80)
  - HTTPBin (1 replica, ClusterIP:8080)
  - Redis (1 replica, ClusterIP:6379)