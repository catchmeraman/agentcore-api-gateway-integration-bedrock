# AgentCore Gateway - Manual Setup Required

## Status: IAM Role Ready ✅

The IAM role `AgentCoreGatewayRole` has been created with proper permissions:
- **Role ARN**: `arn:aws:iam::114805761158:role/AgentCoreGatewayRole`
- **Permissions**: API Gateway invoke access for `66gd6g08ie`

## Next Step: Create Gateway via AWS Console

AgentCore Gateway creation is currently only available through:
1. AWS Console (recommended)
2. AWS SDK (requires latest boto3 version)

### Option 1: AWS Console (Easiest)

1. **Open AWS Console**:
   - Go to: https://console.aws.amazon.com/bedrock/
   - Navigate to: **AgentCore** → **Gateways**

2. **Create Gateway**:
   - Click "Create Gateway"
   - **Name**: `PetStoreGateway`
   - **Description**: `MCP gateway for Pet Store API with Bedrock integration`

3. **Configure Target**:
   - **Target Type**: API Gateway
   - **API Gateway ID**: `66gd6g08ie`
   - **Stage**: `prod`
   - **IAM Role ARN**: `arn:aws:iam::114805761158:role/AgentCoreGatewayRole`

4. **Configure Tools** (4 tools):

   **Tool 1: ListPets**
   ```json
   {
     "name": "ListPets",
     "description": "List all pets in the store",
     "method": "GET",
     "path": "/pets"
   }
   ```

   **Tool 2: GetPetById**
   ```json
   {
     "name": "GetPetById",
     "description": "Get a specific pet by ID",
     "method": "GET",
     "path": "/pets/{petId}",
     "parameters": {
       "petId": {
         "type": "string",
         "required": true,
         "location": "path",
         "description": "The ID of the pet to retrieve"
       }
     }
   }
   ```

   **Tool 3: AddPet**
   ```json
   {
     "name": "AddPet",
     "description": "Add a new pet to the store",
     "method": "POST",
     "path": "/pets",
     "requestBody": {
       "required": true,
       "content": {
         "application/json": {
           "schema": {
             "type": "object",
             "properties": {
               "name": {"type": "string"},
               "type": {"type": "string"},
               "breed": {"type": "string"},
               "age": {"type": "integer"},
               "price": {"type": "integer"}
             },
             "required": ["name", "type"]
           }
         }
       }
     }
   }
   ```

   **Tool 4: QueryPets**
   ```json
   {
     "name": "QueryPets",
     "description": "Query pets using natural language (LLM-powered)",
     "method": "POST",
     "path": "/pets/query",
     "requestBody": {
       "required": true,
       "content": {
         "application/json": {
           "schema": {
             "type": "object",
             "properties": {
               "query": {"type": "string"}
             },
             "required": ["query"]
           }
         }
       }
     }
   }
   ```

5. **Authentication** (Optional):
   - Type: JWT (Cognito)
   - User Pool ID: `us-east-1_RNmMBC87g`
   - Client ID: `435iqd7cgbn2slmgn0a36fo9lf`

6. **Create Gateway**:
   - Click "Create"
   - **Copy the Gateway ID** (e.g., `petstoregateway-xxxxx`)
   - **Copy the Gateway URL** (e.g., `https://petstoregateway-xxxxx.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp`)

### Option 2: Use Existing Gateway

If you already have gateway `petstoregateway-remqjziohl`:

1. Verify it's configured correctly in AWS Console
2. Use URL: `https://petstoregateway-remqjziohl.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp`

## After Gateway Creation

### Update Frontend

Edit `frontend/petstore-chat-secure.html`:

```javascript
const CONFIG = {
    userPoolId: 'us-east-1_RNmMBC87g',
    clientId: '435iqd7cgbn2slmgn0a36fo9lf',
    region: 'us-east-1',
    gatewayUrl: 'https://<YOUR-GATEWAY-ID>.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp'
};
```

Replace `<YOUR-GATEWAY-ID>` with your actual gateway ID.

### Deploy to Amplify

```bash
cd /Users/ramandeep_chandna/agentcore-api-gateway-integration-bedrock

# Commit changes
git add frontend/petstore-chat-secure.html
git commit -m "Update gateway URL"
git push origin main

# Amplify will auto-deploy
```

Or manually:

```bash
aws amplify start-deployment \
  --app-id d1du8jz8xbjmnh \
  --branch-name main \
  --region us-east-1
```

## Verification

Test the gateway with curl:

```bash
# Get JWT token
TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 435iqd7cgbn2slmgn0a36fo9lf \
  --auth-parameters USERNAME=testuser,PASSWORD=******** \
  --query 'AuthenticationResult.AccessToken' \
  --output text \
  --region us-east-1)

# Test MCP call
curl -X POST https://<YOUR-GATEWAY-ID>.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp \
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

## Troubleshooting

### Gateway Not Found
- Verify gateway exists in AWS Console
- Check gateway ID is correct
- Ensure gateway is in `us-east-1` region

### Authentication Errors
- Verify JWT token is valid
- Check Cognito user pool configuration
- Ensure gateway auth is configured correctly

### API Gateway Errors
- Verify API Gateway ID: `66gd6g08ie`
- Check IAM role has proper permissions
- Test API Gateway endpoints directly first

## Summary

✅ **Completed**:
- IAM role created with proper permissions
- Frontend code ready with MCP protocol
- Architecture documented with diagrams

⏳ **Manual Step Required**:
- Create AgentCore Gateway via AWS Console
- Update frontend with gateway URL
- Deploy to Amplify

The gateway creation is a one-time manual step that takes ~2 minutes in the AWS Console.
