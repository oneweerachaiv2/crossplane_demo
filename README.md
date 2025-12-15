# Crossplane Learning Project

A comprehensive learning project demonstrating Crossplane's capabilities for managing Kubernetes infrastructure and applications.

## 🎯 Project Overview

This project showcases:
- **Crossplane Installation**: Complete setup on Kind cluster
- **Azure Provider**: Managing Azure resources (storage, compute, network)
- **Kubernetes Provider**: Managing Kubernetes applications and resources
- **Infrastructure as Code**: Declarative resource management
- **Multi-Provider Support**: Azure + Kubernetes in one platform

## 📋 What's Included

### ✅ Completed Setup

1. **Crossplane v2.1.3** - Installed and running
2. **Azure Providers** - All 4 providers healthy
3. **Kubernetes Provider v0.11.0** - Installed and healthy
4. **3 Sample Applications** - Nginx, HTTPBin, Redis
5. **Complete Documentation** - Guides and examples

### 📁 Project Structure

```
├── AGENTS.md                          # Main documentation
├── GETTING_STARTED.md                 # Quick start guide
├── DEPLOYMENT_SUMMARY.md              # Deployment status
├── README.md                          # This file
│
├── providers/                         # Provider configurations
│   ├── azure-provider.yaml
│   ├── azure-provider-config.yaml
│   └── kubernetes-provider-config.yaml
│
├── compositions/                      # XRDs and Compositions
│   ├── storage-xrd.yaml
│   ├── storage-composition.yaml
│   ├── app-xrd.yaml
│   └── app-composition.yaml
│
├── claims/                            # User-facing claims
│   ├── storage-claim.yaml
│   ├── webapp-nginx.yaml
│   └── webapp-httpbin.yaml
│
├── examples/                          # Learning examples
│   ├── nginx-app.yaml
│   ├── httpbin-app.yaml
│   ├── redis-app.yaml
│   ├── kubernetes-app-deployment.md
│   └── QUICKSTART-APPS.md
│
└── install-crossplane.sh              # Installation script
```

## 🚀 Quick Start

### 1. Access the VM
```bash
ssh -i eapi-gateway-api-poc_key.pem azureuser@172.188.120.75
```

### 2. Check Status
```bash
# Check Crossplane
kubectl get providers

# Check deployed applications
kubectl get objects
kubectl get deployments
kubectl get services
```

### 3. Deploy an Application
```bash
# Deploy Nginx
kubectl apply -f examples/nginx-app.yaml

# Monitor
kubectl get objects -w
```

### 4. View Documentation
- **Getting Started**: See `GETTING_STARTED.md`
- **Deployment Guide**: See `examples/kubernetes-app-deployment.md`
- **Quick Reference**: See `examples/QUICKSTART-APPS.md`
- **Main Docs**: See `AGENTS.md`

## 📊 Current Status

### Providers
- ✅ Crossplane v2.1.3
- ✅ Azure Provider (storage, compute, network, family)
- ✅ Kubernetes Provider v0.11.0

### Applications
- ✅ Nginx (2 replicas, port 80)
- ✅ HTTPBin (1 replica, port 8080)
- ✅ Redis (1 replica, port 6379)

### Infrastructure
- ✅ Kind Cluster on Azure VM
- ✅ Disk space optimized (Docker moved to /mnt)
- ✅ RBAC configured
- ✅ All providers healthy

## 🔑 Key Concepts

### Crossplane Objects
Kubernetes-native resources that represent managed infrastructure:
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: my-app
spec:
  forProvider:
    manifest: <kubernetes-resource>
  providerConfigRef:
    name: default
```

### ProviderConfig
Configures authentication and connection details:
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: InjectedIdentity
```

### Compositions
Reusable templates for common patterns (XRD + Composition):
- Define user-friendly APIs
- Map to actual cloud resources
- Enable self-service infrastructure

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `GETTING_STARTED.md` | Quick start and basic concepts |
| `AGENTS.md` | Complete reference guide |
| `DEPLOYMENT_SUMMARY.md` | Current deployment status |
| `examples/kubernetes-app-deployment.md` | Detailed deployment guide |
| `examples/QUICKSTART-APPS.md` | Quick reference for commands |

## 🛠️ Common Tasks

### Deploy Application
```bash
kubectl apply -f examples/nginx-app.yaml
```

### Check Status
```bash
kubectl get objects
kubectl describe object nginx-deployment
```

### Monitor Deployment
```bash
kubectl get objects -w
```

### Delete Application
```bash
kubectl delete object nginx-deployment nginx-service
```

### View Logs
```bash
kubectl logs -n crossplane-system -l app=provider-kubernetes
```

## 🔗 Resources

- **Crossplane**: https://crossplane.io/
- **Documentation**: https://docs.crossplane.io/
- **GitHub**: https://github.com/crossplane/crossplane
- **Kubernetes Provider**: https://github.com/crossplane/provider-kubernetes

## 📝 Notes

- **VM Access**: SSH key required (`eapi-gateway-api-poc_key.pem`)
- **Subscription**: Azure subscription `3c6373fe-834d-4f88-bb56-539b8e02bd96`
- **Cluster**: Kind cluster running on Azure VM at `172.188.120.75`
- **Namespace**: Crossplane runs in `crossplane-system` namespace

## 🎓 Learning Path

1. **Start**: Read `GETTING_STARTED.md`
2. **Explore**: Check `examples/` directory
3. **Deploy**: Use `examples/QUICKSTART-APPS.md`
4. **Deep Dive**: Read `AGENTS.md` and `examples/kubernetes-app-deployment.md`
5. **Experiment**: Create your own applications

## ✨ Next Steps

- [ ] Create custom Compositions
- [ ] Deploy to multiple clusters
- [ ] Integrate with GitOps (ArgoCD/Flux)
- [ ] Configure Azure resources
- [ ] Set up CI/CD pipeline

---

**Last Updated**: 2025-12-15
**Status**: ✅ All systems operational

