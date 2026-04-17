#!/bin/bash

##############################################################################
# Local Development Setup Script
# Sets up the development environment for local testing
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Local Development Setup${NC}"
echo -e "${GREEN}========================================\n${NC}"

# Create virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip setuptools wheel

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠ Please update .env with your configuration${NC}"
fi

# Run tests
echo -e "${YELLOW}Running tests...${NC}"
pytest test_app.py -v --cov=app --cov-report=html

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t intelligent-cicd-agent:dev .

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================\n${NC}"

echo -e "${YELLOW}Available Commands:${NC}"
echo -e "  Start application:   ${GREEN}python app.py${NC}"
echo -e "  Run tests:           ${GREEN}pytest test_app.py -v${NC}"
echo -e "  Run Flask dev mode:  ${GREEN}flask run${NC}"
echo -e "  Run Docker locally:  ${GREEN}docker run -p 5000:5000 intelligent-cicd-agent:dev${NC}"
echo -e "  Deactivate venv:     ${GREEN}deactivate${NC}\n"

echo -e "${YELLOW}Test the application:${NC}"
echo -e "  curl http://localhost:5000/"
echo -e "  curl http://localhost:5000/api/status"
echo -e "  curl http://localhost:5000/api/version\n"
