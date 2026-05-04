#!/bin/bash
# Trigger OOM incident by lowering memory limits

echo "🔴 Triggering OOM incident..."
echo ""
echo "Step 1: Lowering memory limit and request to 64Mi (too low for the app)"

# Update deployment with lower memory limit AND request
kubectl patch deployment demo-app --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/resources/limits/memory",
    "value": "64Mi"
  },
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/resources/requests/memory",
    "value": "64Mi"
  }
]'

echo "✅ Deployment updated with memory limit and request: 64Mi"
echo ""
echo "Wait 30 seconds for pods to restart..."
sleep 30

echo ""
echo "Checking pod status:"
kubectl get pods -l app=demo-app

echo ""
echo "Checking events (should see OOMKilled):"
kubectl get events --sort-by='.lastTimestamp' | grep -i oom | tail -n 5

echo ""
echo "📊 Incident triggered! Pods should be OOMKilling."
echo "Run the AI agent to investigate and fix:"
echo "  cd .. && python -m agent.graph"
