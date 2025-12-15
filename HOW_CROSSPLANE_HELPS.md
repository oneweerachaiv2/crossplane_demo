# How Crossplane Helps Create Deployments and Services

## The Short Answer

**Yes, you still create YAML files, but Crossplane adds powerful features:**

1. **Unified Management** - Manage all resources through Crossplane
2. **Automatic Syncing** - Crossplane tracks and syncs resources
3. **Reusable Templates** - Create once, use many times (Compositions)
4. **Multi-Cloud** - Same approach for Kubernetes, Azure, AWS, GCP
5. **Infrastructure as Code** - Version control everything

---

## Three Approaches Explained

### 1️⃣ Traditional Kubernetes (What You Know)

**Create separate YAML files:**
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

**Apply separately:**
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Problems:**
- ❌ Multiple files to manage
- ❌ Manual coordination
- ❌ No reusability
- ❌ Hard to standardize

---

### 2️⃣ Crossplane Objects (Direct Approach)

**Embed manifests in Crossplane Objects:**
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

**Benefits:**
- ✅ Single file for related resources
- ✅ Crossplane manages lifecycle
- ✅ Automatic status tracking
- ✅ Works with any Kubernetes resource

**Apply once:**
```bash
kubectl apply -f nginx-app.yaml
```

---

### 3️⃣ Compositions (Best Practice - Reusable Templates)

**Step 1: Define XRD (User-friendly API)**
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
    kind: WebApp
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
              port:
                type: integer
```

**Step 2: Define Composition (Template)**
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
            spec:
              replicas: 1
              template:
                spec:
                  containers:
                  - image: nginx:latest
```

**Step 3: Create Claim (Simple parameters)**
```yaml
apiVersion: demo.crossplane.io/v1alpha1
kind: WebApp
metadata:
  name: my-nginx
spec:
  appName: my-nginx
  image: nginx:latest
  replicas: 2
  port: 80
```

**Benefits:**
- ✅ Simple, user-friendly API
- ✅ Reuse template for many apps
- ✅ Standardized deployments
- ✅ Platform team controls template
- ✅ App teams just specify parameters

---

## Comparison Table

| Feature | Traditional | Crossplane Objects | Compositions |
|---------|-------------|-------------------|--------------|
| YAML Files | Multiple | Single | 3 (XRD + Composition + Claim) |
| Reusability | None | Manual | Automatic |
| Status Tracking | Manual | Automatic | Automatic |
| Multi-Cloud | No | Yes | Yes |
| Learning Curve | Easy | Medium | Medium |
| Standardization | Hard | Medium | Easy |
| Scalability | Poor | Good | Excellent |

---

## Real-World Example

### Traditional Way (3 files)
```bash
# File 1: nginx-deployment.yaml
# File 2: nginx-service.yaml
# File 3: nginx-configmap.yaml
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
kubectl apply -f nginx-configmap.yaml
```

### Crossplane Way (1 file)
```bash
# File: nginx-app.yaml (contains Deployment + Service + ConfigMap)
kubectl apply -f nginx-app.yaml
```

### Composition Way (3 files, but reusable)
```bash
# File 1: app-xrd.yaml (define once)
# File 2: app-composition.yaml (define once)
# File 3: my-nginx-claim.yaml (just parameters)
kubectl apply -f app-xrd.yaml
kubectl apply -f app-composition.yaml
kubectl apply -f my-nginx-claim.yaml

# Deploy another app - just create another claim!
# File 4: my-httpbin-claim.yaml
kubectl apply -f my-httpbin-claim.yaml
```

---

## Key Advantages of Crossplane

### 1. **Unified Management**
- Manage Kubernetes, Azure, AWS, GCP in one place
- Same workflow for all resources

### 2. **Automatic Syncing**
- Crossplane watches resources
- Detects drift and corrects it
- No manual reconciliation

### 3. **Status Tracking**
```bash
kubectl get objects
# Shows SYNCED and READY status
```

### 4. **Reusability**
- Create template once
- Deploy 100 times with different parameters

### 5. **GitOps Ready**
- All infrastructure in Git
- Version control everything
- Easy rollback

### 6. **Multi-Cluster**
- Deploy to multiple clusters from one control plane
- Consistent across environments

---

## When to Use Each Approach

| Scenario | Use |
|----------|-----|
| Learning Kubernetes | Traditional |
| Simple one-off deployments | Traditional |
| Managing multiple resources together | Crossplane Objects |
| Standardizing deployments | Compositions |
| Multi-cloud infrastructure | Crossplane |
| Platform engineering | Compositions |
| GitOps workflows | Crossplane |

---

## Summary

**Crossplane doesn't eliminate YAML** - it enhances it by:
- Adding lifecycle management
- Enabling reusability
- Supporting multi-cloud
- Providing automatic syncing
- Standardizing deployments

**Start with:** Crossplane Objects (direct approach)
**Graduate to:** Compositions (reusable templates)

