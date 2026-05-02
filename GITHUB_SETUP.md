# Setting Up the GitHub Repository

Follow these steps to create a GitHub repository for the demo application.

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `ai-incident-response-demo`
3. Description: `Demo application for AI incident response testing`
4. **Public** (so you don't need to configure private repo access)
5. **Do NOT** initialize with README (we already have one)
6. Click **"Create repository"**

## Step 2: Get Your GitHub Token

1. Go to https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Name: `AI Incident Response Demo`
4. Expiration: 30 days
5. Select scopes:
   - ✅ `repo` (full control of private repositories)
   - ✅ `workflow` (update GitHub Actions workflows)
6. Click **"Generate token"**
7. **Copy the token** (starts with `ghp_`)

## Step 3: Push Code to GitHub

```bash
# Navigate to demo-app directory
cd demo-app

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial demo application for AI incident response"

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/ai-incident-response-demo.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 4: Verify GitHub Repository

1. Go to `https://github.com/YOUR_USERNAME/ai-incident-response-demo`
2. You should see:
   - ✅ `app.js` - Application code
   - ✅ `Dockerfile` - Container image
   - ✅ `k8s/` - Kubernetes manifests
   - ✅ `.github/workflows/` - GitHub Actions
   - ✅ `incidents/` - Incident trigger scripts

## Step 5: Create Some Commits for Testing

The AI agent needs commit history to analyze. Let's create some:

```bash
# Make a small change (v2)
echo "// Version 2" >> app.js
git add app.js
git commit -m "Update to v2 - add new feature"
git push

# Make another change (v3)
sed -i '' 's/256Mi/128Mi/g' k8s/deployment.yaml
git add k8s/deployment.yaml
git commit -m "Lower memory limits to save resources"
git push

# This last commit simulates the change that causes OOM!
```

## Step 6: Update Main Project .env File

Now update your main AI agent `.env` file:

```bash
# Go back to main project
cd ..

# Edit .env
nano .env
```

Add these lines:

```bash
# Live Mode Configuration
MODE=live

# GitHub (use your actual values)
GITHUB_TOKEN=ghp_your_token_here
GITHUB_ORG=YOUR_GITHUB_USERNAME

# Kubernetes
KUBECONFIG=~/.kube/config
K8S_NAMESPACE=default

# Keep existing settings
ANTHROPIC_API_KEY=sk-ant-...
CHECKPOINT_MODE=sqlite
```

## Step 7: Test the Integration

```bash
# Deploy the app
cd demo-app
./setup.sh

# Trigger an incident
./incidents/trigger-oom.sh

# Run the AI agent (should now read from real GitHub!)
cd ..
python -m agent.graph
```

## What the Agent Will Do

With the GitHub repo configured, the agent will:

1. ✅ **Read real commits** from your GitHub repo
2. ✅ **Check deployment history** to see when limits were lowered
3. ✅ **Correlate OOM with the commit** that changed memory limits
4. ✅ **Propose rollback** to the previous commit/version
5. ✅ **Wait for your approval** before executing
6. ✅ **Execute the fix** if you approve

## Viewing on GitHub

After running the agent, you can:
- View commits: `https://github.com/YOUR_USERNAME/ai-incident-response-demo/commits/main`
- View Actions: `https://github.com/YOUR_USERNAME/ai-incident-response-demo/actions`
- View code: `https://github.com/YOUR_USERNAME/ai-incident-response-demo`

The agent will reference these in its analysis!

## Troubleshooting

**"Permission denied" when pushing:**
```bash
# Use token authentication
git remote set-url origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/ai-incident-response-demo.git
git push
```

**"Repository not found":**
- Check the repository exists at https://github.com/YOUR_USERNAME/ai-incident-response-demo
- Make sure you replaced `YOUR_USERNAME` with your actual username

**Agent can't access GitHub:**
- Verify `GITHUB_TOKEN` in `.env` is correct
- Check token has `repo` scope
- Verify `GITHUB_ORG` matches your username
