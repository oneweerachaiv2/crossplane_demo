#!/bin/bash
# ArgoCD Installation Script for Kind Cluster with Crossplane
# This script installs ArgoCD and configures it to work with Crossplane

set -e

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ArgoCD Installation for Crossplane                     ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_status "Connected to Kubernetes cluster"

# Step 1: Create ArgoCD namespace
echo ""
echo "Step 1: Creating ArgoCD namespace..."
if kubectl get namespace argocd &> /dev/null; then
    print_warning "Namespace 'argocd' already exists"
else
    kubectl create namespace argocd
    print_status "Created namespace 'argocd'"
fi

# Step 2: Install ArgoCD
echo ""
echo "Step 2: Installing ArgoCD..."
ARGOCD_VERSION="v2.9.3"
print_status "Installing ArgoCD ${ARGOCD_VERSION}..."

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

print_status "ArgoCD manifests applied"

# Step 3: Wait for ArgoCD to be ready
echo ""
echo "Step 3: Waiting for ArgoCD pods to be ready..."
echo "This may take 2-3 minutes..."

kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n argocd

print_status "ArgoCD pods are ready"

# Step 4: Get ArgoCD admin password
echo ""
echo "Step 4: Retrieving ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

print_status "ArgoCD admin password retrieved"

# Step 5: Display connection info
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                     ArgoCD Installation Complete                           ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "ArgoCD Admin Credentials:"
echo "  Username: admin"
echo "  Password: ${ARGOCD_PASSWORD}"
echo ""
echo "To access ArgoCD UI:"
echo "  Option 1: Port forward"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "    Then access: https://localhost:8080"
echo ""
echo "  Option 2: NodePort (for Kind)"
echo "    kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"NodePort\"}}'"
echo ""
echo "To install ArgoCD CLI:"
echo "  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "  chmod +x argocd"
echo "  sudo mv argocd /usr/local/bin/"
echo ""
echo "To login with ArgoCD CLI:"
echo "  argocd login localhost:8080 --username admin --password ${ARGOCD_PASSWORD} --insecure"
echo ""

# Step 6: Show ArgoCD status
echo "ArgoCD Status:"
kubectl get pods -n argocd
echo ""
kubectl get svc -n argocd

