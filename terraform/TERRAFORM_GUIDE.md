# Terraform Infrastructure Setup - Complete Guide

## 📋 What's Included

This Terraform configuration automates **all AWS infrastructure** for the Intelligent CI/CD Pipeline Failure Agent.

### ✅ Automated Resources

```
✓ S3 Bucket           - For storing failure logs
✓ SNS Topic           - For email notifications
✓ CloudWatch Logs     - For Lambda function logs
✓ IAM Roles & Policies - For Lambda execution permissions
✓ Bedrock Permissions - Claude 3.5 Sonnet access (setup guide)
```

### ⏱️ Deployment Time
- **Fully Automated**: ~5 minutes
- **Manual Setup**: ~10 minutes

### 💰 Monthly Cost
**~$1-2/month** (extremely economical!)

---

## 🚀 Quick Start (60 seconds)

### Prerequisites
```bash
# Install these first
- Terraform >= 1.0
- AWS CLI >= 2.0
- AWS Account with permissions
```

### Deploy in 3 Steps
```bash
# Step 1: Navigate to terraform folder
cd terraform

# Step 2: Configure AWS email
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Change sns_email_address to YOUR email

# Step 3: Deploy
bash setup-terraform.sh
```

**Done!** ✅ All AWS infrastructure created.

---

## 📚 File Guide

### Core Terraform Files
| File | Purpose |
|------|---------|
| `main.tf` | Main infrastructure (S3, SNS, IAM, CloudWatch) |
| `variables.tf` | Input variables with validation |
| `outputs.tf` | Output values (IDs, ARNs, etc.) |
| `bedrock.tf` | Bedrock model access configuration |

### Configuration Files
| File | Purpose |
|------|---------|
| `terraform.tfvars.example` | Example values (copy & edit) |
| `terraform.tfvars` | Your actual values (git-ignored) |
| `.gitignore` | Protects sensitive data |

### Scripts
| File | Purpose |
|------|---------|
| `setup-terraform.sh` | Automated full setup |
| `terraform.sh` | Helper for common commands |
| `scripts/enable-bedrock-access.sh` | Bedrock setup helper |

### Documentation
| File | Purpose |
|------|---------|
| `README.md` | Detailed Terraform guide |
| `DEPLOYMENT.md` | Step-by-step deployment |
| `TERRAFORM_VS_CLOUDFORMATION.md` | Why Terraform? |

---

## 🛠️ Setup Methods

### Method 1: Fully Automated (Easiest) ⭐
```bash
cd terraform
bash setup-terraform.sh
```
- Checks prerequisites
- Validates configuration
- Shows plan
- Applies automatically
- **Best for**: Everyone

### Method 2: Helper Script
```bash
cd terraform
chmod +x terraform.sh
./terraform.sh setup      # Full setup
./terraform.sh plan       # Preview changes
./terraform.sh apply      # Apply changes
./terraform.sh destroy    # Delete resources
```
**Best for**: Quick commands

### Method 3: Manual (Most Control)
```bash
cd terraform
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```
**Best for**: Advanced users

---

## 📝 Configuration

### Edit terraform.tfvars

```hcl
# AWS Configuration
aws_region  = "us-east-1"              # Your region

# SNS Email (REQUIRED - Change this!)
sns_email_address = "your-email@example.com"

# Lambda Settings
lambda_timeout     = 300               # 5 minutes
lambda_memory_size = 512               # 512 MB

# Bedrock Model
bedrock_model_id = "anthropic.claude-3-5-sonnet-20241022-v2:0"

# Optional: Custom Tags
tags = {
  Owner      = "DevOps Team"
  Project    = "CI-CD Pipeline"
  Environment = "Production"
}
```

### All Available Variables

```hcl
aws_region                 = "us-east-1"                    # AWS region
environment                = "prod"                          # dev/staging/prod
failure_logs_bucket_name   = "pipeline-failure-logs"        # S3 bucket prefix
sns_topic_name             = "pipeline-failure-notifications" # SNS topic name
sns_email_address          = "your-email@example.com"       # YOUR EMAIL HERE
lambda_function_name       = "pipeline-failure-analyzer"    # Lambda name
lambda_timeout             = 300                             # seconds
lambda_memory_size         = 512                             # MB
bedrock_model_id           = "anthropic.claude-3-5-sonnet-20241022-v2:0"
enable_bedrock_model_access = true                           # Auto-enable model
log_retention_days         = 30                              # CloudWatch retention
tags                       = {}                              # Custom tags
```

---

## 📊 Infrastructure Overview

```
AWS Account
│
├─ S3 Bucket: pipeline-failure-logs-{ACCOUNT_ID}
│  ├─ Versioning: Enabled
│  ├─ Auto-delete: 90 days
│  ├─ Glacier: 30 days
│  └─ Encryption: AES256
│
├─ SNS Topic: pipeline-failure-notifications
│  ├─ Email subscriptions
│  ├─ Lambda permissions
│  └─ CloudWatch Logs permissions
│
├─ CloudWatch Logs: /aws/lambda/pipeline-failure-analyzer
│  ├─ Retention: 30 days
│  └─ IAM permissions configured
│
└─ IAM Role: pipeline-failure-analyzer-role
   ├─ CloudWatch Logs access
   ├─ Bedrock InvokeModel
   ├─ S3 read/write
   ├─ SNS publish
   └─ Secrets Manager read
```

---

## ✅ Verification Checklist

After running `setup-terraform.sh`, verify:

- [ ] All prerequisites installed (`terraform version`, `aws --version`)
- [ ] AWS credentials working (`aws sts get-caller-identity`)
- [ ] Terraform initialized (`ls .terraform/`)
- [ ] Configuration valid (`terraform validate` passes)
- [ ] S3 bucket created (`aws s3 ls | grep pipeline`)
- [ ] SNS topic created (`aws sns list-topics`)
- [ ] IAM role created (`aws iam get-role --role-name ...`)
- [ ] SNS email subscription confirmed (check inbox)
- [ ] Outputs displayed (`terraform output`)

---

## 🔄 Common Operations

### View What Will Be Created
```bash
cd terraform
terraform plan
# Review the output, then:
terraform apply tfplan
```

### Check Current State
```bash
terraform state list          # All resources
terraform state show aws_s3_bucket.failure_logs  # Specific resource
terraform output              # All outputs
```

### Update Configuration
```bash
# Edit variables
nano terraform.tfvars

# Apply changes
terraform plan -out=tfplan
terraform apply tfplan
```

### Add New Resources
```hcl
# In main.tf, add new resource:
resource "aws_cloudwatch_alarm" "lambda_errors" {
  # ... configuration
}

# Apply
terraform plan -out=tfplan
terraform apply tfplan
```

### Remove Resources
```bash
# Option 1: Remove from tfvars and reapply
terraform apply

# Option 2: Destroy specific resource
terraform destroy -target aws_sns_topic.pipeline_failures

# Option 3: Destroy everything
terraform destroy
```

---

## 🐛 Troubleshooting

### "Terraform command not found"
```bash
# macOS: install via Homebrew
brew install terraform

# Windows: download from hashicorp.com or use chocolatey
choco install terraform

# Linux: download and add to PATH
```

### "AWS credentials not configured"
```bash
# Configure credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
```

### "terraform.tfvars not found"
```bash
# Create from example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### "S3 bucket name already exists"
S3 bucket names are **globally unique**. Edit `terraform.tfvars`:
```hcl
# Add unique suffix
failure_logs_bucket_name = "pipeline-failure-logs-mycompany-2024"
```

### "SNS email not received"
```bash
# Check spam folder first

# List subscriptions
aws sns list-subscriptions

# If stuck on "PendingConfirmation", delete and recreate
```

### "terraform plan hangs"
```bash
# Cancel with Ctrl+C
# Try with debug logging
TF_LOG=DEBUG terraform plan

# Check AWS API rate limits
aws sts get-caller-identity --debug
```

### Full Debug Mode
```bash
# Enable maximum logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run command
terraform plan

# Check logs
tail -f terraform.log
```

---

## 📚 Learning Path

1. **Start Here**: [DEPLOYMENT.md](DEPLOYMENT.md) - Quick start guide
2. **Understand**: [README.md](README.md) - Detailed explanation
3. **Decide**: [TERRAFORM_VS_CLOUDFORMATION.md](TERRAFORM_VS_CLOUDFORMATION.md) - Why Terraform?
4. **Learn More**: 
   - [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
   - [Terraform Best Practices](https://learn.hashicorp.com/collections/terraform/best-practices)

---

## 🎯 Next Steps After Deployment

### 1. Confirm SNS Subscription
- Check your email for AWS notification
- Click confirmation link
- ✅ You'll now receive failure alerts

### 2. Enable Bedrock Model Access
```bash
# Verify model access
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelId==`anthropic.claude-3-5-sonnet-20241022-v2:0`]'

# If not accessible, manually enable in AWS Console
```

### 3. Deploy Lambda Function
```bash
cd ../aws
bash deploy.sh
```

### 4. Setup GitHub Actions
- Add Docker Hub credentials as GitHub Secrets
- Configure webhook (optional: Slack)
- Push code to trigger first pipeline

### 5. Monitor Pipeline
- Go to GitHub Actions tab
- Watch your first pipeline run
- Verify Docker image pushed to Docker Hub

---

## 📊 Architecture

```
GitHub Push
    ↓
GitHub Actions Workflow
    ├─ Test Code
    ├─ Build Docker Image
    ├─ Push to Docker Hub
    └─ On Failure:
        ├─ Collect Logs
        ├─ Invoke Lambda
        ├─ Bedrock Analysis (Claude 3.5 Sonnet)
        ├─ Generate Insights
        └─ Send SNS Email Alert
```

---

## 💡 Pro Tips

### Tip 1: Use Workspaces for Multiple Environments
```bash
terraform workspace new dev
terraform workspace new prod
terraform select dev
# Deploy to dev
```

### Tip 2: Automate with GitHub Actions
```yaml
# .github/workflows/terraform.yml
on: [push]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1
      - run: terraform plan
      - run: terraform apply -auto-approve
```

### Tip 3: Remote State Management
Store state in S3 for team collaboration:
```bash
# Uncomment in main.tf
# backend "s3" {
#   bucket = "terraform-state"
#   key    = "cicd-agent/tfstate"
# }
```

### Tip 4: Cost Estimation
```bash
# Estimate costs before applying
terraform plan -json | grep -o '"cost":"[^"]*'

# Or use https://infracost.io/
```

---

## 🔒 Security Best Practices

- ✅ Never commit `terraform.tfvars` (it's in .gitignore)
- ✅ Never commit `terraform.tfstate` (contains sensitive data)
- ✅ Use AWS IAM roles instead of access keys
- ✅ Enable MFA on AWS account
- ✅ Review `terraform plan` before applying
- ✅ Use Terraform Enterprise/Cloud for remote state (optional)
- ✅ Regularly audit AWS resources created by Terraform

---

## 📞 Support

**Having issues?** Follow this order:

1. Check [DEPLOYMENT.md](DEPLOYMENT.md) - Quick reference
2. Read [README.md](README.md) - Detailed explanations
3. See Troubleshooting section above
4. Check AWS CloudWatch logs
5. Review Terraform logs: `export TF_LOG=DEBUG`
6. Create GitHub issue with full error details

---

## 📄 File Summary

```
terraform/
├── main.tf                    # Core infrastructure
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── bedrock.tf                # Bedrock configuration
├── terraform.tfvars          # Your configuration (git-ignored)
├── terraform.tfvars.example  # Example template
├── .gitignore                # Git ignore rules
├── setup-terraform.sh        # Automated setup ⭐ START HERE
├── terraform.sh              # Helper commands
├── scripts/
│   └── enable-bedrock-access.sh
├── README.md                 # Detailed guide
├── DEPLOYMENT.md             # Step-by-step setup
├── TERRAFORM_VS_CLOUDFORMATION.md # Why Terraform?
└── TERRAFORM_GUIDE.md        # This file
```

---

## 🎉 You're Ready!

```bash
cd terraform
bash setup-terraform.sh
```

**And you're done!** AWS infrastructure automatically deployed. 🚀

---

**Status**: ✅ Complete and Ready  
**Last Updated**: 2024  
**AWS Provider**: 5.0+  
**Terraform**: 1.0+
