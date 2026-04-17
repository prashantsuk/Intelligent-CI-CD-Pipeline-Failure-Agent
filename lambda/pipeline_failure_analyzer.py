"""
AWS Lambda Function for Intelligent CI/CD Pipeline Failure Analysis
Uses Amazon Bedrock LLM to analyze failure logs and suggest fixes
"""

import json
import boto3
import os
import logging
from datetime import datetime
from typing import Dict, List, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_client = boto3.client('bedrock-runtime')
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
github_client = boto3.client('secretsmanager')

# Environment variables
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
FAILURE_LOGS_BUCKET = os.environ.get('FAILURE_LOGS_BUCKET', 'pipeline-failure-logs')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')


class PipelineFailureAnalyzer:
    """Analyzes CI/CD pipeline failures using Bedrock AI"""
    
    def __init__(self):
        self.model_id = BEDROCK_MODEL_ID
    
    def analyze_logs_with_bedrock(self, logs: str) -> Dict[str, Any]:
        """
        Analyze failure logs using Claude via Bedrock
        
        Args:
            logs: Raw failure logs from CI/CD pipeline
        
        Returns:
            Analysis results including root cause and suggestions
        """
        try:
            prompt = self._build_analysis_prompt(logs)
            
            logger.info(f"Analyzing logs with model: {self.model_id}")
            
            # Call Bedrock API
            response = bedrock_client.invoke_model(
                modelId=self.model_id,
                contentType='application/json',
                accept='application/json',
                body=json.dumps({
                    "anthropic_version": "bedrock-2023-06-01",
                    "max_tokens": 2000,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ]
                })
            )
            
            # Parse response
            response_body = json.loads(response.get('body').read())
            analysis_text = response_body['content'][0]['text']
            
            # Extract structured analysis
            analysis = self._parse_analysis(analysis_text)
            
            return {
                'status': 'success',
                'analysis': analysis,
                'raw_response': analysis_text,
                'model_used': self.model_id,
                'timestamp': datetime.utcnow().isoformat()
            }
        
        except Exception as e:
            logger.error(f"Error analyzing logs: {str(e)}")
            return {
                'status': 'error',
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            }
    
    def _build_analysis_prompt(self, logs: str) -> str:
        """Build the prompt for log analysis"""
        return f"""You are an expert DevOps engineer and CI/CD specialist. Analyze the following pipeline failure logs and provide:

1. **Root Cause**: Identify the primary reason for the failure (dependency issue, test failure, config error, etc.)
2. **Severity**: Rate as Critical, High, Medium, or Low
3. **Suggested Fixes**: Provide 2-3 specific, actionable fixes
4. **Prevention**: Suggest how to prevent this in the future
5. **Estimated Impact**: How this affects the team and pipeline

PIPELINE FAILURE LOGS:
========================
{logs}
========================

Respond in the following JSON format:
{{
    "root_cause": "...",
    "severity": "High",
    "category": "dependency|test|config|network|permission|other",
    "suggested_fixes": [
        {{"fix": "...", "priority": "P1", "estimated_impact": "high"}},
        {{"fix": "...", "priority": "P2", "estimated_impact": "medium"}}
    ],
    "prevention_steps": ["...", "..."],
    "summary": "..."
}}"""
    
    def _parse_analysis(self, response: str) -> Dict[str, Any]:
        """Parse the AI response into structured format"""
        try:
            # Extract JSON from response
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            if json_start != -1 and json_end > json_start:
                json_str = response[json_start:json_end]
                return json.loads(json_str)
        except json.JSONDecodeError:
            logger.warning("Could not parse JSON from response, returning raw text")
        
        return {
            'summary': response,
            'raw_response': True
        }


def store_logs_in_s3(logs: str, run_id: str) -> str:
    """Store failure logs in S3 for future reference"""
    try:
        key = f"failures/{run_id}/logs-{datetime.utcnow().isoformat()}.txt"
        s3_client.put_object(
            Bucket=FAILURE_LOGS_BUCKET,
            Key=key,
            Body=logs,
            ContentType='text/plain'
        )
        logger.info(f"Logs stored in S3: s3://{FAILURE_LOGS_BUCKET}/{key}")
        return f"s3://{FAILURE_LOGS_BUCKET}/{key}"
    except Exception as e:
        logger.error(f"Error storing logs in S3: {str(e)}")
        return None


def send_notification(analysis: Dict[str, Any], logs_location: str, context: Dict) -> bool:
    """Send analysis results via SNS"""
    try:
        if not SNS_TOPIC_ARN:
            logger.warning("SNS_TOPIC_ARN not configured")
            return False
        
        message = format_notification_message(analysis, logs_location, context)
        
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='🤖 CI/CD Pipeline Failure - AI Analysis Report',
            Message=message
        )
        
        logger.info("Notification sent successfully")
        return True
    except Exception as e:
        logger.error(f"Error sending notification: {str(e)}")
        return False


def format_notification_message(analysis: Dict, logs_location: str, context: Dict) -> str:
    """Format notification message"""
    msg = "PIPELINE FAILURE - AI ANALYSIS REPORT\n"
    msg += "=" * 50 + "\n\n"
    
    if analysis.get('status') == 'success':
        analysis_data = analysis.get('analysis', {})
        msg += f"Root Cause: {analysis_data.get('root_cause', 'Unknown')}\n"
        msg += f"Severity: {analysis_data.get('severity', 'Unknown')}\n"
        msg += f"Category: {analysis_data.get('category', 'Unknown')}\n\n"
        
        msg += "Suggested Fixes:\n"
        for fix in analysis_data.get('suggested_fixes', []):
            msg += f"  - {fix.get('fix', '')}\n"
        
        msg += "\nPrevention Steps:\n"
        for step in analysis_data.get('prevention_steps', []):
            msg += f"  - {step}\n"
    else:
        msg += f"Analysis Status: {analysis.get('status')}\n"
        msg += f"Error: {analysis.get('error', 'Unknown error')}\n"
    
    msg += f"\nLogs Location: {logs_location}\n"
    msg += f"Pipeline Run ID: {context.get('run_id')}\n"
    msg += f"Repository: {context.get('repository')}\n"
    msg += f"Branch: {context.get('branch')}\n"
    
    return msg


def lambda_handler(event, context):
    """
    AWS Lambda handler for pipeline failure analysis
    
    Event structure:
    {
        "logs": "pipeline failure logs",
        "run_id": "github-run-id",
        "repository": "owner/repo",
        "branch": "main",
        "timestamp": "2024-01-15T10:30:00Z"
    }
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Extract event data
        logs = event.get('logs', '')
        run_id = event.get('run_id', 'unknown')
        repository = event.get('repository', 'unknown')
        branch = event.get('branch', 'main')
        
        if not logs:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'No logs provided'})
            }
        
        # Store logs in S3
        logs_location = store_logs_in_s3(logs, run_id)
        
        # Analyze logs with Bedrock
        analyzer = PipelineFailureAnalyzer()
        analysis = analyzer.analyze_logs_with_bedrock(logs)
        
        # Prepare context for notifications
        notification_context = {
            'run_id': run_id,
            'repository': repository,
            'branch': branch
        }
        
        # Send notification
        send_notification(analysis, logs_location or 'N/A', notification_context)
        
        # Return results
        return {
            'statusCode': 200,
            'body': json.dumps({
                'status': 'success',
                'analysis': analysis,
                'logs_stored_at': logs_location,
                'processed_at': datetime.utcnow().isoformat()
            })
        }
    
    except Exception as e:
        logger.error(f"Lambda execution failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'status': 'error',
                'error': str(e),
                'timestamp': datetime.utcnow().isoformat()
            })
        }


if __name__ == '__main__':
    # Local testing
    test_event = {
        'logs': '''Error: Package installation failed
        npm ERR! code ELIFECYCLE
        npm ERR! 404 Not Found - GET https://registry.npmjs.org/@types/node/-/node-0.1.0.tgz
        npm ERR! 404 Repository not found
        npm ERR! This is probably not a problem with npm. There is likely additional logging...''',
        'run_id': 'test-run-123',
        'repository': 'user/repo',
        'branch': 'main'
    }
    
    result = lambda_handler(test_event, None)
    print(json.dumps(result, indent=2))
