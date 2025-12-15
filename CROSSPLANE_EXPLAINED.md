# Crossplane Explained: Creating Deployments and Services

## Quick Answer

**Yes, you still write YAML, but Crossplane adds:**
- 🔄 Automatic lifecycle management
- 📊 Built-in status tracking
- 🔁 Automatic syncing and drift detection
- 🎯 Reusable templates (Compositions)
- ☁️ Multi-cloud support

---

## The Three Layers

### Layer 1: Crossplane Objects (What We're Using)

**What it is:** Kubernetes resources that wrap your manifests

**Structure:**
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: my-app-deployment
spec:
  forProvider:
    manifest:
      # Your actual Kubernetes manifest goes here
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: my-app
      spec:
        replicas: 2
        # ... rest of deployment spec
  providerConfigRef:
    name: default  # Tells Crossplane where to deploy
```

**Key Parts:**
- `kind: Object` - Crossplane resource type
- `manifest:` - Your actual Kubernetes resource
- `providerConfigRef:` - Which cluster/cloud to use

**Benefits:**
- ✅ Single file for related resources
- ✅ Crossplane tracks status
- ✅ Automatic syncing
- ✅ Works with any Kubernetes resource

---

### Layer 2: Compositions (Reusable Templates)

**What it is:** A template system for standardizing deployments

**Three Components:**

#### 1. XRD (CompositeResourceDefinition)
Defines a user-friendly API:
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xwebapps.demo.crossplane.io
spec:
  group: demo.crossplane.io
  names:
    kind: XWebApp
  claimNames:
    kind: WebApp  # Users create "WebApp" claims
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          spec:
            properties:
              appName:
                type: string
              image:
                type: string
              replicas:
                type: integer
```

#### 2. Composition
Maps user inputs to actual resources:
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: webapp-composition
spec:
  compositeTypeRef:
    apiVersion: demo.crossplane.io/v1alpha1
    kind: XWebApp
  resources:
  - name: deployment
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: apps/v1
            kind: Deployment
            # Template for deployment
```

#### 3. Claim
Users just specify parameters:
```yaml
apiVersion: demo.crossplane.io/v1alpha1
kind: WebApp
metadata:
  name: my-nginx
spec:
  appName: my-nginx
  image: nginx:latest
  replicas: 2
```

**Benefits:**
- ✅ Platform team defines template once
- ✅ App teams just specify parameters
- ✅ Standardized deployments
- ✅ Easy to scale

---

## Real Example: Our Deployment

### What We Created

**File 1: nginx-app.yaml** (Crossplane Objects)
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
      spec:
        replicas: 2
        template:
          spec:
            containers:
            - name: nginx
              image: nginx:latest
              ports:
              - containerPort: 80
  providerConfigRef:
    name: default
---
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: nginx-service
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Service
      metadata:
        name: nginx-app
      spec:
        type: ClusterIP
        selector:
          app: nginx-app
        ports:
        - port: 80
          targetPort: 80
  providerConfigRef:
    name: default
```

### What Happens

1. **You apply:** `kubectl apply -f nginx-app.yaml`
2. **Crossplane sees:** Two Object resources
3. **Crossplane creates:** Deployment + Service in Kubernetes
4. **Crossplane tracks:** Status of both resources
5. **Crossplane syncs:** If you change the manifest, it updates
6. **You monitor:** `kubectl get objects` shows SYNCED and READY

---

## Comparison: Traditional vs Crossplane

### Traditional Way
```bash
# File 1: deployment.yaml
apiVersion: apps/v1
kind: Deployment
...

# File 2: service.yaml
apiVersion: v1
kind: Service
...

# Apply both
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Monitor manually
kubectl get deployment
kubectl get service
```

### Crossplane Way
```bash
# File: app.yaml (contains both)
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: deployment
spec:
  forProvider:
    manifest:
      apiVersion: apps/v1
      kind: Deployment
      ...
---
apiVersion: kubernetes.crossplane.io/v1alpha2
kind: Object
metadata:
  name: service
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Service
      ...

# Apply once
kubectl apply -f app.yaml

# Monitor automatically
kubectl get objects  # Shows both with status
```

---

## Key Concepts

### ProviderConfig
Tells Crossplane where to deploy:
```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: InjectedIdentity  # Use in-cluster service account
```

### Status Tracking
```bash
kubectl get objects
# NAME                 KIND         SYNCED   READY
# nginx-deployment     Deployment   True     True
# nginx-service        Service      True     True
```

### Automatic Syncing
- Crossplane watches your manifests
- If you change the manifest, it updates the resource
- If someone changes the resource directly, Crossplane corrects it

---

## When to Use Each Approach

| Scenario | Use |
|----------|-----|
| Learning Kubernetes | Traditional |
| One-off deployments | Traditional |
| Managing related resources | Crossplane Objects |
| Standardizing deployments | Compositions |
| Multi-cloud infrastructure | Crossplane |
| Platform engineering | Compositions |

---

## Summary

**Crossplane doesn't replace YAML** - it enhances it:

1. **Crossplane Objects** - Wrap manifests for lifecycle management
2. **Compositions** - Create reusable templates
3. **Claims** - Simple user-friendly API

**Start here:** Use Crossplane Objects (like our nginx-app.yaml)
**Graduate to:** Compositions for reusability

All files are in your workspace - check `examples/` for working examples!

