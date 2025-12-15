#!/bin/bash
# Crossplane Installation Script
# This script installs Crossplane on your Kubernetes cluster

set -e

echo "=== Crossplane Installation Script ==="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed or not in PATH"
    echo "Install helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check cluster connectivity
echo "Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi
echo "✓ Connected to Kubernetes cluster"

# Create crossplane-system namespace
echo ""
echo "Creating crossplane-system namespace..."
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace ready"

# Add Crossplane Helm repository
echo ""
echo "Adding Crossplane Helm repository..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
echo "✓ Helm repository added"

# Install Crossplane
echo ""
echo "Installing Crossplane..."
helm install crossplane \
    --namespace crossplane-system \
    crossplane-stable/crossplane \
    --wait

echo "✓ Crossplane installed"

# Wait for Crossplane pods to be ready
echo ""
echo "Waiting for Crossplane pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n crossplane-system --timeout=120s
echo "✓ All Crossplane pods are ready"

# Verify installation
echo ""
echo "=== Crossplane Installation Complete ==="
echo ""
echo "Installed components:"
kubectl get pods -n crossplane-system
echo ""
echo "Crossplane CRDs:"
kubectl get crds | grep crossplane.io || echo "No CRDs found yet (they will be created when you install providers)"
echo ""
echo "Next steps:"
echo "1. Install a provider: kubectl apply -f providers/azure-provider.yaml"
echo "2. Configure provider credentials"
echo "3. Create compositions and claims"

