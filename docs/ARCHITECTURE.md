# Architecture Documentation

## System Overview

The Intelligent CI/CD Pipeline Failure Agent is a fully automated system that monitors, analyzes, and provides insights into CI/CD pipeline failures using AI.

## Components

### 1. GitHub Actions Workflow
**File**: `.github/workflows/ci-cd-pipeline.yml`

**Stages:**
- **Test Stage**: Runs pytest and linting
- **Build & Push Stage**: Builds Docker image and pushes to Docker Hub
- **On Failure Stage**: Triggers failure analysis
- **Notify Stage**: Sends notifications

**Key Features:**
- Parallel job execution
- Caching for faster builds
- Automatic issue creation on failures
- Slack/SNS notifications

### 2. Python Flask Application
**File**: `app.py`

**Endpoints:**
- `GET /` - Health check
- `GET /api/status` - Service status
- `GET /api/version` - Version info
- `POST /api/analyze` - Log analysis endpoint
- `GET /api/health` - Detailed health

**Key Features:**
- RESTful API design
- Comprehensive error handling
- Logging with error tracking
- Docker-ready

### 3. Docker Container
**File**: `Dockerfile`

**Features:**
- Multi-stage build for optimization
- Non-root user for security
- Health check enabled
- Layer caching

**Build time**: ~1m 15s  
**Image size**: ~150MB (optimized)

### 4. AWS Lambda Function
**File**: `lambda/pipeline_failure_analyzer.py`

**Purpose**: AI-powered failure analysis

**Key Classes:**
- `PipelineFailureAnalyzer`: Main analysis engine
- Functions: `store_logs_in_s3()`, `send_notification()`, `lambda_handler()`

**Processing Flow:**
```
Event received
    ↓
Store logs in S3
    ↓
Invoke Bedrock Claude
    ↓
Parse AI response
    ↓
Send SNS notification
    ↓
Return results
```

**Timeout**: 300 seconds  
**Memory**: 512 MB

### 5. AWS Services Integration

#### Amazon Bedrock
- **Model**: Claude 3.5 Sonnet
- **Purpose**: LLM for log analysis
- **API**: InvokeModel
- **Cost**: Pay-per-use (no setup cost)

#### S3 Bucket
- **Purpose**: Store failure logs
- **Retention**: 90 days (lifecycle policy)
- **Encryption**: AES-256
- **Versioning**: Enabled

#### SNS Topic
- **Purpose**: Send notifications
- **Subscribers**: Email, Slack
- **Protocol**: JSON messages

#### CloudWatch Logs
- **Purpose**: Lambda execution logs
- **Retention**: 30 days
- **Queries**: CloudWatch Insights ready

#### IAM Role
- **Purpose**: Lambda permissions
- **Principle**: Least privilege
- **Policies**: Inline + managed

## Data Flow

### Successful Pipeline
```
Code Push
  ↓
Test Pass → Build → Push to Docker Hub → Success Notification
```

### Failed Pipeline
```
Code Push
  ↓
Test Fail (or Build Fail)
  ↓
Collect Logs → Store in S3
  ↓
Trigger Lambda
  ↓
Bedrock Analysis
  ↓
SNS Notification + GitHub Issue Creation
  ↓
Engineer receives AI insights
```

## Failure Categories

The AI agent categorizes failures:

1. **Dependency Issues**
   - Missing packages
   - Version conflicts
   - Registry unavailable
   - Lock file inconsistencies

2. **Test Failures**
   - Unit test failures
   - Integration test failures
   - Coverage below threshold
   - Timeout errors

3. **Configuration Errors**
   - Missing env variables
   - Invalid credentials
   - File permissions
   - Wrong paths

4. **Build Issues**
   - Compilation errors
   - Docker build failures
   - Resource constraints
   - Syntax errors

5. **Runtime Issues**
   - Memory out
   - Timeout
   - Process killed
   - Exit code non-zero

## Analysis Capabilities

### Root Cause Identification
- Scans logs for error patterns
- Cross-references known issues
- Uses context from repository

### Fix Suggestions
- Provides 2-3 ranked suggestions
- Estimates impact (P1/P2/P3)
- Links to documentation
- Explains each fix

### Prevention Steps
- Best practices recommendation
- Preventive configuration
- Monitoring setup
- Testing strategies

## Scalability

### Horizontal Scaling
- Lambda: Auto-scales with concurrent executions
- Workers: Configurable per region
- S3: Unlimited storage capacity

### Vertical Scaling
- Lambda Memory: 128 MB to 10 GB
- Lambda Timeout: 1s to 15m
- Bedrock: No scaling needed (managed service)

### Performance Metrics
| Operation | Time | Cost |
|-----------|------|------|
| Test run | ~30s | Free (GitHub) |
| Docker build | ~75s | Free (Docker) |
| Push to hub | ~45s | Free |
| Lambda invoke | ~2s | $0.0000002 |
| Bedrock call | ~15s | ~$0.003 (Claude) |
| Total pipeline | ~3m | ~$0.005 |

## Cost Estimation (Monthly)

### AWS Services
- **S3**: ~$1-2 (logs storage)
- **Lambda**: ~$1-2 (invocations)
- **Bedrock**: ~$50-100 (analysis calls)
- **SNS**: <$1 (notifications)
- **CloudWatch**: ~$2-5 (logs)

**Total**: ~$55-110/month for 1000+ failures

### GitHub Actions
- Free for public repositories
- $0.008/min for private repos

## Security Architecture

### Data Protection
- ✅ S3 encryption (AES-256)
- ✅ IAM role isolation
- ✅ Secrets in GitHub (encrypted)
- ✅ VPC-ready design

### Access Control
- ✅ Least privilege IAM policy
- ✅ Lambda execution isolation
- ✅ S3 public access blocked
- ✅ GitHub OIDC integration ready

### Audit & Monitoring
- ✅ CloudWatch logging
- ✅ S3 access logs
- ✅ Lambda execution logs
- ✅ CloudTrail compatible

## Fault Tolerance

### Lambda Failures
- **Retry**: 2 automatic retries
- **Dead Letter Queue**: SNS topic for failed messages
- **Fallback**: Logs stored in S3 regardless

### Bedrock Failures
- Graceful degradation with error response
- Stores raw logs for manual review
- Notifies via SNS

### S3 Failures
- Handles write failures gracefully
- Returns error status
- Lambda continues execution

## Monitoring & Observability

### Metrics
- Lambda invocations
- Success/failure rates
- Average analysis time
- Bedrock token usage

### Alarms
- Lambda errors > 5% (1 hour)
- S3 bucket size > 5GB
- SNS delivery failures
- Bedrock rate limiting

### Logs
- Structured JSON logs
- Correlation IDs for tracing
- Log levels: DEBUG, INFO, WARNING, ERROR

## Future Enhancements

1. **Auto-remediation**
   - Automatically apply common fixes
   - Create pull requests with suggestions

2. **Pattern Detection**
   - ML model for recurring failures
   - Predictive failure prevention

3. **Jira Integration**
   - Create tickets automatically
   - Link to existing issues

4. **Dashboards**
   - QuickSight/Grafana integration
   - Failure trends visualization
   - Team analytics

5. **Fine-tuning**
   - Custom organization knowledge base
   - Domain-specific models
   - Historical pattern learning

## References

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
