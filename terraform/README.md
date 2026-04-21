# Terraform - CI/CD Pipeline Failure Agent

Complete Infrastructure-as-Code (IaC) setup using Terraform to automate AWS infrastructure deployment.

## Quick Start

### 1. Prerequisites
```bash
# Install required tools
- Terraform >= 1.0
- AWS CLI >= 2.0
- Git
- Bash

# Verify installations
terraform version
aws --version
```

### 2. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your preferred region (e.g., us-east-1)
```

### 3. Setup Terraform (Automated)
```bash
# Make setup script executable
chmod +x setup-terraform.sh

# Run automated setup
./setup-terraform.sh
```

This script will:
- ✅ Verify all prerequisites
- ✅ Check AWS credentials
- ✅ Initialize Terraform
- ✅ Validate configuration
- ✅ Show what will be created (plan)
- ✅ Create all AWS resources
- ✅ Display outputs

### 4. Manual Setup (Alternative)
If you prefer to run commands manually:

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars  # Update sns_email_address and other values

# Plan deployment
terraform plan -out=tfplan

# Apply configuration
terraform apply tfplan
```

## Configuration

### terraform.tfvars
Edit `terraform.tfvars` to customize your deployment:

```hcl
# AWS Configuration
aws_region  = "us-east-1"              # Your preferred AWS region
environment = "prod"                   # dev, staging, or prod

# S3 Configuration
failure_logs_bucket_name = "pipeline-failure-logs"

# SNS Configuration (REQUIRED)
sns_topic_name    = "pipeline-failure-notifications"
sns_email_address = "your-email@example.com"  # CHANGE THIS!

# Lambda Configuration
lambda_function_name = "pipeline-failure-analyzer"
lambda_timeout       = 300              # seconds
lambda_memory_size   = 512              # MB

# Bedrock Configuration
bedrock_model_id              = "anthropic.claude-3-5-sonnet-20241022-v2:0"
enable_bedrock_model_access   = true

# CloudWatch Configuration
log_retention_days = 30

# Additional Tags
tags = {
  Owner       = "DevOps Team"
  Project     = "CI-CD Pipeline Automation"
  Environment = "Production"
}
```

## What Gets Created

```
AWS Account
├── S3 Bucket
│   ├── Name: pipeline-failure-logs-{ACCOUNT_ID}
│   ├── Versioning: Enabled
│   ├── Lifecycle: Auto-delete after 90 days
│   ├── Glacier transition: After 30 days
│   └── Encryption: AES256
│
├── SNS Topic
│   ├── Name: pipeline-failure-notifications
│   ├── Email subscription: {your-email}
│   ├── Permissions for Lambda, CloudWatch Logs
│   └── Auto-confirm subscription via email
│
├── CloudWatch Log Group
│   ├── Name: /aws/lambda/pipeline-failure-analyzer
│   ├── Retention: 30 days
│   └── IAM permissions configured
│
└── IAM Role (for Lambda)
    ├── Assume role: Lambda service
    ├── Policies:
    │   ├── CloudWatch Logs
    │   ├── Bedrock Invoke
    │   ├── S3 Read/Write
    │   ├── SNS Publish
    │   └── Secrets Manager Read
    └── Total: 5 inline policies
```

## Key Features

### 🔒 Security
- S3 bucket with public access blocked
- Versioning enabled for compliance
- Encryption enabled by default
- Least-privilege IAM policies
- Secrets Manager integration for GitHub tokens

### 💰 Cost Optimization
- Automatic log deletion after 90 days
- Glacier transition after 30 days
- Configurable retention periods
- Estimated cost: ~$0-5/month (depends on usage)

### 📊 Monitoring
- CloudWatch logs for all Lambda invocations
- SNS email notifications for failures
- S3 versioning for audit trail
- CloudFormation tags for cost allocation

### 🔄 Flexibility
- Parameterized variables for easy customization
- Support for multiple environments (dev/staging/prod)
- Optional Bedrock model access automation
- Tag-based resource management

## Terraform Commands

### View Current State
```bash
# Show all outputs
terraform output

# Show specific output
terraform output s3_bucket_name

# Show current infrastructure (plan)
terraform plan
```

### Update Infrastructure
```bash
# Update variables
nano terraform.tfvars

# Apply changes
terraform plan -out=tfplan
terraform apply tfplan
```

### Destroy Infrastructure
```bash
# WARNING: This will delete all AWS resources created by Terraform
terraform plan -destroy -out=tfplan-destroy
terraform apply tfplan-destroy
```

### State Management
```bash
# List resources in state
terraform state list

# Show resource details
terraform state show aws_s3_bucket.failure_logs

# Backup state
cp terraform.tfstate terraform.tfstate.backup
```

## Environment-Specific Deployment

### Development
```bash
# Create dev tfvars
cp terraform.tfvars.example terraform.dev.tfvars
# Edit to use dev settings

# Deploy to dev
terraform plan -var-file="terraform.dev.tfvars" -out=tfplan-dev
terraform apply tfplan-dev
```

### Production
```bash
# Create prod tfvars (already used by default)
terraform plan -out=tfplan-prod
terraform apply tfplan-prod
```

## Troubleshooting

### Terraform Initialization Fails
```bash
# Clear local cache
rm -rf .terraform/
rm -f .terraform.lock.hcl

# Retry initialization
terraform init -upgrade
```

### AWS Credentials Error
```bash
# Verify credentials are configured
aws sts get-caller-identity

# Configure if needed
aws configure

# Use specific profile
export AWS_PROFILE=myprofile
terraform init
```

### S3 Bucket Name Conflict
S3 bucket names are globally unique. If you get an error:
1. Edit `terraform.tfvars`
2. Change `failure_logs_bucket_name` to something unique
3. Reapply: `terraform apply`

### SNS Email Not Received
```bash
# Check spam folder first

# Resend subscription confirmation
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[?Protocol==`email`]'

# If stuck as "PendingConfirmation", delete and recreate SNS in AWS Console
```

### Bedrock Model Access Not Working
```bash
# Check if model is accessible
aws bedrock list-foundation-models \
  --region us-east-1 \
  --query 'modelSummaries[?modelId==`anthropic.claude-3-5-sonnet-20241022-v2:0`]'

# If not available, manually enable in AWS Console
# See: bedrock.tf for manual instructions
```

## File Structure

```
terraform/
├── main.tf                    # Main infrastructure resources
├── variables.tf              # Input variable definitions
├── outputs.tf                # Output values
├── bedrock.tf                # Bedrock configuration
├── terraform.tfvars.example  # Example variable values
├── terraform.tfvars          # Actual values (git-ignored)
├── .gitignore                # Git ignore rules
├── scripts/
│   └── enable-bedrock-access.sh   # Bedrock setup helper
├── setup-terraform.sh        # Automated setup script
└── README.md                 # This file
```

## Next Steps

1. **Deploy Infrastructure**
   ```bash
   ./setup-terraform.sh
   ```

2. **Confirm SNS Subscription**
   - Check your email for AWS notification
   - Click confirmation link

3. **Deploy Lambda Function**
   ```bash
   # Use the deploy script
   bash ../aws/deploy.sh
   ```

4. **Configure GitHub Actions**
   - Add Docker Hub credentials to GitHub Secrets
   - Update workflow files if needed

5. **Test Pipeline**
   ```bash
   # Push code to GitHub
   git add .
   git commit -m "Test: First pipeline"
   git push
   ```

## Cost Estimation

| Service | Monthly Cost | Notes |
|---------|----------|-------|
| S3 | $0.50 | ~5 GB stored |
| SNS | $0.05 | ~50 notifications |
| Lambda | $0.20 | ~1000 invocations |
| CloudWatch Logs | $0.50 | ~10 GB ingested |
| **Total** | **~$1.25** | Very economical! |

## Terraform Best Practices

✅ **Do:**
- Store `terraform.tfvars` locally (git-ignored)
- Use descriptive resource names
- Tag all resources for cost tracking
- Backup `terraform.tfstate` regularly
- Use `terraform plan` before `apply`
- Document changes in git commits

❌ **Don't:**
- Manually modify AWS resources (use Terraform)
- Store credentials in code
- Use `terraform destroy` in production lightly
- Share tfstate file in git
- Change variable names without careful planning

## Advanced Features

### Remote State Management
```bash
# Uncomment in main.tf to use S3 backend
# This keeps state in S3 instead of local file
```

### Import Existing Resources
```bash
# If you already have AWS resources, import them:
terraform import aws_s3_bucket.failure_logs bucket-name
```

### Multiple AWS Accounts
```bash
# Use different providers for different accounts
provider "aws" {
  alias  = "account-b"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  }
}
```

## Support

For detailed troubleshooting, see:
- AWS CloudFormation vs Terraform comparison: See `TERRAFORM_VS_CLOUDFORMATION.md`
- Lambda deployment: See `../SETUP_GUIDE.md`
- Full architecture: See `../docs/ARCHITECTURE.md`

## License

Same as parent project

---

**Status**: ✅ Ready to Use  
**Last Updated**: 2024  
**Terraform Version**: >= 1.0  
**AWS Provider Version**: >= 5.0
