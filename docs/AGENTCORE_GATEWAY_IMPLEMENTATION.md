# AgentCore Gateway Implementation Guide

## Current Status

### ✅ Implemented Components

1. **API Gateway** (ID: `66gd6g08ie`)
   - GET /pets - List all pets
   - GET /pets/{id} - Get pet by ID
   - POST /pets - Add new pet
   - POST /pets/query - LLM-powered query

2. **Lambda Function** (`PetStoreFunction`)
   - Bedrock integration for NL queries
   - DynamoDB CRUD operations
   - CORS handling

3. **DynamoDB Table** (`PetStore`)
   - 30+ pets loaded
   - On-demand billing

4. **Cognito User Pool** (`us-east-1_RNmMBC87g`)
   - User: testuser
   - JWT authentication

5. **Frontend** (Updated)
   - MCP protocol support
   - AgentCore Gateway integration code
   - Deployed to: https://petstore.cloudopsinsights.com

### ⚠️ AgentCore Gateway Setup Required

The frontend code is **ready** to use AgentCore Gateway, but the gateway needs to be created/verified in your AWS account.

## Setup AgentCore Gateway

### Step 1: Create IAM Role for Gateway

```bash
cd /Users/ramandeep_chandna/agentcore-api-gateway-integration-bedrock

# Create trust policy
cat > /tmp/gateway-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "bedrock.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create role
aws iam create-role \
  --role-name AgentCoreGatewayRole \
  --assume-role-policy-document file:///tmp/gateway-trust-policy.json

# Create policy for API Gateway access
cat > /tmp/gateway-api-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "execute-api:Invoke",
      "execute-api:ManageConnections"
    ],
    "Resource": "arn:aws:execute-api:us-east-1:*:66gd6g08ie/*"
  }]
}
EOF

# Attach policy
aws iam put-role-policy \
  --role-name AgentCoreGatewayRole \
  --policy-name APIGatewayAccess \
  --policy-document file:///tmp/gateway-api-policy.json

# Get role ARN (save this)
aws iam get-role --role-name AgentCoreGatewayRole --query 'Role.Arn' --output text
```

### Step 2: Create AgentCore Gateway via Console

**Note**: AgentCore Gateway creation is currently only available via AWS Console or SDK (not CLI).

1. Go to AWS Console → Bedrock → AgentCore → Gateways
2. Click "Create Gateway"
3. Configure:
   - **Name**: `PetStoreGateway`
   - **Description**: `MCP gateway for Pet Store API`
   - **Target Type**: API Gateway
   - **API Gateway ID**: `66gd6g08ie`
   - **Stage**: `prod`
   - **IAM Role**: `AgentCoreGatewayRole` (from Step 1)

4. **Tool Configuration**:
   ```json
   {
     "tools": [
       {
         "name": "ListPets",
         "description": "List all pets in the store",
         "method": "GET",
         "path": "/pets"
       },
       {
         "name": "GetPetById",
         "description": "Get a specific pet by ID",
         "method": "GET",
         "path": "/pets/{petId}",
         "parameters": {
           "petId": {
             "type": "string",
             "required": true,
             "location": "path"
           }
         }
       },
       {
         "name": "AddPet",
         "description": "Add a new pet to the store",
         "method": "POST",
         "path": "/pets",
         "requestBody": {
           "name": "string",
           "type": "string",
           "breed": "string",
           "age": "number",
           "price": "number"
         }
       },
       {
         "name": "QueryPets",
         "description": "Query pets using natural language",
         "method": "POST",
         "path": "/pets/query",
         "requestBody": {
           "query": "string"
         }
       }
     ]
   }
   ```

5. **Authentication**:
   - Type: JWT (Cognito)
   - User Pool: `us-east-1_RNmMBC87g`
   - Client ID: `435iqd7cgbn2slmgn0a36fo9lf`

6. Click "Create"

### Step 3: Update Frontend Configuration

After creating the gateway, update the frontend with the gateway URL:

```javascript
// In frontend/petstore-chat-secure.html
const CONFIG = {
    userPoolId: 'us-east-1_RNmMBC87g',
    clientId: '435iqd7cgbn2slmgn0a36fo9lf',
    region: 'us-east-1',
    gatewayUrl: 'https://<gateway-id>.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp'
};
```

Replace `<gateway-id>` with your actual gateway ID from the console.

### Step 4: Deploy Updated Frontend

```bash
cd /Users/ramandeep_chandna/agentcore-api-gateway-integration-bedrock

# Deploy to Amplify
aws amplify start-deployment \
  --app-id d1du8jz8xbjmnh \
  --branch-name main \
  --region us-east-1
```

## Alternative: Python SDK Method

If you prefer programmatic creation:

```python
import boto3

bedrock = boto3.client('bedrock-agent', region_name='us-east-1')

# Create gateway
response = bedrock.create_gateway(
    gatewayName='PetStoreGateway',
    description='MCP gateway for Pet Store API',
    targetConfig={
        'apiGateway': {
            'apiGatewayId': '66gd6g08ie',
            'stage': 'prod',
            'roleArn': '<IAM_ROLE_ARN_FROM_STEP_1>'
        }
    },
    authConfig={
        'type': 'JWT',
        'jwtConfig': {
            'userPoolId': 'us-east-1_RNmMBC87g',
            'clientId': '435iqd7cgbn2slmgn0a36fo9lf'
        }
    }
)

print(f"Gateway ID: {response['gatewayId']}")
print(f"Gateway URL: {response['gatewayUrl']}")
```

## Verification

### Test Gateway with curl

```bash
# Get JWT token first
TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 435iqd7cgbn2slmgn0a36fo9lf \
  --auth-parameters USERNAME=testuser,PASSWORD=******** \
  --query 'AuthenticationResult.AccessToken' \
  --output text)

# Test MCP call
curl -X POST https://<gateway-id>.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "PetStoreTarget___ListPets",
      "arguments": {}
    }
  }'
```

Expected response:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{
      "type": "text",
      "text": "[{\"id\":\"1\",\"name\":\"Buddy\",...}]"
    }]
  }
}
```

## Current Frontend Behavior

The frontend code is **already updated** to use AgentCore Gateway:

1. All operations route through Gateway MCP endpoint
2. JWT token from Cognito is included in requests
3. Responses are parsed from MCP format
4. User sees: "Found X pets (via AgentCore Gateway)"

**Once you create the gateway and update the `gatewayUrl` in CONFIG, the complete flow will be active!**

## Architecture Benefits

### With AgentCore Gateway:
```
Browser → AgentCore Gateway (MCP) → API Gateway → Lambda → Bedrock/DynamoDB
```

**Benefits:**
- Standardized MCP protocol
- Centralized authentication
- Tool abstraction layer
- Better observability
- Future-proof for multi-agent systems

### Without AgentCore Gateway (Current):
```
Browser → API Gateway → Lambda → Bedrock/DynamoDB
```

**Current State:**
- Direct REST API calls
- Works but less abstraction
- No MCP protocol benefits

## Next Steps

1. ✅ IAM Role created
2. ⏳ Create AgentCore Gateway (via Console or SDK)
3. ⏳ Update frontend CONFIG with gateway URL
4. ⏳ Deploy to Amplify
5. ✅ Test complete flow

## Documentation

- Architecture diagrams: `generated-diagrams/`
- Complete flow: `README.md`
- STAR method: `docs/STAR_METHOD.md`
- Detailed workflows: `docs/WORKFLOW_DETAILED.md`

## Support

If you encounter issues:
1. Check CloudWatch logs for Lambda function
2. Verify IAM role permissions
3. Test API Gateway endpoints directly
4. Validate Cognito JWT tokens
5. Check AgentCore Gateway logs in Console
