#!/bin/bash

##############################################################################
# Makefile equivalent for Terraform commands (for Windows/bash compatibility)
# Quick commands for common Terraform operations
##############################################################################

# Usage: source terraform.sh or ./terraform.sh command

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Available commands
show_help() {
    cat << EOF
${BLUE}Terraform Helper Commands${NC}

Usage: ./terraform.sh [command]

${GREEN}Setup Commands:${NC}
  init              Initialize Terraform (terraform init)
  validate          Validate configuration (terraform validate)
  setup             Full automated setup

${GREEN}Planning & Deployment:${NC}
  plan              Show what will be created (terraform plan)
  apply             Apply configuration (terraform apply)
  deploy            Plan and apply in one command

${GREEN}State Management:${NC}
  output            Show all outputs
  state-list        List all resources in state
  state-show [res]  Show resource details
  refresh           Refresh state from AWS

${GREEN}Cleanup:${NC}
  destroy           Destroy all infrastructure (WARNING!)
  destroy-plan      Show destroy plan without applying

${GREEN}Utilities:${NC}
  fmt               Format all .tf files
  lint              Run basic validation
  console           Launch Terraform console
  help              Show this help message

${YELLOW}Examples:${NC}
  ./terraform.sh init
  ./terraform.sh plan
  ./terraform.sh apply
  ./terraform.sh state-show aws_s3_bucket.failure_logs
  ./terraform.sh destroy

EOF
}

# Initialize Terraform
cmd_init() {
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    cd "$SCRIPT_DIR"
    terraform init -upgrade
}

# Validate configuration
cmd_validate() {
    echo -e "${YELLOW}Validating Terraform configuration...${NC}"
    cd "$SCRIPT_DIR"
    terraform validate
}

# Show plan
cmd_plan() {
    echo -e "${YELLOW}Running Terraform plan...${NC}"
    cd "$SCRIPT_DIR"
    terraform plan -out=tfplan
}

# Apply configuration
cmd_apply() {
    echo -e "${YELLOW}Applying Terraform configuration...${NC}"
    cd "$SCRIPT_DIR"
    terraform apply tfplan
}

# Plan and apply
cmd_deploy() {
    echo -e "${YELLOW}Planning and applying Terraform...${NC}"
    cd "$SCRIPT_DIR"
    terraform plan -out=tfplan
    echo -e "\n${BLUE}Ready to apply. Review plan above.${NC}"
    read -p "Continue? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        terraform apply tfplan
    fi
}

# Show outputs
cmd_output() {
    echo -e "${YELLOW}Terraform Outputs:${NC}\n"
    cd "$SCRIPT_DIR"
    terraform output
}

# List state resources
cmd_state_list() {
    echo -e "${YELLOW}Resources in state:${NC}\n"
    cd "$SCRIPT_DIR"
    terraform state list
}

# Show resource details
cmd_state_show() {
    if [ -z "$1" ]; then
        echo -e "${RED}Usage: ./terraform.sh state-show [resource_name]${NC}"
        echo -e "${YELLOW}Example: ./terraform.sh state-show aws_s3_bucket.failure_logs${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Resource details: $1${NC}\n"
    cd "$SCRIPT_DIR"
    terraform state show "$1"
}

# Refresh state
cmd_refresh() {
    echo -e "${YELLOW}Refreshing Terraform state...${NC}"
    cd "$SCRIPT_DIR"
    terraform refresh
    echo -e "${GREEN}✓ State refreshed${NC}"
}

# Destroy resources
cmd_destroy() {
    echo -e "${RED}WARNING: This will delete all AWS resources!${NC}"
    read -p "Type 'yes' to confirm: " -r
    if [[ $REPLY == "yes" ]]; then
        cd "$SCRIPT_DIR"
        terraform destroy
    else
        echo -e "${YELLOW}Destroy cancelled${NC}"
    fi
}

# Destroy plan
cmd_destroy_plan() {
    echo -e "${YELLOW}Showing destroy plan (not applying)...${NC}"
    cd "$SCRIPT_DIR"
    terraform plan -destroy
}

# Format files
cmd_fmt() {
    echo -e "${YELLOW}Formatting Terraform files...${NC}"
    cd "$SCRIPT_DIR"
    terraform fmt -recursive
    echo -e "${GREEN}✓ Files formatted${NC}"
}

# Lint (validate)
cmd_lint() {
    echo -e "${YELLOW}Linting Terraform files...${NC}"
    cd "$SCRIPT_DIR"
    terraform validate
    terraform fmt -check -recursive 2>/dev/null || true
    echo -e "${GREEN}✓ Validation complete${NC}"
}

# Console
cmd_console() {
    echo -e "${YELLOW}Launching Terraform console...${NC}"
    cd "$SCRIPT_DIR"
    terraform console
}

# Full setup
cmd_setup() {
    bash "$SCRIPT_DIR/setup-terraform.sh"
}

# Main handler
main() {
    local cmd="${1:-help}"
    
    case "$cmd" in
        init)           cmd_init ;;
        validate)       cmd_validate ;;
        plan)           cmd_plan ;;
        apply)          cmd_apply ;;
        deploy)         cmd_deploy ;;
        output)         cmd_output ;;
        state-list)     cmd_state_list ;;
        state-show)     cmd_state_show "$2" ;;
        refresh)        cmd_refresh ;;
        destroy)        cmd_destroy ;;
        destroy-plan)   cmd_destroy_plan ;;
        fmt)            cmd_fmt ;;
        lint)           cmd_lint ;;
        console)        cmd_console ;;
        setup)          cmd_setup ;;
        help)           show_help ;;
        *)              echo -e "${RED}Unknown command: $cmd${NC}"; show_help; exit 1 ;;
    esac
}

# Make script executable if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
