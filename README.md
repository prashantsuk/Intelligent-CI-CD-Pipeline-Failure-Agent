# 🤖 Intelligent CI/CD Pipeline Failure Agent

[![CI/CD Pipeline](https://github.com/prashantsuk/Intelligent-CI-CD-Pipeline-Failure-Agent/actions/workflows/ci-cd-pipeline.yml/badge.svg)](https://github.com/prashantsuk/Intelligent-CI-CD-Pipeline-Failure-Agent/actions)
[![Python 3.11](https://img.shields.io/badge/python-3.11-blue.svg)](https://www.python.org/downloads/)
[![Docker Ready](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![AWS Bedrock](https://img.shields.io/badge/AWS-Bedrock-FF9900.svg)](https://aws.amazon.com/bedrock/)

Automatically analyze CI/CD pipeline failures using AI-powered insights from AWS Bedrock and Claude.

## ✨ Features

🚀 **Automated Pipeline**
- Build Docker images on every push
- Push to Docker Hub automatically
- Full test coverage reporting

🤖 **AI-Powered Analysis**
- Uses Claude 3.5 Sonnet via AWS Bedrock
- Identifies root causes (dependencies, tests, config, etc.)
- Suggests actionable fixes with priorities

📊 **Intelligent Insights**
- Categorizes failures automatically
- Suggests prevention strategies
- Tracks failure patterns over time

🔔 **Smart Notifications**
- SNS alerts with detailed analysis
- Slack integration (optional)
- GitHub issues auto-creation on failures

💾 **Comprehensive Logging**
- CloudWatch integration
- S3 backup of failure logs
- 90-day retention policy

## 🏗️ Architecture

```
┌──────────────────┐
│  GitHub Actions  │ ← Code push
│    Workflow      │
└────────┬─────────┘
         │
         ├─→ [Test] ─→ [Build] ─→ [Push to Docker Hub]
         │
         └─→ [Pipeline Fails?]
                │
         ┌──────▼──────────┐
         │  Lambda Function │
         │  (on failure)    │
         └──────┬──────────┘
                │
         ┌──────▼──────────────┐
         │ Amazon Bedrock      │
         │ (Claude Analysis)   │
         └──────┬──────────────┘
                │
         ┌──────▼──────────────┐
         │   Store in S3       │
         │ + SNS Notification  │
         └─────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- GitHub Account
- Docker Hub Account
- AWS Account (with Bedrock access)
- Python 3.11+

### 1️⃣ Clone Repository
```bash
git clone https://github.com/prashantsuk/Intelligent-CI-CD-Pipeline-Failure-Agent.git
cd Intelligent-CI-CD-Pipeline-Failure-Agent
```

### 2️⃣ Configure AWS
```bash
# Enable Bedrock access
aws bedrock update-model-access \
  --region us-east-1 \
  --model-name "Anthropic Claude 3 Sonnet"

# Create S3 bucket for logs
aws s3 mb s3://pipeline-failure-logs-$(aws sts get-caller-identity --query Account --output text)
```

### 3️⃣ Setup GitHub Secrets
```
Settings → Secrets and variables → Actions
├── DOCKER_USERNAME
├── DOCKER_PASSWORD
└── SLACK_WEBHOOK_URL (optional)
```

### 4️⃣ Deploy Lambda
```bash
cd lambda
npm install -g aws-cdk
cdk deploy
```

### 5️⃣ Push to GitHub
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

## 📋 Workflow Stages

### Stage 1: Test
- Install dependencies
- Run pytest with coverage
- Lint with flake8
- Upload coverage reports

### Stage 2: Build & Push
- Build Docker image with multi-stage optimization
- Generate metadata (tags, semver)
- Push to Docker Hub
- Cache layers for faster builds

### Stage 3: On Failure
- Collect failure logs
- Trigger Lambda function
- Save logs to S3
- Create GitHub issue

### Stage 4: AI Analysis (Lambda)
- Parse pipeline logs
- Invoke Bedrock Claude
- Identify root cause
- Generate fix suggestions

### Stage 5: Notify
- Send SNS notification
- Post to Slack
- Update GitHub issue

## 📊 Analysis Output Example

```json
{
  "root_cause": "Package version conflict in dependencies",
  "severity": "High",
  "category": "dependency",
  "suggested_fixes": [
    {
      "fix": "Update package.json to use compatible versions",
      "priority": "P1",
      "estimated_impact": "high"
    },
    {
      "fix": "Clear npm cache and reinstall",
      "priority": "P2",
      "estimated_impact": "medium"
    }
  ],
  "prevention_steps": [
    "Use lock files (package-lock.json)",
    "Add version constraints to dependencies",
    "Run dependency audit in CI"
  ]
}
```

## 🔧 Configuration

### Environment Variables
Create `.env` from `.env.example`:
```bash
cp .env.example .env
# Edit .env with your values
```

Key variables:
- `BEDROCK_MODEL_ID`: Claude model to use
- `FAILURE_LOGS_BUCKET`: S3 bucket for logs
- `SNS_TOPIC_ARN`: SNS topic for notifications
- `DOCKER_USERNAME`: Docker Hub username

### Lambda Settings
- **Timeout**: 300 seconds
- **Memory**: 512 MB
- **Runtime**: Python 3.11
- **Concurrent executions**: 10 (adjustable)

## 📈 Performance Metrics

| Metric | Value |
|--------|-------|
| Test Execution | ~30s |
| Docker Build | ~1m 15s |
| Docker Push | ~45s |
| AI Analysis | ~15-20s |
| Total Pipeline | ~3m |

## 🔐 Security

✅ Non-root Docker user
✅ Secrets in GitHub (not in code)
✅ S3 bucket encryption enabled
✅ IAM roles with least privilege
✅ CloudWatch logging enabled
✅ VPC support ready

## 📚 Documentation

- [Setup Guide](SETUP_GUIDE.md) - Detailed setup instructions
- [Architecture](docs/ARCHITECTURE.md) - System design details
- [API Reference](docs/API.md) - REST endpoints
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## 🐛 Troubleshooting

### Pipeline not triggering?
- Check GitHub Actions is enabled
- Verify workflow file exists at `.github/workflows/ci-cd-pipeline.yml`
- Check branch protection rules

### Docker push failing?
- Verify Docker Hub credentials
- Check rate limiting: `docker info | grep Rate`
- Ensure repository name is lowercase

### Lambda errors?
- Check CloudWatch logs: `aws logs tail /aws/lambda/pipeline-failure-analyzer`
- Verify Bedrock access is enabled
- Check IAM role permissions

### Bedrock not responding?
- Confirm model is enabled in Bedrock console
- Check AWS region configuration
- Verify service quota not exceeded

## 📝 Example Failures Detected

1. **Dependency Issues** ✅
   - Missing packages
   - Version conflicts
   - Registry unavailable

2. **Test Failures** ✅
   - Unit test failures
   - Integration test failures
   - Coverage thresholds

3. **Configuration Errors** ✅
   - Missing environment variables
   - Invalid credentials
   - File system permissions

4. **Build Issues** ✅
   - Compilation errors
   - Docker build failures
   - Resource constraints

5. **Deployment Issues** ✅
   - Docker push failures
   - Registry authentication
   - Network timeouts

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🙋 Support

For questions or issues:
1. Check [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. Review [GitHub Issues](https://github.com/prashantsuk/Intelligent-CI-CD-Pipeline-Failure-Agent/issues)
3. Create new issue with detailed description

## 🎯 Roadmap

- [ ] Auto-apply fixes via GitHub PRs
- [ ] Jira ticket integration
- [ ] Slack workflow integration
- [ ] Custom model fine-tuning
- [ ] Analytics dashboard
- [ ] Failure pattern detection
- [ ] Team notifications
- [ ] Cost tracking

## 📞 Contact

Created with ❤️ for DevOps and Engineering teams

**Author**: Prashant Sukhadeve  
**GitHub**: [@prashantsuk](https://github.com/prashantsuk)

---

**Star ⭐ if helpful!**
