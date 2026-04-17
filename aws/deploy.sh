#!/bin/bash

##############################################################################
# Deployment Script for Intelligent CI/CD Pipeline Failure Agent
# This script automates AWS infrastructure deployment
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="pipeline-failure-agent"
REGION="${AWS_REGION:-us-east-1}"
LAMBDA_FUNCTION_NAME="pipeline-failure-analyzer"
BEDROCK_MODEL_ID="anthropic.claude-3-sonnet-20240229-v1:0"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CI/CD Pipeline Failure Agent Deployment${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    commands=("aws" "docker" "python3")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}❌ $cmd is not installed${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ All prerequisites met\n${NC}"
}

# Check AWS credentials
check_aws_credentials() {
    echo -e "${YELLOW}Checking AWS credentials...${NC}"
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✓ AWS Account: $ACCOUNT_ID\n${NC}"
}

# Check Bedrock access
check_bedrock_access() {
    echo -e "${YELLOW}Checking Bedrock model access...${NC}"
    
    if aws bedrock list-foundation-models \
        --region "$REGION" \
        --query 'modelSummaries[?modelId==`'$BEDROCK_MODEL_ID'`]' \
        --output json 2>/dev/null | grep -q "$BEDROCK_MODEL_ID"; then
        echo -e "${GREEN}✓ Bedrock access confirmed\n${NC}"
    else
        echo -e "${YELLOW}⚠ Bedrock model not confirmed accessible${NC}"
        echo -e "${YELLOW}Please enable access in: https://console.aws.amazon.com/bedrock/home\n${NC}"
    fi
}

# Create S3 bucket
create_s3_bucket() {
    echo -e "${YELLOW}Creating S3 bucket for failure logs...${NC}"
    
    BUCKET_NAME="pipeline-failure-logs-${ACCOUNT_ID}"
    
    if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
        aws s3 mb "s3://${BUCKET_NAME}" --region "$REGION"
        echo -e "${GREEN}✓ S3 bucket created: $BUCKET_NAME\n${NC}"
    else
        echo -e "${GREEN}✓ S3 bucket already exists: $BUCKET_NAME\n${NC}"
    fi
}

# Create SNS topic
create_sns_topic() {
    echo -e "${YELLOW}Creating SNS topic for notifications...${NC}"
    
    SNS_RESPONSE=$(aws sns create-topic \
        --name pipeline-failure-notifications \
        --region "$REGION" \
        --output json)
    
    SNS_TOPIC_ARN=$(echo "$SNS_RESPONSE" | grep -o 'arn:aws:sns:[^"]*')
    
    echo -e "${GREEN}✓ SNS topic created: $SNS_TOPIC_ARN\n${NC}"
}

# Create IAM role
create_iam_role() {
    echo -e "${YELLOW}Creating IAM role for Lambda...${NC}"
    
    ROLE_NAME="${STACK_NAME}-lambda-role"
    
    # Check if role exists
    if aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓ IAM role already exists: $ROLE_NAME\n${NC}"
        ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
    else
        # Create trust policy
        TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'
        
        aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document "$TRUST_POLICY"
        
        # Attach policies
        aws iam attach-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
        
        # Create inline policy for Bedrock, S3, SNS
        INLINE_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::pipeline-failure-logs-*", "arn:aws:s3:::pipeline-failure-logs-*/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["sns:Publish"],
      "Resource": "'$SNS_TOPIC_ARN'"
    }
  ]
}'
        
        aws iam put-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-name lambda-execution-policy \
            --policy-document "$INLINE_POLICY"
        
        # Wait for role to be available
        sleep 10
        
        ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
        echo -e "${GREEN}✓ IAM role created: $ROLE_ARN\n${NC}"
    fi
}

# Deploy Lambda function
deploy_lambda_function() {
    echo -e "${YELLOW}Deploying Lambda function...${NC}"
    
    cd lambda
    
    # Create deployment package
    mkdir -p package
    pip install -r ../requirements.txt -t ./package --quiet
    cp pipeline_failure_analyzer.py ./package/
    
    # Create ZIP file
    cd package
    zip -r ../lambda_function.zip . -q
    cd ..
    
    # Create or update Lambda function
    if aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" --region "$REGION" 2>/dev/null; then
        echo -e "${YELLOW}Updating existing Lambda function...${NC}"
        aws lambda update-function-code \
            --function-name "$LAMBDA_FUNCTION_NAME" \
            --zip-file fileb://lambda_function.zip \
            --region "$REGION" \
            --output json > /dev/null
    else
        echo -e "${YELLOW}Creating new Lambda function...${NC}"
        aws lambda create-function \
            --function-name "$LAMBDA_FUNCTION_NAME" \
            --runtime python3.11 \
            --role "$ROLE_ARN" \
            --handler pipeline_failure_analyzer.lambda_handler \
            --zip-file fileb://lambda_function.zip \
            --timeout 300 \
            --memory-size 512 \
            --environment "Variables={BEDROCK_MODEL_ID=$BEDROCK_MODEL_ID,FAILURE_LOGS_BUCKET=pipeline-failure-logs-${ACCOUNT_ID},SNS_TOPIC_ARN=$SNS_TOPIC_ARN}" \
            --region "$REGION" \
            --output json > /dev/null
    fi
    
    cd ..
    
    echo -e "${GREEN}✓ Lambda function deployed\n${NC}"
}

# Setup environment file
setup_env_file() {
    echo -e "${YELLOW}Creating .env file...${NC}"
    
    if [ ! -f .env ]; then
        cp .env.example .env
        
        # Update with actual values
        sed -i "s|BEDROCK_MODEL_ID=.*|BEDROCK_MODEL_ID=$BEDROCK_MODEL_ID|" .env
        sed -i "s|FAILURE_LOGS_BUCKET=.*|FAILURE_LOGS_BUCKET=pipeline-failure-logs-${ACCOUNT_ID}|" .env
        sed -i "s|SNS_TOPIC_ARN=.*|SNS_TOPIC_ARN=$SNS_TOPIC_ARN|" .env
        sed -i "s|AWS_REGION=.*|AWS_REGION=$REGION|" .env
        
        echo -e "${GREEN}✓ .env file created${NC}"
    else
        echo -e "${YELLOW}⚠ .env file already exists${NC}"
    fi
    
    echo ""
}

# Print summary
print_summary() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Deployment Complete!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    echo -e "${YELLOW}AWS Resources Created:${NC}"
    echo -e "  Account ID:       ${GREEN}$ACCOUNT_ID${NC}"
    echo -e "  S3 Bucket:        ${GREEN}pipeline-failure-logs-${ACCOUNT_ID}${NC}"
    echo -e "  SNS Topic:        ${GREEN}$SNS_TOPIC_ARN${NC}"
    echo -e "  Lambda Function:  ${GREEN}$LAMBDA_FUNCTION_NAME${NC}"
    echo -e "  IAM Role:         ${GREEN}${ROLE_NAME}${NC}"
    echo -e "  Region:           ${GREEN}$REGION${NC}\n"
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "  1. Update GitHub Secrets:"
    echo -e "     - DOCKER_USERNAME"
    echo -e "     - DOCKER_PASSWORD"
    echo -e "  2. Subscribe to SNS notifications"
    echo -e "  3. Push to GitHub to trigger pipeline\n"
    
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo -e "  View Lambda logs:"
    echo -e "    ${GREEN}aws logs tail /aws/lambda/$LAMBDA_FUNCTION_NAME --follow${NC}"
    echo -e "  View S3 logs:"
    echo -e "    ${GREEN}aws s3 ls s3://pipeline-failure-logs-${ACCOUNT_ID}/failures/${NC}"
    echo -e "  Invoke Lambda manually:"
    echo -e "    ${GREEN}aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload file://lambda/test_event.json response.json${NC}\n"
}

# Main execution
main() {
    check_prerequisites
    check_aws_credentials
    check_bedrock_access
    create_s3_bucket
    create_sns_topic
    create_iam_role
    deploy_lambda_function
    setup_env_file
    print_summary
}

# Run main function
main
