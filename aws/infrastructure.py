"""
AWS Infrastructure deployment for Intelligent CI/CD Pipeline Failure Agent
Uses CloudFormation/CDK concepts for deployment
"""

# This module can be used with AWS CDK or CloudFormation

import json

# CloudFormation template for the failure analysis infrastructure
CLOUDFORMATION_TEMPLATE = {
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "Intelligent CI/CD Pipeline Failure Agent Infrastructure",
    
    "Parameters": {
        "GitHubToken": {
            "Type": "String",
            "NoEcho": True,
            "Description": "GitHub personal access token"
        },
        "SNSEmailAddress": {
            "Type": "String",
            "Description": "Email address for SNS notifications"
        }
    },
    
    "Resources": {
        # S3 Bucket for storing failure logs
        "FailureLogsBucket": {
            "Type": "AWS::S3::Bucket",
            "Properties": {
                "BucketName": {"Fn::Sub": "pipeline-failure-logs-${AWS::AccountId}"},
                "VersioningConfiguration": {
                    "Status": "Enabled"
                },
                "LifecycleConfiguration": {
                    "LifecycleRules": [{
                        "Id": "DeleteOldLogs",
                        "Status": "Enabled",
                        "ExpirationInDays": 90,
                        "NoncurrentVersionExpirationInDays": 30
                    }]
                },
                "PublicAccessBlockConfiguration": {
                    "BlockPublicAcls": True,
                    "BlockPublicPolicy": True,
                    "IgnorePublicAcls": True,
                    "RestrictPublicBuckets": True
                }
            }
        },
        
        # IAM Role for Lambda
        "LambdaExecutionRole": {
            "Type": "AWS::IAM::Role",
            "Properties": {
                "AssumeRolePolicyDocument": {
                    "Version": "2012-10-17",
                    "Statement": [{
                        "Effect": "Allow",
                        "Principal": {
                            "Service": "lambda.amazonaws.com"
                        },
                        "Action": "sts:AssumeRole"
                    }]
                },
                "ManagedPolicyArns": [
                    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
                ],
                "Policies": [{
                    "PolicyName": "LambdaExecutionPolicy",
                    "PolicyDocument": {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Action": [
                                    "bedrock:InvokeModel",
                                    "bedrock:InvokeModelWithResponseStream"
                                ],
                                "Resource": "*"
                            },
                            {
                                "Effect": "Allow",
                                "Action": [
                                    "s3:PutObject",
                                    "s3:GetObject",
                                    "s3:ListBucket"
                                ],
                                "Resource": [
                                    {"Fn::GetAtt": ["FailureLogsBucket", "Arn"]},
                                    {"Fn::Sub": "${FailureLogsBucket.Arn}/*"}
                                ]
                            },
                            {
                                "Effect": "Allow",
                                "Action": [
                                    "sns:Publish"
                                ],
                                "Resource": {"Ref": "FailureNotificationTopic"}
                            },
                            {
                                "Effect": "Allow",
                                "Action": [
                                    "logs:CreateLogGroup",
                                    "logs:CreateLogStream",
                                    "logs:PutLogEvents"
                                ],
                                "Resource": "arn:aws:logs:*:*:*"
                            }
                        ]
                    }
                }]
            }
        },
        
        # SNS Topic for notifications
        "FailureNotificationTopic": {
            "Type": "AWS::SNS::Topic",
            "Properties": {
                "TopicName": "pipeline-failure-notifications",
                "DisplayName": "CI/CD Pipeline Failure Notifications"
            }
        },
        
        # SNS Subscription for email
        "EmailSubscription": {
            "Type": "AWS::SNS::Subscription",
            "Properties": {
                "TopicArn": {"Ref": "FailureNotificationTopic"},
                "Protocol": "email",
                "Endpoint": {"Ref": "SNSEmailAddress"}
            }
        },
        
        # CloudWatch Log Group
        "LambdaLogGroup": {
            "Type": "AWS::Logs::LogGroup",
            "Properties": {
                "LogGroupName": "/aws/lambda/pipeline-failure-analyzer",
                "RetentionInDays": 30
            }
        }
    },
    
    "Outputs": {
        "FailureLogsBucketName": {
            "Description": "S3 bucket for storing failure logs",
            "Value": {"Ref": "FailureLogsBucket"}
        },
        "SNSTopicArn": {
            "Description": "SNS topic ARN for notifications",
            "Value": {"Ref": "FailureNotificationTopic"}
        },
        "LambdaRoleArn": {
            "Description": "Lambda execution role ARN",
            "Value": {"Fn::GetAtt": ["LambdaExecutionRole", "Arn"]}
        }
    }
}


def get_cloudformation_template():
    """Return the CloudFormation template"""
    return json.dumps(CLOUDFORMATION_TEMPLATE, indent=2)


if __name__ == '__main__':
    print(get_cloudformation_template())
