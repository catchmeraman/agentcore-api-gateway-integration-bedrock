#!/usr/bin/env python3
"""
Create AgentCore Gateway for Pet Store API
"""
import boto3
import json

# Initialize clients
bedrock_agent = boto3.client('bedrock-agent', region_name='us-east-1')

# Configuration
GATEWAY_NAME = 'PetStoreGateway'
API_GATEWAY_ID = '66gd6g08ie'
STAGE = 'prod'
IAM_ROLE_ARN = 'arn:aws:iam::114805761158:role/AgentCoreGatewayRole'

print(f"Creating AgentCore Gateway: {GATEWAY_NAME}")
print(f"API Gateway ID: {API_GATEWAY_ID}")
print(f"IAM Role: {IAM_ROLE_ARN}")
print()

try:
    # Create the gateway
    response = bedrock_agent.create_gateway(
        gatewayName=GATEWAY_NAME,
        description='MCP gateway for Pet Store API with Bedrock integration',
        gatewayConfiguration={
            'apiGatewayProxyConfiguration': {
                'apiGatewayId': API_GATEWAY_ID,
                'resourceArn': f'arn:aws:execute-api:us-east-1:114805761158:{API_GATEWAY_ID}/{STAGE}/*',
                'stage': STAGE
            }
        },
        gatewayRoleArn=IAM_ROLE_ARN
    )
    
    gateway_id = response['gatewayId']
    gateway_arn = response['gatewayArn']
    
    print("✅ Gateway created successfully!")
    print(f"Gateway ID: {gateway_id}")
    print(f"Gateway ARN: {gateway_arn}")
    print()
    
    # Get gateway details to find the URL
    details = bedrock_agent.get_gateway(gatewayIdentifier=gateway_id)
    
    if 'gatewayUrl' in details:
        gateway_url = details['gatewayUrl']
        print(f"Gateway URL: {gateway_url}")
    else:
        print(f"Gateway URL: https://{gateway_id}.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp")
    
    print()
    print("Next steps:")
    print(f"1. Update frontend CONFIG.gatewayUrl to: https://{gateway_id}.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp")
    print("2. Deploy to Amplify")
    
except Exception as e:
    print(f"❌ Error creating gateway: {e}")
    print()
    print("Checking if gateway already exists...")
    
    try:
        # List existing gateways
        gateways = bedrock_agent.list_gateways()
        
        if gateways.get('gatewaySummaries'):
            print(f"Found {len(gateways['gatewaySummaries'])} existing gateway(s):")
            for gw in gateways['gatewaySummaries']:
                print(f"  - {gw['gatewayName']} (ID: {gw['gatewayId']})")
                
                # Get details
                details = bedrock_agent.get_gateway(gatewayIdentifier=gw['gatewayId'])
                if 'gatewayUrl' in details:
                    print(f"    URL: {details['gatewayUrl']}")
                else:
                    print(f"    URL: https://{gw['gatewayId']}.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp")
        else:
            print("No existing gateways found.")
            print(f"Error details: {e}")
    except Exception as list_error:
        print(f"Could not list gateways: {list_error}")
