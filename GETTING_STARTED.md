# Getting Started with Crossplane Kubernetes Application Deployment

## What is Crossplane?

Crossplane is a Kubernetes-native infrastructure management platform that enables you to:
- Define infrastructure as code using Kubernetes manifests
- Manage resources across multiple cloud providers
- Create reusable templates for common patterns
- Integrate with GitOps workflows

## What We've Set Up

We've configured Crossplane to manage Kubernetes applications (Deployments, Services, etc.) on your Kind cluster using the Kubernetes Provider.

### Current Deployment

✅ **3 Applications Running**:
- **Nginx**: 2 replicas, accessible on port 80
- **HTTPBin**: 1 replica, accessible on port 8080
- **Redis**: 1 replica, accessible on port 6379

## Quick Start

### 1. Check Status
```bash
# SSH into the VM
ssh -i eapi-gateway-api-poc_key.pem azureuser@172.188.120.75

# Check Crossplane objects
kubectl get objects

# Check Kubernetes resources
kubectl get deployments
kubectl get services
kubectl get pods
```

### 2. Deploy a New Application

Create a file `my-app.yaml`:
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
```

Deploy it:
```bash
kubectl apply -f my-app.yaml
```

### 3. Monitor Deployment
```bash
# Watch Crossplane objects
kubectl get objects -w

# Check deployment status
kubectl describe object my-app-deployment

# Check actual Kubernetes resources
kubectl get deployment my-app
kubectl get pods -l app=my-app
```

### 4. Delete Application
```bash
kubectl delete object my-app-deployment
```

## Key Concepts

### Crossplane Objects
- Represent Kubernetes resources managed by Crossplane
- Located in `kubernetes.crossplane.io/v1alpha2` API group
- Have SYNCED and READY status conditions

### ProviderConfig
- Configures how Crossplane connects to the target cluster
- Name: `default`
- Uses in-cluster service account for authentication

### Manifest
- The actual Kubernetes resource definition
- Placed in `spec.forProvider.manifest`
- Can be any Kubernetes resource (Deployment, Service, ConfigMap, etc.)

## File Structure

```
├── providers/
│   └── kubernetes-provider-config.yaml    # ProviderConfig
├── examples/
│   ├── nginx-app.yaml                     # Nginx example
│   ├── httpbin-app.yaml                   # HTTPBin example
│   ├── redis-app.yaml                     # Redis example
│   ├── kubernetes-app-deployment.md       # Detailed guide
│   └── QUICKSTART-APPS.md                 # Quick reference
├── AGENTS.md                              # Main documentation
├── DEPLOYMENT_SUMMARY.md                  # Deployment summary
└── GETTING_STARTED.md                     # This file
```

## Useful Commands

```bash
# List all Crossplane objects
kubectl get objects

# Get detailed status
kubectl describe object <object-name>

# Get YAML output
kubectl get object <object-name> -o yaml

# Watch for changes
kubectl get objects -w

# Delete an object
kubectl delete object <object-name>

# Check provider status
kubectl get providers

# Check provider logs
kubectl logs -n crossplane-system -l app=provider-kubernetes
```

## Troubleshooting

### Object not syncing?
```bash
# Check object status
kubectl describe object <object-name>

# Check provider logs
kubectl logs -n crossplane-system -l app=provider-kubernetes

# Check RBAC permissions
kubectl get clusterrole provider-kubernetes-admin
kubectl get clusterrolebinding provider-kubernetes-admin
```

### Deployment not created?
```bash
# Check if object is SYNCED
kubectl get objects

# Check Kubernetes resources
kubectl get deployments
kubectl get services

# Check pod logs
kubectl logs -l app=<app-name>
```

## Next Steps

1. **Explore Examples**: Check `examples/` directory for more patterns
2. **Create Compositions**: Build reusable templates in `compositions/`
3. **Multi-Cluster**: Deploy to multiple clusters
4. **GitOps**: Integrate with ArgoCD or Flux
5. **Azure Integration**: Combine with Azure provider for full infrastructure

## Resources

- **Crossplane Docs**: https://docs.crossplane.io/
- **Kubernetes Provider**: https://github.com/crossplane/provider-kubernetes
- **Examples**: See `examples/` directory
- **Quick Start**: See `examples/QUICKSTART-APPS.md`

## Support

For issues or questions:
1. Check the logs: `kubectl logs -n crossplane-system`
2. Review the examples in `examples/`
3. Check Crossplane documentation
4. Verify RBAC permissions are configured

