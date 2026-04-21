#!/bin/bash

##############################################################################
# Terraform Setup and Deployment Script
# Automated setup for AWS infrastructure
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}CI/CD Pipeline Agent - Terraform Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing=0
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed${NC}"
        echo -e "${YELLOW}Install: https://www.terraform.io/downloads${NC}"
        missing=1
    else
        TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
        echo -e "${GREEN}✓ Terraform ${TF_VERSION}${NC}"
    fi
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        echo -e "${YELLOW}Install: https://aws.amazon.com/cli/${NC}"
        missing=1
    else
        AWS_VERSION=$(aws --version | cut -d' ' -f1)
        echo -e "${GREEN}✓ AWS CLI ${AWS_VERSION}${NC}"
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git is not installed${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Git installed${NC}"
    fi
    
    if [ $missing -eq 1 ]; then
        echo -e "\n${RED}Please install missing tools${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met\n${NC}"
}

# Check AWS credentials
check_aws_credentials() {
    echo -e "${YELLOW}Checking AWS credentials...${NC}"
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        echo -e "${YELLOW}Run: aws configure${NC}"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    IDENTITY=$(aws sts get-caller-identity --query Arn --output text)
    
    echo -e "${GREEN}✓ AWS Account: $ACCOUNT_ID${NC}"
    echo -e "${GREEN}✓ Identity: $IDENTITY\n${NC}"
}

# Initialize Terraform
init_terraform() {
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    
    cd "$SCRIPT_DIR"
    
    if terraform init -upgrade; then
        echo -e "${GREEN}✓ Terraform initialized\n${NC}"
    else
        echo -e "${RED}❌ Terraform initialization failed${NC}"
        exit 1
    fi
}

# Validate Terraform configuration
validate_terraform() {
    echo -e "${YELLOW}Validating Terraform configuration...${NC}"
    
    cd "$SCRIPT_DIR"
    
    if terraform validate; then
        echo -e "${GREEN}✓ Terraform configuration valid\n${NC}"
    else
        echo -e "${RED}❌ Terraform validation failed${NC}"
        exit 1
    fi
}

# Check if terraform.tfvars exists
check_tfvars() {
    echo -e "${YELLOW}Checking terraform.tfvars...${NC}"
    
    if [ ! -f "$SCRIPT_DIR/terraform.tfvars" ]; then
        echo -e "${YELLOW}⚠ terraform.tfvars not found${NC}"
        echo -e "${YELLOW}Creating from example...${NC}"
        
        if [ -f "$SCRIPT_DIR/terraform.tfvars.example" ]; then
            cp "$SCRIPT_DIR/terraform.tfvars.example" "$SCRIPT_DIR/terraform.tfvars"
            echo -e "${YELLOW}✓ Created terraform.tfvars${NC}"
            echo -e "${RED}⚠ IMPORTANT: Edit terraform.tfvars and update sns_email_address${NC}\n"
        else
            echo -e "${RED}❌ terraform.tfvars.example not found${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ terraform.tfvars exists\n${NC}"
    fi
}

# Make scripts executable
make_scripts_executable() {
    echo -e "${YELLOW}Making scripts executable...${NC}"
    
    chmod +x "$SCRIPT_DIR/scripts/enable-bedrock-access.sh" 2>/dev/null || true
    chmod +x "$PROJECT_DIR/aws/deploy.sh" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Scripts made executable\n${NC}"
}

# Show Terraform plan
show_plan() {
    echo -e "${YELLOW}Running Terraform plan...${NC}"
    echo -e "${YELLOW}(This shows what will be created)\n${NC}"
    
    cd "$SCRIPT_DIR"
    
    if terraform plan -out=tfplan; then
        echo -e "\n${GREEN}✓ Plan created successfully${NC}\n"
        return 0
    else
        echo -e "${RED}❌ Terraform plan failed${NC}"
        return 1
    fi
}

# Apply Terraform configuration
apply_terraform() {
    echo -e "${YELLOW}Applying Terraform configuration...${NC}"
    echo -e "${BLUE}This will create AWS resources${NC}\n"
    
    read -p "Do you want to continue? (yes/no): " -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
    
    cd "$SCRIPT_DIR"
    
    if terraform apply tfplan; then
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}✓ Infrastructure deployed successfully!${NC}"
        echo -e "${GREEN}========================================\n${NC}"
        return 0
    else
        echo -e "${RED}❌ Terraform apply failed${NC}"
        return 1
    fi
}

# Display outputs
show_outputs() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Deployment Outputs${NC}"
    echo -e "${BLUE}========================================\n${NC}"
    
    cd "$SCRIPT_DIR"
    terraform output
    
    echo -e "\n${GREEN}Next Steps:${NC}"
    echo -e "${BLUE}1. Confirm SNS email subscription${NC}"
    echo -e "${BLUE}2. Enable Bedrock model access (if not done)${NC}"
    echo -e "${BLUE}3. Deploy Lambda function${NC}"
    echo -e "${BLUE}4. Configure GitHub Actions secrets${NC}"
    echo -e "${BLUE}5. Push code to trigger first pipeline\n${NC}"
}

# Main execution
main() {
    check_prerequisites
    check_aws_credentials
    init_terraform
    validate_terraform
    check_tfvars
    make_scripts_executable
    
    if show_plan; then
        if apply_terraform; then
            show_outputs
            echo -e "${GREEN}✓ Setup complete!${NC}"
        else
            echo -e "${RED}❌ Deployment failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Planning failed${NC}"
        exit 1
    fi
}

# Run main function
main
