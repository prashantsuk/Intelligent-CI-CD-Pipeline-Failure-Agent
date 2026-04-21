# 🚀 Terraform Deployment Quick Start

## Option A: Fully Automated Setup (Recommended)

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Make setup script executable
chmod +x setup-terraform.sh

# 3. Run automated setup
./setup-terraform.sh
```

**What happens:**
- ✅ Checks all prerequisites (Terraform, AWS CLI, Git)
- ✅ Verifies AWS credentials
- ✅ Initializes Terraform
- ✅ Validates configuration
- ✅ Prompts for sns_email_address if not set
- ✅ Shows what will be created
- ✅ Creates all AWS resources
- ✅ Displays outputs and next steps

---

## Option B: Manual Setup (Step-by-Step)

### Step 1: Prerequisites
```bash
# Install Terraform
# macOS
brew install terraform

# Windows
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip -d /usr/local/bin/

# Verify
terraform version
```

### Step 2: Configure AWS
```bash
# Configure AWS credentials
aws configure

# Verify credentials
aws sts get-caller-identity
```

### Step 3: Initialize Terraform
```bash
# Navigate to terraform directory
cd terraform

# Initialize
terraform init

# Validate configuration
terraform validate
```

### Step 4: Configure Variables
```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars

# Key changes:
# - sns_email_address = "your-email@example.com"
# - aws_region = "us-east-1"  (or your preferred region)
```

### Step 5: Review Plan
```bash
# Show what will be created
terraform plan -out=tfplan
```

### Step 6: Apply Configuration
```bash
# Apply the plan
terraform apply tfplan
```

---

## Option C: Using Terraform Helper Script

```bash
# Navigate to terraform directory
cd terraform

# Make script executable
chmod +x terraform.sh

# Available commands
./terraform.sh init       # Initialize
./terraform.sh validate   # Validate
./terraform.sh plan       # Show plan
./terraform.sh apply      # Apply
./terraform.sh output     # Show outputs
./terraform.sh destroy    # Delete resources
./terraform.sh help       # Show all commands
```

---

## Verification Steps

### 1. Check Terraform Initialized
```bash
# Should show Terraform initialized
ls -la .terraform/
terraform --version
```

### 2. Verify AWS Resources Created
```bash
# Show all resources
terraform state list

# S3 bucket created?
aws s3 ls | grep pipeline-failure-logs

# SNS topic created?
aws sns list-topics --query 'Topics[?contains(TopicArn, `pipeline-failure`)]'

# IAM role created?
aws iam get-role --role-name pipeline-failure-analyzer-role
```

### 3. Confirm SNS Subscription
```bash
# Check subscription status
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[].SubscriptionArn'

# Should show: arn:aws:sns:region:account:topic-name:subscription-id
# If shows "PendingConfirmation", check your email
```

### 4. View Terraform Outputs
```bash
# Show all outputs
terraform output

# Show specific output
terraform output s3_bucket_name
terraform output sns_topic_arn
terraform output lambda_role_arn
```

---

## 📝 Next Steps After Deployment

### 1. **Confirm SNS Email**
- Check your email for AWS notification
- Click "Confirm subscription" link
- You'll now receive failure alerts

### 2. **Enable Bedrock Model Access**
```bash
# Check if already enabled
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelId==`anthropic.claude-3-5-sonnet-20241022-v2:0`]'

# If not accessible, manually enable:
# 1. Go to https://console.aws.amazon.com/bedrock/home
# 2. Click "Model access" (left sidebar)
# 3. Click "Manage model access"
# 4. Find "Anthropic Claude 3.5 Sonnet"
# 5. Check box and save
# 6. Wait 5-10 minutes
```

### 3. **Deploy Lambda Function**
```bash
# Navigate to aws directory
cd ../aws

# Deploy Lambda
bash deploy.sh
```

### 4. **Configure GitHub Actions**
- Add Docker Hub credentials to GitHub Secrets
- Add Slack webhook (optional)
- Push code to trigger first pipeline

### 5. **Test the Pipeline**
```bash
# Make a small change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "Test: Trigger pipeline"
git push origin main

# Watch pipeline in GitHub Actions tab
```

---

## 🔧 Common Commands

### View Infrastructure
```bash
# Show all resources
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.failure_logs

# Export state
terraform state pull > backup.json
```

### Update Infrastructure
```bash
# Edit variables
nano terraform.tfvars

# Apply changes
terraform plan -out=tfplan
terraform apply tfplan
```

### Troubleshooting
```bash
# Validate configuration
terraform validate

# Format files
terraform fmt -recursive

# Show detailed logs
TF_LOG=DEBUG terraform plan

# Check what Terraform will do
terraform plan -json
```

---

## ⚙️ Environment Variables

```bash
# Use specific AWS profile
export AWS_PROFILE=myprofile

# Enable debug logging
export TF_LOG=DEBUG

# Use specific variables file
export TF_VAR_environment=prod
export TF_VAR_aws_region=us-east-1
```

---

## 🗑️ Cleanup

### Destroy Individual Resources
```bash
# Remove specific resource
terraform destroy -target aws_s3_bucket.failure_logs

# Confirm when prompted
```

### Destroy Everything
```bash
# ⚠️ WARNING: This deletes all AWS resources created by Terraform

terraform plan -destroy  # Review first
terraform apply -destroy # Confirm when prompted
```

---

## 📊 Cost Estimation

**Monthly AWS Cost** (with typical usage):

| Service | Amount | Cost |
|---------|--------|------|
| S3 Storage | 5 GB | $0.50 |
| SNS Emails | 50 alerts | $0.05 |
| Lambda | 1,000 invocations | $0.20 |
| CloudWatch Logs | 10 GB | $0.50 |
| **Total** | | **~$1.25/month** |

Very economical! 💰

---

## 🆘 Troubleshooting

### "Terraform not found"
```bash
# Install Terraform first
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads
```

### "AWS credentials not configured"
```bash
# Configure AWS
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### "terraform.tfvars not found"
```bash
# Create from example
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values
```

### "S3 bucket name already exists"
```bash
# S3 names are globally unique
# Edit terraform.tfvars:
failure_logs_bucket_name = "pipeline-failure-logs-mycompany-123"

# Re-apply
terraform apply
```

### "SNS email not received"
```bash
# Check spam folder first

# Check subscription status
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# If PendingConfirmation, email may have been lost
# Resubscribe in AWS Console or create new subscription
```

---

## 📚 More Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/extend/best-practices.html)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/)
- [CI/CD Pipeline Failure Agent README](../README.md)
- [Full Setup Guide](../SETUP_GUIDE.md)

---

**Ready?** Run `./setup-terraform.sh` to deploy! 🚀
