# Intelligent CI/CD Pipeline Failure Agent - Setup Guide

## Overview

This project implements an AI-powered CI/CD pipeline failure analysis system that:
1. Builds and deploys applications to Docker Hub via GitHub Actions
2. Automatically analyzes pipeline failures using AWS Bedrock (Claude LLM)
3. Identifies root causes and suggests fixes
4. Sends notifications via SNS/Slack

## Architecture

```
Pipeline Fails
     ↓
GitHub Actions (on-failure job)
     ↓
Collects logs & triggers Lambda
     ↓
AWS Lambda Function
     ↓
Amazon Bedrock (Claude)
     ↓
Analyzes & generates insights
     ↓
Stores logs in S3 + SNS notification
     ↓
Engineer receives analysis + fixes
```

## Prerequisites

- GitHub account with repository access
- Docker Hub account
- AWS account with:
  - Bedrock access (Claude model enabled)
  - IAM permissions for Lambda, S3, SNS
  - CloudWatch access
- Python 3.11+
- AWS CLI configured
- Docker installed locally

## Step 1: Prepare GitHub Repository

### 1.1 Create Repository Secrets

Go to your repository Settings → Secrets and variables → Actions, add:

```
DOCKER_USERNAME      = your_docker_hub_username
DOCKER_PASSWORD      = your_docker_Hub_access_token
SLACK_WEBHOOK_URL    = https://hooks.slack.com/services/YOUR/WEBHOOK/URL (optional)
AWS_REGION           = us-east-1 (or your region)
```

**To get Docker Hub access token:**
- Go to Docker Hub → Account Settings → Security → New Access Token

### 1.2 Configure GitHub Actions Secrets

```bash
# Using GitHub CLI (recommended)
gh secret set DOCKER_USERNAME -b "your_username"
gh secret set DOCKER_PASSWORD -b "your_access_token"
```

## Step 2: Set Up AWS Infrastructure

### 2.1 Enable Bedrock Access

1. Go to AWS Console → Bedrock → Model access
2. Click "Manage model access"
3. Enable "Anthropic Claude 3.5 Sonnet"
4. Wait for access approval (may take a few minutes)

### 2.2 Create S3 Bucket for Logs

```bash
aws s3 mb s3://pipeline-failure-logs-$(aws sts get-caller-identity --query Account --output text) \
  --region us-east-1
```

### 2.3 Create SNS Topic for Notifications

```bash
aws sns create-topic \
  --name pipeline-failure-notifications \
  --region us-east-1

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:YOUR_ACCOUNT_ID:pipeline-failure-notifications \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### 2.4 Deploy CloudFormation Stack

```bash
# Deploy the infrastructure
aws cloudformation create-stack \
  --stack-name pipeline-failure-agent \
  --template-body file://aws/cloudformation-template.json \
  --parameters ParameterKey=SNSEmailAddress,ParameterValue=your-email@example.com \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# Monitor deployment
aws cloudformation describe-stacks \
  --stack-name pipeline-failure-agent \
  --region us-east-1
```

## Step 3: Deploy Lambda Function

### 3.1 Create Lambda Function

```bash
# Navigate to lambda directory
cd lambda

# Create deployment package
pip install -r ../requirements.txt -t ./package
cp pipeline_failure_analyzer.py ./package/

# Create ZIP file
cd package
zip -r ../lambda_function.zip .
cd ..

# Create Lambda function
aws lambda create-function \
  --function-name pipeline-failure-analyzer \
  --runtime python3.11 \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/pipeline-failure-agent-LambdaExecutionRole \
  --handler pipeline_failure_analyzer.lambda_handler \
  --zip-file fileb://lambda_function.zip \
  --timeout 300 \
  --memory-size 512 \
  --environment Variables="{BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0,FAILURE_LOGS_BUCKET=pipeline-failure-logs-YOUR_ACCOUNT_ID,SNS_TOPIC_ARN=arn:aws:sns:us-east-1:YOUR_ACCOUNT_ID:pipeline-failure-notifications}" \
  --region us-east-1
```

### 3.2 Set Lambda Permissions

```bash
# Allow GitHub Actions to invoke Lambda
aws lambda add-permission \
  --function-name pipeline-failure-analyzer \
  --statement-id AllowGitHubActions \
  --action lambda:InvokeFunction \
  --principal lambda.amazonaws.com \
  --region us-east-1
```

## Step 4: Local Testing

### 4.1 Test the Application

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
pytest test_app.py -v --cov=app

# Run application locally
python app.py
# Visit http://localhost:5000
```

### 4.2 Test Docker Build Locally

```bash
# Build image
docker build -t intelligent-cicd-agent:latest .

# Run container
docker run -p 5000:5000 intelligent-cicd-agent:latest

# Test endpoints
curl http://localhost:5000/
curl http://localhost:5000/api/status
curl http://localhost:5000/api/version
```

### 4.3 Test Lambda Function Locally

```bash
# Using AWS SAM (optional)
sam local invoke pipeline-failure-analyzer \
  --event lambda/test_event.json

# Or test directly with Python
cd lambda
python pipeline_failure_analyzer.py
```

## Step 5: Push to GitHub & Trigger Pipeline

### 5.1 Initialize Git Repository

```bash
cd Intelligent-CI-CD-Pipeline-Failure-Agent

git init
git add .
git commit -m "Initial commit: Intelligent CI/CD Pipeline Failure Agent"

git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/Intelligent-CI-CD-Pipeline-Failure-Agent.git
git push -u origin main
```

### 5.2 Trigger the CI/CD Pipeline

The workflow will automatically trigger on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

Pipeline stages:
1. **Test**: Runs pytest, generates coverage report
2. **Build & Push**: Builds Docker image, pushes to Docker Hub
3. **On Failure**: Collects logs, triggers Lambda analysis
4. **Notify**: Sends Slack/SNS notifications

## Step 6: Monitor & Troubleshoot

### 6.1 Check GitHub Actions Logs

```bash
# View workflow runs
gh run list --repo YOUR_USERNAME/Intelligent-CI-CD-Pipeline-Failure-Agent

# View specific run
gh run view RUN_ID --repo YOUR_USERNAME/Intelligent-CI-CD-Pipeline-Failure-Agent
```

### 6.2 Check Lambda Logs

```bash
# View Lambda logs
aws logs tail /aws/lambda/pipeline-failure-analyzer --follow --region us-east-1
```

### 6.3 Check S3 Failure Logs

```bash
aws s3 ls s3://pipeline-failure-logs-YOUR_ACCOUNT_ID/failures/
aws s3 cp s3://pipeline-failure-logs-YOUR_ACCOUNT_ID/failures/RUN_ID/logs-*.txt - | head -100
```

## Common Issues & Fixes

### Issue: "Bedrock access denied"
- Solution: Ensure Bedrock access is enabled for your region and model

### Issue: "Docker push failed"
- Solution: Verify DOCKER_USERNAME and DOCKER_PASSWORD secrets are correct
- Check Docker Hub rate limits

### Issue: "Lambda execution role not found"
- Solution: Ensure CloudFormation stack was deployed successfully
- Check IAM role exists and has correct permissions

### Issue: "SNS email not received"
- Solution: Check email subscription in SNS (may be pending confirmation)
- Verify SNS topic ARN is correct in Lambda environment variables

## Performance Optimization

### 1. Cache Layer
- Lambda caches Bedrock responses for identical logs
- S3 stores historical analyses for pattern recognition

### 2. Parallel Processing
- Multiple workflow steps run in parallel
- Lambda processes logs asynchronously

### 3. Cost Optimization
- S3 lifecycle policy: Delete logs after 90 days
- Lambda timeout: Adjusted for analysis complexity
- Bedrock: Uses efficient model selection

## Security Best Practices

✅ **Implemented:**
- GitHub Secrets for credentials
- AWS IAM roles with least privilege
- S3 bucket encryption and versioning
- Non-root Docker user
- Environment-based configuration

## Next Steps

1. **Add webhook integration**: Direct GitHub → Lambda invocation
2. **Implement auto-fix**: Automatically create PRs with suggested fixes
3. **Integrate with Jira**: Create tickets for tracked issues
4. **Add dashboard**: CloudWatch dashboard for failure analytics
5. **Custom models**: Fine-tune Bedrock with your organization's best practices

## Support & Contributing

For issues or improvements, please open a GitHub issue in your repository.

## License

MIT License - See LICENSE file for details
