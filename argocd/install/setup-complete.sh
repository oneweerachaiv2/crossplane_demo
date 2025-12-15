#!/bin/bash
# Complete ArgoCD + Crossplane Setup Script
# This script installs ArgoCD and configures it for Crossplane

set -e

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║           Complete ArgoCD + Crossplane GitOps Setup                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Step $1: $2${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}\n"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check prerequisites
print_step "0" "Checking Prerequisites"

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi
print_status "kubectl found"

if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
print_status "Connected to Kubernetes cluster"

# Check if Crossplane is installed
if kubectl get pods -n crossplane-system 2>/dev/null | grep -q crossplane; then
    print_status "Crossplane is installed"
else
    print_warning "Crossplane not found - continuing anyway"
fi

# Step 1: Create ArgoCD namespace
print_step "1" "Creating ArgoCD Namespace"

if kubectl get namespace argocd &> /dev/null; then
    print_warning "Namespace 'argocd' already exists"
else
    kubectl create namespace argocd
    print_status "Created namespace 'argocd'"
fi

# Step 2: Install ArgoCD
print_step "2" "Installing ArgoCD"

ARGOCD_VERSION="v2.9.3"
echo "Installing ArgoCD ${ARGOCD_VERSION}..."

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

print_status "ArgoCD manifests applied"

# Step 3: Wait for ArgoCD
print_step "3" "Waiting for ArgoCD to be Ready"

echo "This may take 2-3 minutes..."

# Wait for deployments
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-applicationset-controller -n argocd --timeout=300s

print_status "ArgoCD is ready"

# Step 4: Configure for Crossplane
print_step "4" "Configuring ArgoCD for Crossplane Compatibility"

# Apply the Crossplane-compatible ConfigMap
cat << 'CONFIGMAP_EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  application.resourceTrackingMethod: annotation
  resource.exclusions: |
    - apiGroups:
      - "*"
      kinds:
      - ProviderConfigUsage
  resource.customizations: |
    "kubernetes.crossplane.io/*":
      health.lua: |
        health_status = {
          status = "Progressing",
          message = "Provisioning ..."
        }
        if obj.status == nil or obj.status.conditions == nil then
          return health_status
        end
        for i, condition in ipairs(obj.status.conditions) do
          if condition.type == "Synced" then
            if condition.status == "False" then
              health_status.status = "Degraded"
              health_status.message = condition.message
              return health_status
            end
          end
          if condition.type == "Ready" then
            if condition.status == "True" then
              health_status.status = "Healthy"
              health_status.message = "Resource is synced and ready."
            end
          end
        end
        return health_status
CONFIGMAP_EOF

print_status "ArgoCD configured for Crossplane"

# Restart ArgoCD to pick up changes
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-repo-server -n argocd
sleep 10
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

print_status "ArgoCD restarted with new configuration"

# Step 5: Get credentials
print_step "5" "Retrieving ArgoCD Credentials"

# Wait for secret to be created
sleep 5
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

if [ -z "$ARGOCD_PASSWORD" ]; then
    print_warning "Could not retrieve password - secret may not be ready yet"
    ARGOCD_PASSWORD="(run: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
fi

# Step 6: Expose ArgoCD
print_step "6" "Exposing ArgoCD Service"

# Patch to NodePort for Kind access
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

NODE_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

print_status "ArgoCD exposed on NodePort: ${NODE_PORT}"

# Final summary
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    ArgoCD + Crossplane Setup Complete!                     ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "ArgoCD Admin Credentials:"
echo "  Username: admin"
echo "  Password: ${ARGOCD_PASSWORD}"
echo ""
echo "ArgoCD UI Access:"
echo "  NodePort: ${NODE_PORT}"
echo "  URL: https://<node-ip>:${NODE_PORT}"
echo ""
echo "Port Forward (recommended):"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo "  Then access: https://localhost:8080"
echo ""
echo "ArgoCD Status:"
kubectl get pods -n argocd
echo ""
echo "Next Steps:"
echo "  1. Access ArgoCD UI"
echo "  2. Create Applications to sync your Crossplane manifests"
echo "  3. Watch ArgoCD deploy Crossplane Objects"
echo "  4. Crossplane provisions the actual resources"
echo ""

