# Demo Application for AI Incident Response

A minimal web application designed to demonstrate the AI Incident Response Engineer in live mode.

## What This Includes

- **Simple Node.js API** - Minimal Express server
- **Kubernetes manifests** - Deployment, Service, ConfigMap
- **GitHub Actions** - Automated deployment pipeline
- **Incident scenarios** - Scripts to trigger realistic incidents
- **Local K8s setup** - Instructions for minikube

## Quick Start

### 1. Prerequisites

```bash
# Install required tools
brew install minikube kubectl docker

# Or on Linux:
# sudo apt-get install docker.io
# curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
# sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### 2. Start Local Kubernetes Cluster

```bash
# Start minikube
minikube start --memory=4096 --cpus=2

# Verify it's running
kubectl get nodes

# Enable metrics server (for resource monitoring)
minikube addons enable metrics-server

# Use minikube's Docker daemon (optional, for building locally)
eval $(minikube docker-env)
```

### 3. Deploy the Application

```bash
# Build the Docker image
docker build -t demo-app:v1 .

# Apply Kubernetes manifests
kubectl apply -f k8s/

# Wait for deployment
kubectl wait --for=condition=available --timeout=60s deployment/demo-app

# Check pods are running
kubectl get pods

# Access the app
minikube service demo-app --url
# Or: kubectl port-forward svc/demo-app 8080:80
# Then visit http://localhost:8080
```

### 4. Trigger an Incident

```bash
# Scenario 1: Trigger OOM (memory limit too low)
./incidents/trigger-oom.sh

# Scenario 2: Trigger crash loop
./incidents/trigger-crash.sh

# Scenario 3: Simulate high error rate
./incidents/trigger-errors.sh
```

### 5. Run the AI Agent (Live Mode)

```bash
# Go back to the main project
cd ..

# Configure for live mode
export MODE=live
export KUBECONFIG=~/.kube/config
export K8S_NAMESPACE=default
export GITHUB_TOKEN=ghp_your_token_here
export GITHUB_ORG=your-github-username

# Run the incident response agent
python -m agent.graph
```

## Application Endpoints

- `GET /` - Health check (returns OK)
- `GET /health` - Detailed health status
- `GET /metrics` - Prometheus-style metrics
- `POST /crash` - Intentionally crash the pod
- `POST /oom` - Trigger out-of-memory
- `POST /errors` - Generate 5xx errors

## Kubernetes Resources

The application deploys:
- **Deployment**: 3 replicas
- **Service**: LoadBalancer type (minikube tunnel)
- **ConfigMap**: Application configuration
- **Resource limits**: 256Mi memory, 200m CPU

## Incident Scenarios

### Scenario 1: OOM After Deploy
1. Deploy with 512Mi memory limit
2. App works fine initially
3. Update deployment to 128Mi (too low)
4. Pods start OOMKilling
5. Agent detects, diagnoses, proposes rollback

### Scenario 2: Crash Loop from Bad Config
1. Deploy with valid config
2. Update ConfigMap with invalid JSON
3. Pods crash on restart
4. Agent detects config issue, proposes fix

### Scenario 3: High Error Rate After Deploy
1. Deploy v1 (stable)
2. Deploy v2 with bug
3. Error rate spikes
4. Agent correlates with deployment, proposes rollback

## GitHub Actions Workflow

The repo includes a CI/CD pipeline:
- **On push to main**: Builds and deploys to "production"
- **On PR**: Runs tests and builds image
- **Manual trigger**: Can deploy specific versions

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/

# Stop minikube
minikube stop

# Delete minikube cluster (optional)
minikube delete
```

## Setting Up GitHub

1. Create a new GitHub repo: `ai-incident-response-demo`
2. Push this code:
   ```bash
   git init
   git add .
   git commit -m "Initial demo app"
   git remote add origin https://github.com/YOUR_USERNAME/ai-incident-response-demo.git
   git push -u origin main
   ```
3. Set up GitHub Actions (already configured in `.github/workflows/`)
4. Add repository secrets for deployment (if needed)

## Integration with AI Agent

The agent will:
1. **Read Kubernetes**: Check pod status, events, logs
2. **Read GitHub**: Analyze commits, PRs, deployment history
3. **Correlate data**: Match incidents with deployments
4. **Propose fixes**: Rollback, scale, config changes
5. **Require approval**: Human review before execution
6. **Execute safely**: Apply fixes to Kubernetes

## Next Steps

1. ✅ Deploy to local Kubernetes
2. ✅ Trigger an incident
3. ✅ Run the AI agent
4. ✅ Observe the investigation
5. ✅ Approve/reject the proposed fix
6. ✅ View results in dashboard

## Troubleshooting

**Minikube won't start:**
```bash
minikube delete
minikube start --driver=docker
```

**Pods stuck in Pending:**
```bash
kubectl describe pod <pod-name>
# Check events section for errors
```

**Can't access service:**
```bash
# Use port-forward instead
kubectl port-forward svc/demo-app 8080:80
```

**Agent can't connect to Kubernetes:**
```bash
# Verify kubeconfig
kubectl config view
kubectl config current-context

# Should be "minikube"
```
# Test
