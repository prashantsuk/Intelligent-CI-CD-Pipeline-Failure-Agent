# Troubleshooting Guide

## Common Issues and Solutions

### 1. Pipeline Issues

#### Pipeline not triggering
**Symptoms**: Workflow doesn't run on push

**Solutions**:
1. Check if GitHub Actions is enabled
   ```bash
   # In repository Settings → Actions → General
   # Ensure "Allow all actions and reusable workflows" is selected
   ```

2. Verify workflow file syntax
   ```bash
   # Check .github/workflows/ci-cd-pipeline.yml exists
   # Use yamllint for validation
   yamllint .github/workflows/ci-cd-pipeline.yml
   ```

3. Check branch rules
   ```bash
   # Settings → Branches
   # Ensure workflow can run on your branch
   ```

#### Tests failing locally but passing in GitHub
**Solutions**:
1. Check Python version matches
   ```bash
   python --version  # Should be 3.11+
   ```

2. Install dependencies
   ```bash
   pip install -r requirements.txt
   ```

3. Run tests with same flags as GitHub
   ```bash
   pytest test_app.py -v --cov=app --cov-report=xml
   ```

#### Docker build failing
**Symptoms**: `docker build` fails locally

**Solutions**:
1. Check Dockerfile syntax
   ```bash
   docker build --no-cache -t test:latest .
   # Add --progress=plain for detailed output
   ```

2. Verify base image is accessible
   ```bash
   docker pull python:3.11-slim
   ```

3. Check disk space
   ```bash
   docker system df
   docker system prune  # Clean up unused images
   ```

---

### 2. Docker Hub Issues

#### Docker push rejected
**Symptoms**: `Error response from daemon: denied: access denied`

**Solutions**:
1. Verify Docker Hub credentials
   ```bash
   docker login
   # Enter username and password (or token)
   ```

2. Check username in image tag
   ```bash
   docker tag myimage:latest username/myimage:latest
   docker push username/myimage:latest
   ```

3. Verify GitHub secrets
   ```bash
   # Go to repo Settings → Secrets
   # Check DOCKER_USERNAME and DOCKER_PASSWORD
   ```

#### Rate limit exceeded
**Symptoms**: `429 Too Many Requests`

**Solutions**:
1. Check rate limit status
   ```bash
   docker info | grep -A2 "Rate"
   ```

2. Wait before retrying (1 hour cooling period)

3. Use Docker Hub login for higher limits
   ```bash
   docker login
   ```

---

### 3. AWS Issues

#### Bedrock access denied
**Symptoms**: `AccessDenied: User: ... is not authorized to perform: bedrock:InvokeModel`

**Solutions**:
1. Enable Bedrock model access
   - Go to AWS Console → Bedrock → Model access
   - Click "Manage model access"
   - Select "Anthropic Claude 3.5 Sonnet"
   - Wait for approval (5-10 minutes)

2. Verify IAM permissions
   ```bash
   aws iam get-role-policy \
     --role-name pipeline-failure-agent-lambda-role \
     --policy-name LambdaExecutionPolicy
   ```

3. Check region
   ```bash
   # Bedrock only available in specific regions
   # us-east-1, us-west-2, eu-west-1, ap-northeast-1
   echo $AWS_REGION
   ```

#### Lambda function not found
**Symptoms**: `ResourceNotFoundException: Function not found`

**Solutions**:
1. Verify Lambda exists
   ```bash
   aws lambda get-function \
     --function-name pipeline-failure-analyzer \
     --region us-east-1
   ```

2. Check region
   ```bash
   aws lambda list-functions --region us-east-1
   ```

3. Re-deploy if needed
   ```bash
   cd lambda
   bash ../aws/deploy.sh
   ```

#### S3 bucket not writable
**Symptoms**: `AccessDenied: Access Denied` when writing to S3

**Solutions**:
1. Verify bucket exists
   ```bash
   aws s3 ls s3://pipeline-failure-logs-ACCOUNT_ID/
   ```

2. Check bucket policy
   ```bash
   aws s3api get-bucket-policy \
     --bucket pipeline-failure-logs-ACCOUNT_ID
   ```

3. Check IAM role permissions
   ```bash
   aws iam get-role-policy \
     --role-name pipeline-failure-agent-lambda-role \
     --policy-name LambdaExecutionPolicy
   ```

#### SNS notifications not received
**Symptoms**: Pipeline fails but no email notification

**Solutions**:
1. Check SNS subscriptions
   ```bash
   aws sns list-subscriptions-by-topic \
     --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:pipeline-failure-notifications
   ```

2. Verify subscription is confirmed
   - Check email (including spam folder)
   - Click confirmation link if needed

3. Test SNS manually
   ```bash
   aws sns publish \
     --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:pipeline-failure-notifications \
     --subject "Test" \
     --message "Test message"
   ```

#### CloudFormation stack creation failed
**Symptoms**: Stack rollback or creation fails

**Solutions**:
1. Check stack events
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name pipeline-failure-agent
   ```

2. Clean up and retry
   ```bash
   aws cloudformation delete-stack \
     --stack-name pipeline-failure-agent
   # Wait for deletion
   aws cloudformation create-stack \
     --stack-name pipeline-failure-agent \
     --template-body file://aws/cloudformation-template.yaml \
     --parameters ParameterKey=SNSEmailAddress,ParameterValue=your-email@example.com \
     --capabilities CAPABILITY_NAMED_IAM
   ```

---

### 4. GitHub Issues

#### Repository secrets not working
**Symptoms**: GitHub Actions fails with authentication errors

**Solutions**:
1. Re-create secret (they can't be read back)
   ```bash
   # Delete and recreate in Settings → Secrets
   ```

2. Verify secret name matches workflow
   ```yaml
   # In workflow file
   username: ${{ secrets.DOCKER_USERNAME }}
   ```

3. Check secret scope
   - Secrets are per-repository by default
   - Organization secrets are inherited

#### GitHub Actions rate limited
**Symptoms**: `API rate limit exceeded`

**Solutions**:
1. Use `secrets.GITHUB_TOKEN` automatically provided
   - Already in workflow for GitHub actions

2. For custom API calls, authenticate
   ```bash
   curl -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
        https://api.github.com/...
   ```

---

### 5. Local Development Issues

#### Virtual environment not activating
**Solutions**:
```bash
# On Linux/Mac
source venv/bin/activate

# On Windows
.\venv\Scripts\activate

# Verify activation
which python  # Should point to venv
```

#### Import errors for local modules
**Solutions**:
```bash
# Reinstall in development mode
pip install -e .

# Or ensure PYTHONPATH includes project
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

#### Port 5000 already in use
**Solutions**:
```bash
# Find process using port
lsof -i :5000
# Kill process
kill -9 <PID>

# Or use different port
PORT=8000 python app.py
```

---

### 6. Performance Issues

#### Lambda taking too long
**Symptoms**: Lambda timeout after 300 seconds

**Solutions**:
1. Increase timeout
   ```bash
   aws lambda update-function-configuration \
     --function-name pipeline-failure-analyzer \
     --timeout 600  # Max 900 seconds
   ```

2. Increase memory (improves CPU)
   ```bash
   aws lambda update-function-configuration \
     --function-name pipeline-failure-analyzer \
     --memory-size 1024
   ```

3. Optimize code
   - Cache Bedrock responses
   - Process logs in parallel
   - Use smaller models for simple tasks

#### Docker build very slow
**Solutions**:
1. Use BuildKit for better caching
   ```bash
   DOCKER_BUILDKIT=1 docker build -t test:latest .
   ```

2. Minimize layers
   - Combine RUN commands
   - Use .dockerignore

3. Use layer caching
   ```bash
   docker build --cache-from test:latest -t test:latest .
   ```

---

### 7. Debugging Techniques

#### Enable debug logging
```bash
# In Lambda
export LOG_LEVEL=DEBUG

# In Flask app
export FLASK_ENV=development
export FLASK_DEBUG=True
```

#### View detailed logs
```bash
# Lambda logs with timestamps
aws logs tail /aws/lambda/pipeline-failure-analyzer \
  --follow \
  --log-stream-name-prefix "2024-04-"

# GitHub Actions logs
gh run view RUN_ID --log
```

#### Test Lambda locally
```bash
# Using AWS Lambda Runtime Interface Emulator
docker run -p 9000:8080 \
  -v $(pwd):/var/task \
  public.ecr.aws/lambda/python:3.11 \
  pipeline_failure_analyzer.lambda_handler

# Test invoke
curl -X POST \
  "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d @lambda/test_event.json
```

---

## Getting Help

1. **Check logs first**
   - GitHub Actions: Workflow runs
   - Lambda: CloudWatch logs
   - Docker: Build output

2. **Verify configuration**
   - `.env` file values
   - GitHub secrets
   - AWS IAM permissions

3. **Search existing issues**
   - GitHub repository issues
   - AWS forums

4. **Ask for help**
   - Create GitHub issue with:
     - Error message (full stacktrace)
     - Steps to reproduce
     - Configuration (sanitized)
     - Logs (relevant sections)
