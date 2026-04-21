##############################################################################
# Main Terraform Configuration for CI/CD Pipeline Failure Agent
# Automates AWS infrastructure deployment
##############################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "cicd-agent/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CI-CD-Pipeline-Failure-Agent"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

##############################################################################
# S3 Bucket for Failure Logs
##############################################################################

resource "aws_s3_bucket" "failure_logs" {
  bucket = "${var.failure_logs_bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Pipeline Failure Logs"
    Description = "Stores CI/CD pipeline failure logs for analysis"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "failure_logs" {
  bucket = aws_s3_bucket.failure_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "failure_logs" {
  bucket = aws_s3_bucket.failure_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to delete old logs
resource "aws_s3_bucket_lifecycle_configuration" "failure_logs" {
  bucket = aws_s3_bucket.failure_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"
    
    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    
    filter {}

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "failure_logs" {
  bucket = aws_s3_bucket.failure_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##############################################################################
# SNS Topic for Notifications
##############################################################################

resource "aws_sns_topic" "pipeline_failures" {
  name = var.sns_topic_name

  tags = {
    Name        = "Pipeline Failure Notifications"
    Description = "Sends alerts when CI/CD pipeline fails"
  }
}

# SNS Topic Policy to allow CloudWatch Logs
resource "aws_sns_topic_policy" "pipeline_failures" {
  arn = aws_sns_topic.pipeline_failures.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.pipeline_failures.arn
      },
      {
        Sid    = "AllowLambda"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.pipeline_failures.arn
      }
    ]
  })
}

# Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.pipeline_failures.arn
  protocol  = "email"
  endpoint  = var.sns_email_address

  depends_on = [aws_sns_topic_policy.pipeline_failures]
}

##############################################################################
# CloudWatch Log Group for Lambda
##############################################################################

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "Lambda Failure Analyzer Logs"
    Description = "Logs for the pipeline failure analyzer Lambda function"
  }
}

resource "aws_cloudwatch_log_resource_policy" "lambda_logs" {
  policy_name = "lambda-logs-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

##############################################################################
# IAM Role for Lambda Function
##############################################################################

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssumeRoleForLambda"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "Lambda Execution Role"
    Description = "Role for Lambda to execute with required permissions"
  }
}

# Policy: CloudWatch Logs
resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.lambda_function_name}-logs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
      }
    ]
  })
}

# Policy: Bedrock Access
resource "aws_iam_role_policy" "lambda_bedrock" {
  name = "${var.lambda_function_name}-bedrock-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:${var.aws_region}::foundation-model/${var.bedrock_model_id}"
      },
      {
        Sid    = "BedrockList"
        Effect = "Allow"
        Action = [
          "bedrock:ListFoundationModels"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy: S3 Access
resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.lambda_function_name}-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.failure_logs.arn,
          "${aws_s3_bucket.failure_logs.arn}/*"
        ]
      }
    ]
  })
}

# Policy: SNS Publish
resource "aws_iam_role_policy" "lambda_sns" {
  name = "${var.lambda_function_name}-sns-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.pipeline_failures.arn
      }
    ]
  })
}

# Policy: GitHub API Access (for creating issues)
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${var.lambda_function_name}-secrets-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:github/*"
      }
    ]
  })
}

##############################################################################
# Data Sources
##############################################################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
