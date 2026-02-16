# Quick Setup: Configure AgentCore Gateway Tools

## Gateway Status

✅ **Gateway Exists**: `petstoregateway-xxxxxxx`  
✅ **Gateway URL**: `https://petstoregateway-rxxxxxxxx.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp`  
✅ **IAM Role**: `arn:aws:iam::1xxxxxxxxx:role/AgentCoreGatewayRole`  
✅ **Frontend**: Updated with gateway URL  
⚠️ **Tools**: Need to be configured (currently only has search tool)

## What You Need to Do

### Step 1: Configure Gateway Tools (5 minutes)

1. Open AWS Console: https://console.aws.amazon.com/bedrock/
2. Navigate to: **AgentCore** → **Gateways**
3. Find gateway: `petstoregateway-rxxxxxxx`
4. Click **Edit** or **Configure Tools**

### Step 2: Add 4 Tools

Copy-paste these tool configurations:

#### Tool 1: ListPets
```json
{
  "name": "ListPets",
  "description": "List all pets in the store",
  "apiSchema": {
    "method": "GET",
    "path": "/pets"
  }
}
```

#### Tool 2: GetPetById  
```json
{
  "name": "GetPetById",
  "description": "Get a specific pet by ID",
  "apiSchema": {
    "method": "GET",
    "path": "/pets/{petId}",
    "parameters": [
      {
        "name": "petId",
        "in": "path",
        "required": true,
        "schema": {"type": "string"}
      }
    ]
  }
}
```

#### Tool 3: AddPet
```json
{
  "name": "AddPet",
  "description": "Add a new pet to the store",
  "apiSchema": {
    "method": "POST",
    "path": "/pets",
    "requestBody": {
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
            }
          }
        }
      }
    }
  }
}
```

#### Tool 4: QueryPets
```json
{
  "name": "QueryPets",
  "description": "Query pets using natural language with AI",
  "apiSchema": {
    "method": "POST",
    "path": "/pets/query",
    "requestBody": {
      "content": {
        "application/json": {
          "schema": {
            "type": "object",
            "properties": {
              "query": {"type": "string"}
            }
          }
        }
      }
    }
  }
}
```

### Step 3: Save Configuration

Click **Save** or **Update Gateway**

### Step 4: Test Gateway

```bash
# Get token
TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id xxxxxxx \
  --auth-parameters USERNAME=testuser,PASSWORD=******** \
  --query 'AuthenticationResult.AccessToken' \
  --output text \
  --region us-east-1)

# List tools (should show 4 tools now)
curl -X POST https://petstoregateway-xxxxxx.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | jq '.result.tools[].name'

# Test ListPets
curl -X POST https://petstoregateway-xxxxxxxx.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"tools/call",
    "params":{
      "name":"PetStoreTarget___ListPets",
      "arguments":{}
    }
  }' | jq .
```

### Step 5: Deploy Frontend (Already Done!)

The frontend is already updated and will auto-deploy via Amplify.

Check deployment status:
```bash
aws amplify list-jobs --app-id xxxxxxxxx --branch-name main --region us-east-1 --max-items 1
```

## Expected Result

After configuring tools, visit: https://petstore.cloudopsinsights.com

1. Login with: `testuser` / `********`
2. Try: "Show me dogs under $300"
3. You should see: "Found X pets (🤖 AI via AgentCore Gateway → Bedrock)"

## Complete Flow

```
Browser → AgentCore Gateway (MCP) → API Gateway → Lambda → Bedrock/DynamoDB
```

All requests now go through the gateway!

## Troubleshooting

### Tools not showing up
- Wait 1-2 minutes after saving
- Refresh the gateway page
- Check CloudWatch logs

### Frontend still shows errors
- Clear browser cache
- Wait for Amplify deployment to complete
- Check browser console for errors

### Gateway returns 403
- Verify IAM role permissions
- Check API Gateway resource policy
- Ensure JWT token is valid

## Summary

✅ Gateway exists and is responding  
✅ IAM role configured  
✅ Frontend updated with gateway URL  
✅ Code pushed to GitHub  
✅ Amplify will auto-deploy  

⏳ **Only remaining step**: Configure 4 tools in AWS Console (5 minutes)

Once tools are configured, the complete AgentCore Gateway flow will be active!
