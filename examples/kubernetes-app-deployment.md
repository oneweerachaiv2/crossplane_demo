# Crossplane Kubernetes Application Deployment Guide

## Overview

This guide demonstrates how to use Crossplane to manage Kubernetes applications (Deployments, Services, etc.) on a remote Kubernetes cluster using the Kubernetes Provider.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Crossplane Control Plane                 │
│                    (Kind Cluster on VM)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Kubernetes Provider (v0.11.0)                       │  │
│  │  - Manages Kubernetes Objects (Deployments, Svcs)   │  │
│  │  - Uses ProviderConfig for authentication            │  │
│  │  - Syncs resources to target cluster                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Crossplane Objects (kubernetes.crossplane.io)      │  │
│  │  - nginx-deployment, nginx-service                  │  │
│  │  - httpbin-deployment, httpbin-service              │  │
│  │  - redis-deployment, redis-service                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Manages
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Target Kubernetes Cluster                      │
│              (Same Kind Cluster)                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Deployments:                                               │
│  - nginx-app (2 replicas)                                   │
│  - httpbin-app (1 replica)                                  │
│  - redis-app (1 replica)                                    │
│                                                              │
│  Services:                                                  │
│  - nginx-app (ClusterIP:80)                                 │
│  - httpbin-app (ClusterIP:8080)                             │
│  - redis-app (ClusterIP:6379)                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. Kubernetes Provider
- **Version**: v0.11.0
- **Purpose**: Manages Kubernetes resources on target clusters
- **Status**: Healthy and running

### 2. ProviderConfig
- **Name**: default
- **Authentication**: InjectedIdentity (uses in-cluster service account)
- **RBAC**: ClusterRole with admin permissions

### 3. Crossplane Objects
Managed resources that represent Kubernetes objects:
- `kubernetes.crossplane.io/v1alpha2` - Object kind
- Each object has SYNCED and READY status

## Deployed Applications

### Nginx
- **Deployment**: nginx-app (2 replicas)
- **Service**: nginx-app (ClusterIP:80)
- **Status**: ✅ Running and accessible

### HTTPBin
- **Deployment**: httpbin-app (1 replica)
- **Service**: httpbin-app (ClusterIP:8080)
- **Status**: ✅ Running and accessible

### Redis
- **Deployment**: redis-app (1 replica)
- **Service**: redis-app (ClusterIP:6379)
- **Status**: ✅ Running and accessible

## How It Works

1. **Define Crossplane Object**: Create a `kubernetes.crossplane.io/v1alpha2` Object resource
2. **Specify Manifest**: Include the Kubernetes manifest in `spec.forProvider.manifest`
3. **Reference Provider**: Point to ProviderConfig via `spec.providerConfigRef`
4. **Apply**: kubectl apply the Crossplane object
5. **Sync**: Crossplane provider creates the actual Kubernetes resource
6. **Monitor**: Check status with `kubectl get objects`

## Example: Deploying an Application

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
        replicas: 2
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
```

## Useful Commands

```bash
# List all Crossplane objects
kubectl get objects

# Describe a specific object
kubectl describe object my-app-deployment

# Check object status
kubectl get object my-app-deployment -o yaml

# Watch object status
kubectl get objects -w

# Check actual Kubernetes resources
kubectl get deployments
kubectl get services
kubectl get pods
```

## Benefits of Using Crossplane

1. **Infrastructure as Code**: Manage all resources declaratively
2. **Unified API**: Single interface for multiple cloud providers
3. **Composition**: Create reusable templates for common patterns
4. **GitOps Ready**: Version control and CI/CD integration
5. **Multi-Cloud**: Manage resources across different clouds

