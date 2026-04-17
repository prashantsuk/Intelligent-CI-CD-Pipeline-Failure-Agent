# Quick Start Deployment Guide

## 🚀 5-Step Setup (20 minutes)

This guide walks you through deploying the Intelligent CI/CD Pipeline Failure Agent.

### Prerequisites Checklist
- [ ] GitHub account with repository cloned
- [ ] AWS account with IAM permissions
- [ ] Docker Hub account
- [ ] AWS CLI installed and configured
- [ ] Python 3.11+ installed
- [ ] Git installed

---

## Step 1: Setup GitHub Secrets (2 minutes)

### 1.1 Generate Docker Hub Token
1. Go to [Docker Hub Account Settings](https://hub.docker.com/settings/security)
2. Click "New Access Token"
3. Name it: `pipeline-agent`
4. Copy the token

### 1.2 Add GitHub Secrets
Navigate to: **Repository → Settings → Secrets and variables → Actions**

Add these secrets:

| Secret | Value |
|--------|-------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Your Docker Hub access token |
| `SLACK_WEBHOOK_URL` | (Optional) Your Slack webhook URL |

**Using GitHub CLI:**
```bash
gh secret set DOCKER_USERNAME -b "your_username"
gh secret set DOCKER_PASSWORD -b "your_token"
```

---

## Step 2: Setup AWS Infrastructure (5 minutes)

### 2.1 Enable Bedrock Model Access

1. Go to [AWS Bedrock Console](https://console.aws.amazon.com/bedrock/home)
2. Click **"Model access"** in left sidebar
3. Click **"Manage model access"**
4. Find **"Anthropic Claude 3.5 Sonnet"**
5. Click checkbox to enable
6. Accept terms and click **"Save changes"**
7. **Wait 5-10 minutes** for access confirmation

### 2.2 Deploy Infrastructure with Script

```bash
# Clone your repository locally
git clone https://github.com/YOUR_USERNAME/Intelligent-CI-CD-Pipeline-Failure-Agent.git
cd Intelligent-CI-CD-Pipeline-Failure-Agent

# Run the automated deployment script
bash aws/deploy.sh
```

**What the script does:**
- ✅ Creates S3 bucket for logs
- ✅ Creates SNS topic for notifications  
- ✅ Creates IAM role for Lambda
- ✅ Deploys Lambda function
- ✅ Configures all permissions

### 2.3 Confirm SNS Email Subscription

1. Check your email (including spam folder)
2. Look for **"AWS Notification"** with subject **"AWS Notification - Subscription Confirmation"**
3. Click **"Confirm subscription"** link
4. You'll now receive failure notifications

---

## Step 3: Configure Environment (2 minutes)

Update the `.env` file with your values:

```bash
# Copy example
cp .env.example .env

# Edit .env
nano .env
```

Key values to update:
- `DOCKER_USERNAME`: Your Docker Hub username
- `AWS_REGION`: Your AWS region (us-east-1, us-west-2, etc.)
- `SNS_EMAIL_ADDRESS`: Your email for notifications

---

## Step 4: Test Locally (5 minutes)

### 4.1 Setup Local Development

```bash
# Make script executable
chmod +x setup-dev.sh

# Run setup
./setup-dev.sh

# Activate virtual environment
source venv/bin/activate
```

### 4.2 Run Tests

```bash
# Run application tests
pytest test_app.py -v

# Build Docker image locally
docker build -t intelligent-cicd-agent:dev .

# Test the application
docker run -p 5000:5000 intelligent-cicd-agent:dev
```

### 4.3 Test API Endpoints

```bash
# In another terminal
curl http://localhost:5000/
curl http://localhost:5000/api/status
curl http://localhost:5000/api/version

# Test analysis endpoint
curl -X POST http://localhost:5000/api/analyze \
  -H "Content-Type: application/json" \
  -d '{"logs": "test failure logs"}'
```

---

## Step 5: Trigger Your First Pipeline (3 minutes)

### 5.1 Push to GitHub

```bash
# Make sure you're in branch main
git checkout main

# Create a test commit
echo "# Test Pipeline" >> README.md
git add README.md
git commit -m "Test: Trigger CI/CD pipeline"
git push origin main
```

### 5.2 Monitor Pipeline

1. Go to your repository on GitHub
2. Click **"Actions"** tab
3. Click the workflow run to see live logs
4. You should see:
   - ✅ **Test stage**: Running tests
   - ✅ **Build & Push stage**: Building Docker image
   - ✅ **Pushing to Docker Hub**: Uploading image

### 5.3 Check Docker Hub

- Go to [Docker Hub](https://hub.docker.com)
- Login and navigate to your repository
- You should see your image tag (e.g., `main`, `latest`)

---

## 🎉 Success! What's Next?

### Option A: Simulate a Failure Test

```bash
# Edit test_app.py to make a test fail
# Or modify app.py to introduce an error
# Commit and push
# Pipeline will run, fail, and trigger AI analysis
```

### Option B: Setup Slack Integration (Optional)

1. Create Slack webhook:
   - Go to [Slack API](https://api.slack.com/apps)
   - Create "New App"
   - Enable "Incoming Webhooks"
   - Create new webhook for your channel
   - Copy webhook URL

2. Add to GitHub Secrets:
   ```bash
   gh secret set SLACK_WEBHOOK_URL -b "https://hooks.slack.com/services/..."
   ```

---

## Monitor & Troubleshoot

### View Pipeline Logs

```bash
# GitHub Actions logs
gh run list
gh run view RUN_ID --log

# Lambda logs
aws logs tail /aws/lambda/pipeline-failure-analyzer --follow

# S3 failure logs
aws s3 ls s3://pipeline-failure-logs-$(aws sts get-caller-identity --query Account --output text)/failures/
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Pipeline not triggered | Enable GitHub Actions in Settings |
| Docker push fails | Verify Docker credentials are correct |
| Bedrock not responding | Ensure model access is enabled (wait 10 min) |
| No SNS email | Check spam folder, confirm subscription |
| Lambda timeout | Increase timeout in deploy.sh (max 900s) |

### Get Full Logs

For detailed troubleshooting, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 📊 Pipeline Workflow Summary

```
Your Code Push
    ↓
GitHub Actions Workflow Starts
    ├─→ [Test] pytest & code quality checks
    ├─→ [Build] Docker image creation
    ├─→ [Push] Upload to Docker Hub
    └─→ [Notify] GitHub status + Slack
         ↓
    If Pipeline Fails:
         ├─→ Collect logs to S3
         ├─→ Invoke Lambda function
         ├─→ AWS Bedrock AI analyzes
         ├─→ Generate insights & fixes
         └─→ Send SNS notification + GitHub issue
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│               Your GitHub Repository                    │
│         ┌──────────────────────────────────┐            │
│         │   GitHub Actions Workflow        │            │
│         │   - Test app                     │            │
│         │   - Build Docker image           │            │
│         │   - Push to Docker Hub           │            │
│         └──────────────┬───────────────────┘            │
└────────────────────────┼────────────────────────────────┘
                         │
                    On Failure
                         │
                    ┌────▼─────┐
                    │ AWS Lambda│
                    │  Function │
                    └────┬─────┘
                         │
             ┌───────────┼───────────┐
             │           │           │
         ┌───▼──┐   ┌───▼──┐   ┌───▼────┐
         │  S3  │   │Bedrock   │ SNS    │
         │Logs  │   │ Claude   │ Alert  │
         └──────┘   └────────┘ └────────┘
```

---

## Performance Metrics

| Stage | Time | Cost |
|-------|------|------|
| Test | ~30s | Free |
| Build Docker | ~75s | Free |
| Push to Hub | ~45s | Free |
| AI Analysis | ~15-20s | ~$0.003 |
| **Total** | **~3 min** | **~$0.005** |

---

## Next Steps

1. **Read Architecture**: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. **Full Setup Guide**: [SETUP_GUIDE.md](SETUP_GUIDE.md)
3. **Troubleshooting**: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
4. **API Reference**: Check [README.md](README.md)

---

## Support

For help:
1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review AWS CloudWatch logs
3. Create GitHub issue with error details

**Questions?** Check the detailed [SETUP_GUIDE.md](SETUP_GUIDE.md)

---

**Status**: ✅ Ready to Deploy  
**Estimated Setup Time**: ~20 minutes  
**AWS Cost**: ~$55-110/month (based on failure frequency)
