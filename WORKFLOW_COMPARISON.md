# Workflow Comparison: Traditional vs Crossplane

## Scenario: Deploy Nginx with Deployment + Service

---

## Traditional Kubernetes Workflow

### Step 1: Create deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
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
```

### Step 2: Create service.yaml
```yaml
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
```

### Step 3: Apply both files
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### Step 4: Monitor manually
```bash
kubectl get deployment
kubectl get service
kubectl get pods
# Check each one separately
```

### Step 5: Update (if needed)
```bash
# Edit deployment.yaml
# Edit service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Total Files:** 2
**Total Commands:** 5+
**Manual Steps:** Many

---

## Crossplane Objects Workflow

### Step 1: Create app.yaml (single file)
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

### Step 2: Apply single file
```bash
kubectl apply -f app.yaml
```

### Step 3: Monitor automatically
```bash
kubectl get objects
# Shows both with status
# NAME                 KIND         SYNCED   READY
# nginx-deployment     Deployment   True     True
# nginx-service        Service      True     True
```

### Step 4: Update (if needed)
```bash
# Edit app.yaml
kubectl apply -f app.yaml
# Crossplane automatically syncs both resources
```

**Total Files:** 1
**Total Commands:** 2
**Manual Steps:** Minimal

---

## Compositions Workflow (Best Practice)

### Step 1: Define XRD (once)
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
```

### Step 2: Define Composition (once)
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
            # Template...
  - name: service
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        forProvider:
          manifest:
            apiVersion: v1
            kind: Service
            # Template...
```

### Step 3: Create Claim (simple!)
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

### Step 4: Deploy another app (just change parameters!)
```yaml
apiVersion: demo.crossplane.io/v1alpha1
kind: WebApp
metadata:
  name: my-httpbin
spec:
  appName: my-httpbin
  image: kennethreitz/httpbin:latest
  replicas: 1
```

### Step 5: Monitor all
```bash
kubectl get webapps
# Shows all deployed apps
```

**Total Files:** 3 (reusable!)
**Total Commands:** 3
**Manual Steps:** Minimal
**Reusability:** Excellent

---

## Comparison Summary

| Aspect | Traditional | Crossplane | Composition |
|--------|-------------|-----------|------------|
| **Files for 1 app** | 2 | 1 | 3 (reusable) |
| **Files for 5 apps** | 10 | 5 | 3 + 5 claims |
| **Commands for 1 app** | 2+ | 1 | 1 |
| **Commands for 5 apps** | 10+ | 5 | 5 |
| **Status tracking** | Manual | Automatic | Automatic |
| **Syncing** | Manual | Automatic | Automatic |
| **Reusability** | None | Manual | Automatic |
| **Learning curve** | Easy | Medium | Medium |

---

## Key Takeaways

### Traditional
- ✅ Simple for beginners
- ❌ Doesn't scale
- ❌ Manual everything

### Crossplane Objects
- ✅ Reduces files
- ✅ Automatic tracking
- ✅ Automatic syncing
- ❌ Still manual for each app

### Compositions
- ✅ Define once, use many times
- ✅ Standardized deployments
- ✅ Automatic everything
- ✅ Scales to 100+ apps

---

## Our Current Setup

We're using **Crossplane Objects** approach:
- ✅ 3 YAML files (nginx, httpbin, redis)
- ✅ Automatic tracking
- ✅ Automatic syncing
- ✅ All apps running

**Next step:** Create Compositions for reusability!

