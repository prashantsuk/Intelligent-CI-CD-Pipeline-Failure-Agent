##############################################################################
# Input Variables for CI/CD Pipeline Failure Agent
##############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, eu-west-1)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "failure_logs_bucket_name" {
  description = "Base name for S3 bucket storing failure logs (account ID will be appended)"
  type        = string
  default     = "pipeline-failure-logs"

  validation {
    condition     = length(var.failure_logs_bucket_name) <= 25
    error_message = "Bucket name must be 25 characters or less."
  }
}

variable "sns_topic_name" {
  description = "Name for the SNS topic for failure notifications"
  type        = string
  default     = "pipeline-failure-notifications"
}

variable "sns_email_address" {
  description = "Email address to subscribe to SNS notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.sns_email_address))
    error_message = "Must be a valid email address."
  }
}

variable "lambda_function_name" {
  description = "Name for the Lambda function"
  type        = string
  default     = "pipeline-failure-analyzer"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,64}$", var.lambda_function_name))
    error_message = "Lambda function name must be 1-64 characters, alphanumeric, hyphens, and underscores only."
  }
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 3 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512

  validation {
    condition     = contains([128, 256, 512, 1024, 1536, 2048, 3008], var.lambda_memory_size)
    error_message = "Lambda memory must be one of: 128, 256, 512, 1024, 1536, 2048, 3008."
  }
}

variable "bedrock_model_id" {
  description = "Bedrock model ID to use for analysis"
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20241022-v2:0"

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.bedrock_model_id))
    error_message = "Must be a valid Bedrock model ID."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Must be a valid CloudWatch retention period."
  }
}

variable "enable_bedrock_model_access" {
  description = "Whether to enable Bedrock model access via AWS CLI (requires aws CLI installed)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
