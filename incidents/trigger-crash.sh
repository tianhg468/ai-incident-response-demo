#!/bin/bash
# Trigger crash loop by calling the crash endpoint

echo "🔴 Triggering crash loop incident..."
echo ""

# Get service URL
SERVICE_URL=$(minikube service demo-app --url 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then
  echo "⚠️  Service not accessible via minikube service"
  echo "Using kubectl port-forward instead..."

  # Start port-forward in background
  kubectl port-forward svc/demo-app 8080:80 &
  PF_PID=$!
  sleep 3
  SERVICE_URL="http://localhost:8080"
fi

echo "Service URL: $SERVICE_URL"
echo ""
echo "Step 1: Getting pod names"
PODS=$(kubectl get pods -l app=demo-app -o jsonpath='{.items[*].metadata.name}')

echo "Pods: $PODS"
echo ""
echo "Step 2: Triggering crash on all pods"

for POD in $PODS; do
  echo "Crashing pod: $POD"
  kubectl exec $POD -- wget -qO- --post-data='' http://localhost:3000/crash || true
done

# Kill port-forward if we started it
if [ -n "$PF_PID" ]; then
  kill $PF_PID 2>/dev/null
fi

echo ""
echo "Wait 10 seconds for crashes..."
sleep 10

echo ""
echo "Checking pod status (should see CrashLoopBackOff):"
kubectl get pods -l app=demo-app

echo ""
echo "Checking events:"
kubectl get events --sort-by='.lastTimestamp' | grep -i crash | tail -n 5

echo ""
echo "📊 Incident triggered! Pods should be in CrashLoopBackOff."
echo "Run the AI agent to investigate:"
echo "  cd .. && python -m agent.graph"
