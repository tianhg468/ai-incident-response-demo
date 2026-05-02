#!/bin/bash
# Complete setup script for demo environment

set -e

echo "🚀 Setting up AI Incident Response Demo Environment"
echo "=================================================="
echo ""

# Check prerequisites
echo "Step 1: Checking prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed. Install from https://docker.com"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not installed. Run: brew install kubectl"; exit 1; }
command -v minikube >/dev/null 2>&1 || { echo "❌ minikube not installed. Run: brew install minikube"; exit 1; }
echo "✅ All prerequisites installed"
echo ""

# Start minikube
echo "Step 2: Starting minikube..."
if minikube status | grep -q "Running"; then
  echo "✅ Minikube already running"
else
  echo "Starting minikube with 4GB RAM and 2 CPUs..."
  minikube start --memory=4096 --cpus=2 --driver=docker
  echo "✅ Minikube started"
fi
echo ""

# Enable addons
echo "Step 3: Enabling minikube addons..."
minikube addons enable metrics-server
echo "✅ Metrics server enabled"
echo ""

# Use minikube's Docker daemon
echo "Step 4: Configuring Docker to use minikube..."
eval $(minikube docker-env)
echo "✅ Docker configured"
echo ""

# Build the application image
echo "Step 5: Building application Docker image..."
docker build -t demo-app:v1 .
echo "✅ Image built: demo-app:v1"
echo ""

# Deploy to Kubernetes
echo "Step 6: Deploying to Kubernetes..."
kubectl apply -f k8s/
echo "✅ Kubernetes resources created"
echo ""

# Wait for deployment
echo "Step 7: Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/demo-app || {
  echo "⚠️  Deployment taking longer than expected"
  echo "Checking pod status..."
  kubectl get pods -l app=demo-app
  echo ""
  echo "Checking events..."
  kubectl get events --sort-by='.lastTimestamp' | tail -n 10
}
echo ""

# Show status
echo "Step 8: Deployment Status"
echo "========================="
kubectl get deployments demo-app
echo ""
kubectl get pods -l app=demo-app
echo ""
kubectl get svc demo-app
echo ""

# Get service URL
echo "Step 9: Accessing the Application"
echo "=================================="
SERVICE_URL=$(minikube service demo-app --url 2>/dev/null)
echo "Service URL: $SERVICE_URL"
echo ""
echo "Test the application:"
echo "  curl $SERVICE_URL"
echo "  curl $SERVICE_URL/health"
echo ""

# Make incident scripts executable
echo "Step 10: Making incident scripts executable..."
chmod +x incidents/*.sh
echo "✅ Scripts ready"
echo ""

echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Test the app: curl $SERVICE_URL"
echo "2. Trigger an incident: ./incidents/trigger-oom.sh"
echo "3. Run AI agent: cd .. && python -m agent.graph"
echo ""
echo "Useful commands:"
echo "  kubectl get pods              # Check pod status"
echo "  kubectl logs <pod-name>       # View pod logs"
echo "  kubectl describe pod <pod>    # Pod details"
echo "  kubectl get events            # Recent events"
echo "  minikube dashboard            # K8s UI dashboard"
echo ""
