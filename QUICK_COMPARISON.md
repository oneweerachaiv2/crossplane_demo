# Quick Comparison: Traditional vs Crossplane

## The Question You Asked

> "I see we need to create yml like traditional."

**Yes, but with superpowers!**

---

## Side-by-Side Comparison

### Traditional Kubernetes

**What you write:**
```yaml
# deployment.yaml
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
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-app
spec:
  selector:
    app: nginx-app
  ports:
  - port: 80
```

**What you do:**
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get deployment
kubectl get service
# Manual tracking and updates
```

**Problems:**
- ❌ Multiple files
- ❌ Manual coordination
- ❌ No reusability
- ❌ Manual status tracking
- ❌ No drift detection

---

### Crossplane Objects

**What you write:**
```yaml
# app.yaml
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
        selector:
          app: nginx-app
        ports:
        - port: 80
  providerConfigRef:
    name: default
```

**What you do:**
```bash
kubectl apply -f app.yaml
kubectl get objects
# Automatic tracking and syncing
```

**Benefits:**
- ✅ Single file
- ✅ Automatic coordination
- ✅ Automatic status tracking
- ✅ Automatic drift detection
- ✅ Automatic syncing

---

## Key Differences

| Aspect | Traditional | Crossplane |
|--------|-------------|-----------|
| **Files** | Multiple (1 per resource) | Single (multiple resources) |
| **Apply** | Multiple commands | Single command |
| **Status** | Manual `kubectl get` | Automatic `kubectl get objects` |
| **Tracking** | Manual | Automatic |
| **Drift Detection** | None | Automatic |
| **Syncing** | Manual | Automatic |
| **Reusability** | None | Via Compositions |
| **Multi-Cloud** | No | Yes |

---

## What Crossplane Adds

### 1. Unified Management
```bash
# One command for all resources
kubectl apply -f app.yaml

# One status check
kubectl get objects
```

### 2. Automatic Syncing
```bash
# Crossplane watches and syncs automatically
kubectl get objects
# NAME                 SYNCED   READY
# nginx-deployment     True     True
# nginx-service        True     True
```

### 3. Drift Detection
```
If someone manually changes the resource:
  Crossplane detects it
  Crossplane corrects it
  Your manifest is the source of truth
```

### 4. Reusability (Compositions)
```yaml
# Define once
apiVersion: demo.crossplane.io/v1alpha1
kind: WebApp
metadata:
  name: my-nginx
spec:
  image: nginx:latest
  replicas: 2

# Deploy another app - just change the name and image!
apiVersion: demo.crossplane.io/v1alpha1
kind: WebApp
metadata:
  name: my-httpbin
spec:
  image: kennethreitz/httpbin:latest
  replicas: 1
```

---

## Real-World Example

### Scenario: Deploy 3 Apps

#### Traditional Way
```bash
# 6 files
nginx-deployment.yaml
nginx-service.yaml
httpbin-deployment.yaml
httpbin-service.yaml
redis-deployment.yaml
redis-service.yaml

# 6 commands
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
kubectl apply -f httpbin-deployment.yaml
kubectl apply -f httpbin-service.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml

# Manual tracking
kubectl get deployment
kubectl get service
```

#### Crossplane Way
```bash
# 3 files
nginx-app.yaml
httpbin-app.yaml
redis-app.yaml

# 3 commands
kubectl apply -f nginx-app.yaml
kubectl apply -f httpbin-app.yaml
kubectl apply -f redis-app.yaml

# Automatic tracking
kubectl get objects
```

#### Composition Way
```bash
# 3 files (reusable!)
app-xrd.yaml (define once)
app-composition.yaml (define once)
claims.yaml (just parameters)

# 3 commands
kubectl apply -f app-xrd.yaml
kubectl apply -f app-composition.yaml
kubectl apply -f claims.yaml

# Automatic tracking
kubectl get webapps
```

---

## The Bottom Line

**You still write YAML** - but Crossplane:
- ✅ Reduces file count
- ✅ Reduces commands
- ✅ Adds automatic tracking
- ✅ Adds automatic syncing
- ✅ Enables reusability
- ✅ Supports multi-cloud

**Start with:** Crossplane Objects (like our examples)
**Graduate to:** Compositions (for reusability)

---

## Our Current Setup

We've deployed 3 apps using **Crossplane Objects**:
- ✅ Nginx (2 replicas, port 80)
- ✅ HTTPBin (1 replica, port 8080)
- ✅ Redis (1 replica, port 6379)

All in 3 YAML files with automatic tracking and syncing!

Check `examples/` for the actual files.

