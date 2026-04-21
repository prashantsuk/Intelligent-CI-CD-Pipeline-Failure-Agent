#!/bin/bash

##############################################################################
# Script to Enable Bedrock Model Access via AWS CLI
# This script automates the Bedrock model access enablement
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get variables from environment
AWS_REGION="${AWS_REGION:-us-east-1}"
BEDROCK_MODEL_ID="${BEDROCK_MODEL_ID:-anthropic.claude-3-5-sonnet-20241022-v2:0}"
AWS_PROFILE="${AWS_PROFILE:-default}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Enabling Bedrock Model Access${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo -e "${YELLOW}Please install AWS CLI: https://aws.amazon.com/cli/${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking prerequisites...${NC}"
echo -e "${YELLOW}Region: $AWS_REGION${NC}"
echo -e "${YELLOW}Model ID: $BEDROCK_MODEL_ID${NC}\n"

# Check AWS credentials
if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo -e "${YELLOW}Please configure AWS credentials: aws configure${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
echo -e "${GREEN}✓ AWS Account: $ACCOUNT_ID\n${NC}"

# Function to check if model is already enabled
check_model_access() {
    aws bedrock list-foundation-models \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query "modelSummaries[?modelId=='$BEDROCK_MODEL_ID'].modelStatus" \
        --output text 2>/dev/null || echo ""
}

echo -e "${YELLOW}Checking current Bedrock model access...${NC}"

MODEL_STATUS=$(check_model_access)

if [[ "$MODEL_STATUS" == "AVAILABLE" ]]; then
    echo -e "${GREEN}✓ Model is already AVAILABLE${NC}\n"
    exit 0
elif [[ "$MODEL_STATUS" == "ON_DEMAND" ]]; then
    echo -e "${GREEN}✓ Model is ON_DEMAND (accessible)${NC}\n"
    exit 0
else
    echo -e "${YELLOW}⚠ Model status: ${MODEL_STATUS:-Not accessible}${NC}"
    echo -e "${YELLOW}Attempting to enable model access...${NC}\n"
fi

# Note: AWS doesn't provide a direct API to enable Bedrock models
# The enablement must be done through the AWS Console
# This script documents the process and provides verification

cat > /tmp/bedrock-setup-instructions.txt << 'EOF'
========================================
Manual Bedrock Model Access Setup
========================================

Unfortunately, AWS does not provide an API endpoint to enable Bedrock model access.
This must be done through the AWS Console.

Steps to Enable:

1. Open AWS Bedrock Console:
   https://console.aws.amazon.com/bedrock/home

2. Navigate to "Model access" in the left sidebar

3. Click "Manage model access" button

4. Search for "Claude 3.5 Sonnet" or your desired model

5. Check the checkbox to enable the model

6. Accept the terms and conditions

7. Click "Save changes"

8. Wait 5-10 minutes for access to be activated

Verification:
You can verify access using:
  aws bedrock list-foundation-models --region {REGION} --query 'modelSummaries[?modelId==`{MODEL_ID}`]'

========================================
EOF

echo -e "${YELLOW}Manual setup instructions saved to: /tmp/bedrock-setup-instructions.txt${NC}"
cat /tmp/bedrock-setup-instructions.txt

echo -e "\n${YELLOW}Steps to enable Bedrock access:${NC}"
echo -e "${BLUE}1. Open: https://console.aws.amazon.com/bedrock/home${NC}"
echo -e "${BLUE}2. Click 'Model access' (left sidebar)${NC}"
echo -e "${BLUE}3. Click 'Manage model access'${NC}"
echo -e "${BLUE}4. Find and check 'Anthropic Claude 3.5 Sonnet'${NC}"
echo -e "${BLUE}5. Accept terms and save${NC}"
echo -e "${BLUE}6. Wait 5-10 minutes${NC}\n"

echo -e "${YELLOW}After enabling, verify with:${NC}"
echo -e "${BLUE}aws bedrock list-foundation-models --region $AWS_REGION --query 'modelSummaries[?modelId==\`$BEDROCK_MODEL_ID\`]'${NC}\n"

echo -e "${GREEN}✓ Bedrock setup instructions complete${NC}"
