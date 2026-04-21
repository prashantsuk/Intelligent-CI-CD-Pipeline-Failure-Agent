##############################################################################
# Output Values for CI/CD Pipeline Failure Agent
##############################################################################

output "s3_bucket_name" {
  description = "Name of the S3 bucket for failure logs"
  value       = aws_s3_bucket.failure_logs.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.failure_logs.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.pipeline_failures.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.pipeline_failures.name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_role.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    s3_bucket              = aws_s3_bucket.failure_logs.id
    sns_topic              = aws_sns_topic.pipeline_failures.name
    lambda_role            = aws_iam_role.lambda_role.name
    cloudwatch_log_group   = aws_cloudwatch_log_group.lambda_logs.name
    bedrock_model_id       = var.bedrock_model_id
    lambda_timeout_seconds = var.lambda_timeout
    lambda_memory_mb       = var.lambda_memory_size
  }
}

output "next_steps" {
  description = "Next steps after Terraform deployment"
  value = [
    "1. Confirm SNS email subscription - Check your email for AWS notification",
    "2. Deploy Lambda function - Use deploy.sh or manually upload the Lambda code",
    "3. Configure GitHub Actions secrets with Docker credentials",
    "4. Configure GitHub Actions workflow to trigger on failures",
    "5. Push code to GitHub to trigger the first pipeline"
  ]
}
