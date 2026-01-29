# Quick Start Guide

Get the Pet Store Chatbot running in 15 minutes!

## Prerequisites

- AWS Account with admin access
- AWS CLI configured (`aws configure`)
- Python 3.8+ installed
- Git installed

## Step 1: Clone Repository (1 min)

```bash
git clone https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock.git
cd agentcore-api-gateway-integration-bedrock
```

## Step 2: Run Deployment Script (5 min)

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

This creates:
- ✅ DynamoDB table (PetStore)
- ✅ IAM role with permissions
- ✅ Lambda function
- ✅ S3 bucket for frontend

**Output:**
```
✅ Deployment Complete!

📝 Next Steps:
1. Create API Gateway
2. Create Cognito User Pool
3. Update frontend configuration
```

## Step 3: Create API Gateway (3 min)

### Option A: AWS Console (Recommended)

1. Go to API Gateway console
2. Click "Create API" → "REST API"
3. Name: `PetStoreAPI`
4. Create resources:
   - `/pets` (GET, POST)
   - `/pets/{petId}` (GET)
   - `/pets/query` (POST)
5. For each method:
   - Integration type: Lambda Function
   - Lambda: `PetStoreFunction`
   - Enable Lambda Proxy integration
6. Add OPTIONS method for CORS
7. Deploy to `prod` stage

### Option B: AWS CLI

```bash
# Create API
API_ID=$(aws apigateway create-rest-api \
  --name PetStoreAPI \
  --region us-east-1 \
  --query 'id' \
  --output text)

# Get root resource
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region us-east-1 \
  --query 'items[0].id' \
  --output text)

# Create /pets resource
PETS_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part pets \
  --region us-east-1 \
  --query 'id' \
  --output text)

# Add POST method
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $PETS_ID \
  --http-method POST \
  --authorization-type NONE \
  --region us-east-1

# Add Lambda integration
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $PETS_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:${ACCOUNT_ID}:function:PetStoreFunction/invocations" \
  --region us-east-1

# Deploy
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region us-east-1

echo "API Gateway URL: https://${API_ID}.execute-api.us-east-1.amazonaws.com/prod"
```

## Step 4: Create Cognito User Pool (3 min)

```bash
# Create user pool
POOL_ID=$(aws cognito-idp create-user-pool \
  --pool-name PetStoreUsers \
  --policies "PasswordPolicy={MinimumLength=8,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}" \
  --auto-verified-attributes email \
  --region us-east-1 \
  --query 'UserPool.Id' \
  --output text)

# Create app client
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --user-pool-id $POOL_ID \
  --client-name PetStoreApp \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --region us-east-1 \
  --query 'UserPoolClient.ClientId' \
  --output text)

# Create test user
aws cognito-idp admin-create-user \
  --user-pool-id $POOL_ID \
  --username testuser \
  --temporary-password TempPass123! \
  --message-action SUPPRESS \
  --region us-east-1

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $POOL_ID \
  --username testuser \
  --password ******** \
  --permanent \
  --region us-east-1

echo "User Pool ID: $POOL_ID"
echo "Client ID: $CLIENT_ID"
echo "Test User: testuser / ********"
```

## Step 5: Update Frontend Configuration (2 min)

Edit `frontend/petstore-chat-secure.html`:

```javascript
const CONFIG = {
    userPoolId: 'YOUR_POOL_ID',      // From Step 4
    clientId: 'YOUR_CLIENT_ID',       // From Step 4
    region: 'us-east-1',
    apiUrl: 'YOUR_API_URL'            // From Step 3
};
```

Upload to S3:
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="petstore-chat-demo-${ACCOUNT_ID}"

aws s3 cp frontend/petstore-chat-secure.html s3://$BUCKET/ --cache-control "no-cache"

echo "Frontend URL: http://${BUCKET}.s3-website-us-east-1.amazonaws.com/petstore-chat-secure.html"
```

## Step 6: Test! (1 min)

1. Open the frontend URL in your browser
2. Login with: `testuser` / `********`
3. Try these queries:
   - "List all pets"
   - "Show me expensive dogs"
   - "Cheap cats under $200"
   - "Add a dog named Max, breed: Golden Retriever, age: 3, price: $500"

**Look for the 🤖 AI-powered badge on complex queries!**

---

## Troubleshooting

### Issue: Login fails
**Solution:** Check Cognito configuration
```bash
aws cognito-idp describe-user-pool-client \
  --user-pool-id YOUR_POOL_ID \
  --client-id YOUR_CLIENT_ID \
  --region us-east-1
```

### Issue: API returns 403
**Solution:** Add Lambda permissions
```bash
aws lambda add-permission \
  --function-name PetStoreFunction \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:us-east-1:ACCOUNT_ID:API_ID/*" \
  --region us-east-1
```

### Issue: No AI badge appears
**Solution:** Check Lambda logs
```bash
aws logs tail /aws/lambda/PetStoreFunction --since 5m --region us-east-1 | grep "LLM"
```

If you see "LLM Error", check Bedrock permissions:
```bash
aws iam get-role-policy \
  --role-name PetStoreLambdaRole \
  --policy-name BedrockInvokePolicy
```

### Issue: CORS errors
**Solution:** Verify OPTIONS method exists
```bash
aws apigateway get-method \
  --rest-api-id YOUR_API_ID \
  --resource-id YOUR_RESOURCE_ID \
  --http-method OPTIONS \
  --region us-east-1
```

---

## Verification Checklist

- [ ] DynamoDB table created
- [ ] Lambda function deployed
- [ ] API Gateway created with 4 endpoints
- [ ] Cognito user pool created
- [ ] Test user created
- [ ] Frontend uploaded to S3
- [ ] Can login successfully
- [ ] Can list pets
- [ ] Can add pets
- [ ] LLM queries show 🤖 badge

---

## Next Steps

1. **Read the docs:**
   - [Architecture](docs/ARCHITECTURE.md) - Understand the system
   - [Example Logs](docs/EXAMPLE_LOGS.md) - See actual request flows
   - [Cost Analysis](docs/COST_ANALYSIS.md) - Understand costs

2. **Customize:**
   - Add more pet types
   - Implement update/delete
   - Add image upload
   - Multi-language support

3. **Deploy to production:**
   - Enable HTTPS with CloudFront
   - Add rate limiting
   - Enable CloudWatch alarms
   - Set up CI/CD pipeline

4. **Share:**
   - Star the repo ⭐
   - Share with colleagues
   - Contribute improvements

---

## Clean Up

To delete all resources:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

This removes:
- Lambda function
- DynamoDB table
- S3 bucket
- IAM roles
- API Gateway
- Cognito user pool

**Estimated time to clean up: 2 minutes**

---

## Support

- **Issues:** https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock/issues
- **Discussions:** https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock/discussions

---

**Total Setup Time: ~15 minutes**
**Monthly Cost: ~$0.05 for 1000 queries**

🎉 **Congratulations! You now have a production-ready AI chatbot!**
