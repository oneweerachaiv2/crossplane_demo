# Quick Start: Deploy Applications with Crossplane

## Prerequisites

1. Crossplane installed on your cluster
2. Kubernetes Provider installed: `provider-kubernetes:v0.11.0`
3. ProviderConfig configured (see `providers/kubernetes-provider-config.yaml`)
4. RBAC permissions configured (see setup below)

## Setup (One-time)

### 1. Create Kubernetes Provider
```bash
kubectl apply -f providers/kubernetes-provider.yaml
```

### 2. Create ProviderConfig
```bash
kubectl apply -f providers/kubernetes-provider-config.yaml
```

### 3. Configure RBAC
```bash
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
```

## Deploy Applications

### Deploy Nginx
```bash
kubectl apply -f examples/nginx-app.yaml
```

### Deploy HTTPBin
```bash
kubectl apply -f examples/httpbin-app.yaml
```

### Deploy Redis
```bash
kubectl apply -f examples/redis-app.yaml
```

## Monitor Deployment

### Check Crossplane Objects
```bash
kubectl get objects
```

Expected output:
```
NAME                 KIND         PROVIDERCONFIG   SYNCED   READY   AGE
nginx-deployment     Deployment   default          True     True    2m
nginx-service        Service      default          True     True    2m
httpbin-deployment   Deployment   default          True     True    1m
httpbin-service      Service      default          True     True    1m
redis-deployment     Deployment   default          True     True    30s
redis-service        Service      default          True     True    30s
```

### Check Kubernetes Resources
```bash
# Check deployments
kubectl get deployments

# Check services
kubectl get services

# Check pods
kubectl get pods
```

## Verify Applications

### Check Nginx
```bash
kubectl get service nginx-app
# Should show ClusterIP and port 80
```

### Check HTTPBin
```bash
kubectl get service httpbin-app
# Should show ClusterIP and port 8080
```

### Check Redis
```bash
kubectl get service redis-app
# Should show ClusterIP and port 6379
```

## Create Custom Applications

Create a new file `my-app.yaml`:

```yaml
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: my-app-deployment
spec:
  forProvider:
    manifest:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: my-app
        namespace: default
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: my-app
        template:
          metadata:
            labels:
              app: my-app
          spec:
            containers:
              - name: app
                image: my-image:latest
                ports:
                  - containerPort: 8080
  providerConfigRef:
    name: default
---
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: my-app-service
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Service
      metadata:
        name: my-app
        namespace: default
      spec:
        type: ClusterIP
        selector:
          app: my-app
        ports:
          - port: 8080
            targetPort: 8080
  providerConfigRef:
    name: default
```

Then deploy:
```bash
kubectl apply -f my-app.yaml
```

## Cleanup

Delete all applications:
```bash
kubectl delete objects --all
```

Or delete specific applications:
```bash
kubectl delete object nginx-deployment nginx-service
```

