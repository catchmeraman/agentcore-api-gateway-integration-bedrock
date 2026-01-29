# AgentCore Gateway + API Gateway + Bedrock Integration Demo

🐾 **AI-Powered Pet Store Chatbot** - A production-ready demonstration of AWS AgentCore Gateway integration with API Gateway, Lambda, DynamoDB, and Amazon Bedrock for natural language processing.

## 🎯 What We Built

A conversational AI chatbot that demonstrates:

1. **AgentCore Gateway Integration** - MCP protocol for tool exposure
2. **LLM-Powered Natural Language** - Amazon Bedrock (Nova Micro) for query understanding
3. **Full CRUD Operations** - Via conversational interface
4. **Secure Authentication** - AWS Cognito without hardcoded credentials
5. **Complete Observability** - CloudWatch logs showing full request flow

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                             │
│                  (petstore-chat-secure.html)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS COGNITO                                 │
│                  (Authentication)                                │
│              User Pool: us-east-1_RNmMBC87g                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ JWT Token
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   API GATEWAY (REST API)                         │
│                    ID: 66gd6g08ie                                │
│                                                                   │
│  Endpoints:                                                       │
│  • GET  /pets          - List all pets                          │
│  • GET  /pets/{id}     - Get pet by ID                          │
│  • POST /pets          - Add new pet                            │
│  • POST /pets/query    - LLM-powered natural language query     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Lambda Proxy Integration
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LAMBDA FUNCTION                               │
│                  (PetStoreFunction)                              │
│                                                                   │
│  Features:                                                        │
│  • Bedrock Converse API integration                             │
│  • Tool calling for parameter extraction                        │
│  • Fallback to keyword matching                                 │
│  • CORS handling                                                │
└──────────────┬──────────────────────────┬───────────────────────┘
               │                          │
               │                          │ InvokeModel
               ▼                          ▼
┌──────────────────────────┐  ┌─────────────────────────────────┐
│      DYNAMODB            │  │    AMAZON BEDROCK               │
│   Table: PetStore        │  │  Model: Nova Micro              │
│                          │  │  (us.amazon.nova-micro-v1:0)    │
│  • 30+ pets              │  │                                 │
│  • Partition key: id     │  │  Tool: filter_pets              │
│  • On-demand billing     │  │  • type_filter                  │
└──────────────────────────┘  │  • max_price                    │
                              │  • min_price                    │
                              │  • sort_by                      │
                              └─────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              AGENTCORE GATEWAY (Optional)                        │
│           Gateway ID: petstoregateway-remqjziohl                 │
│                                                                   │
│  MCP Tools Exposed:                                              │
│  • ListPets    - GET /pets                                      │
│  • GetPetById  - GET /pets/{petId}                              │
│  • AddPet      - POST /pets                                     │
│  • QueryPets   - POST /pets/query (LLM-powered)                 │
└─────────────────────────────────────────────────────────────────┘
```

## 💡 Why This Matters

### Business Value
- **Natural Language Interface** - Users ask questions in plain English
- **Minimal Cost** - Nova Micro costs ~$0.0001 per query (fraction of a cent!)
- **Production Ready** - Secure authentication, error handling, observability
- **Scalable** - Serverless architecture scales automatically

### Technical Innovation
- **LLM Tool Calling** - Bedrock extracts structured parameters from natural language
- **Hybrid Approach** - LLM for complex queries, fallback for simple ones
- **MCP Protocol** - AgentCore Gateway exposes APIs as standardized tools
- **Complete Observability** - CloudWatch logs show entire request flow

## 🚀 Quick Start

### Prerequisites
- AWS Account
- AWS CLI configured
- Python 3.8+
- Git

### 1. Clone Repository
```bash
git clone https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock.git
cd agentcore-api-gateway-integration-bedrock
```

### 2. Deploy Infrastructure
```bash
# Create DynamoDB table
aws dynamodb create-table \
  --table-name PetStore \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Create Lambda execution role
aws iam create-role \
  --role-name PetStoreLambdaRole \
  --assume-role-policy-document file://iam/lambda-trust-policy.json

# Attach policies
aws iam put-role-policy \
  --role-name PetStoreLambdaRole \
  --policy-name BedrockInvokePolicy \
  --policy-document file://iam/bedrock-policy.json

aws iam put-role-policy \
  --role-name PetStoreLambdaRole \
  --policy-name DynamoDBAccessPolicy \
  --policy-document file://iam/dynamodb-policy.json

# Deploy Lambda function
cd lambda
zip lambda.zip lambda_function.py
aws lambda create-function \
  --function-name PetStoreFunction \
  --runtime python3.11 \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/PetStoreLambdaRole \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda.zip \
  --timeout 30 \
  --memory-size 256 \
  --region us-east-1

# Create API Gateway (see api-gateway/ for detailed steps)
# Create Cognito User Pool (see cognito/ for detailed steps)
# Create AgentCore Gateway (see agentcore/ for detailed steps)
```

### 3. Deploy Frontend
```bash
# Create S3 bucket
aws s3 mb s3://YOUR-BUCKET-NAME --region us-east-1

# Configure for static website hosting
aws s3 website s3://YOUR-BUCKET-NAME \
  --index-document petstore-chat-secure.html

# Upload HTML
aws s3 cp frontend/petstore-chat-secure.html s3://YOUR-BUCKET-NAME/

# Make public
aws s3api put-bucket-policy \
  --bucket YOUR-BUCKET-NAME \
  --policy file://s3/bucket-policy.json
```

### 4. Test
```bash
# Open in browser
open http://YOUR-BUCKET-NAME.s3-website-us-east-1.amazonaws.com/petstore-chat-secure.html

# Login with test user
Username: testuser
Password: MySecurePass123!

# Try queries:
# - "List all pets"
# - "Show me expensive dogs"
# - "Cheap cats under $200"
# - "Add a dog named Max, breed: Golden Retriever, age: 3, price: $500"
```

## 📊 Use Cases

### 1. Natural Language Queries
**User:** "Show me expensive dogs under $700"

**What Happens:**
1. Frontend sends raw query to `/pets/query`
2. Lambda calls Bedrock Converse API
3. LLM understands intent and calls `filter_pets` tool:
   ```json
   {
     "type_filter": "dog",
     "max_price": 700,
     "sort_by": "price_desc"
   }
   ```
4. Lambda applies filters to DynamoDB data
5. Returns sorted results with "🤖 AI-powered" badge

**Cost:** ~$0.0001 per query

### 2. Simple CRUD Operations
**User:** "Add a dog named Max, breed: Golden Retriever, age: 3, price: $500"

**What Happens:**
1. Frontend regex extracts parameters
2. Direct POST to `/pets` endpoint
3. Lambda writes to DynamoDB
4. Returns success confirmation

**Cost:** Free (no LLM call)

### 3. List Operations
**User:** "List all pets"

**What Happens:**
1. Frontend sends to `/pets/query`
2. Lambda uses fallback (no LLM needed)
3. DynamoDB scan returns all pets
4. Displays results

**Cost:** Free (fallback mode)

## 🔍 How It Works

### LLM Tool Calling Flow

```python
# Lambda calls Bedrock with tool definition
response = bedrock.converse(
    modelId="us.amazon.nova-micro-v1:0",
    messages=[{"role": "user", "content": [{"text": query}]}],
    toolConfig={
        "tools": [{
            "toolSpec": {
                "name": "filter_pets",
                "description": "Filter and sort pets",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "type_filter": {"type": "string"},
                        "max_price": {"type": "number"},
                        "min_price": {"type": "number"},
                        "sort_by": {"type": "string"}
                    }
                }
            }
        }]
    }
)

# LLM returns structured parameters
# Lambda applies filters to DynamoDB results
```

### Complete Request Flow (with Logs)

See [docs/COMPLETE_FLOW_WITH_LOGS.md](docs/COMPLETE_FLOW_WITH_LOGS.md) for actual CloudWatch logs showing:
- Browser request
- API Gateway invocation
- Lambda execution
- Bedrock API call
- DynamoDB query
- Response timing (~600ms total)

## 📁 Repository Structure

```
.
├── README.md                          # This file
├── docs/
│   ├── ARCHITECTURE.md                # Detailed architecture diagrams
│   ├── COMPLETE_FLOW_WITH_LOGS.md     # Request flow with actual logs
│   ├── DEMO_QUESTIONS.md              # What you can/can't ask
│   ├── SECURITY_IMPROVEMENTS.md       # Security best practices
│   └── COST_ANALYSIS.md               # Cost breakdown
├── lambda/
│   ├── lambda_function.py             # Main Lambda code
│   └── requirements.txt               # Python dependencies
├── frontend/
│   └── petstore-chat-secure.html      # Browser interface
├── iam/
│   ├── lambda-trust-policy.json       # Lambda execution role trust
│   ├── bedrock-policy.json            # Bedrock invoke permissions
│   ├── dynamodb-policy.json           # DynamoDB access
│   └── agentcore-gateway-role.json    # AgentCore Gateway role
├── api-gateway/
│   ├── openapi-spec.yaml              # API Gateway definition
│   └── deployment-steps.md            # Step-by-step setup
├── cognito/
│   ├── user-pool-config.json          # Cognito configuration
│   └── setup-steps.md                 # Authentication setup
├── agentcore/
│   ├── gateway-config.json            # Gateway target configuration
│   └── setup-steps.md                 # MCP gateway setup
├── s3/
│   └── bucket-policy.json             # Public read policy
└── scripts/
    ├── deploy.sh                      # Full deployment script
    ├── cleanup.sh                     # Resource cleanup
    └── test-queries.sh                # Test various queries
```

## 🎓 What You'll Learn

1. **AgentCore Gateway** - How to expose APIs as MCP tools
2. **Bedrock Integration** - LLM tool calling for parameter extraction
3. **Serverless Architecture** - Lambda + API Gateway + DynamoDB
4. **Secure Authentication** - Cognito without hardcoded credentials
5. **Cost Optimization** - Using cheapest models with fallback strategies
6. **Observability** - CloudWatch logs for debugging and monitoring

## 💰 Cost Analysis

### Per Query Costs
- **LLM Query (complex):** ~$0.0001 (Nova Micro)
- **Simple Query (fallback):** $0.00 (no LLM call)
- **Lambda Execution:** ~$0.0000002 per request
- **DynamoDB Read:** ~$0.00000025 per item
- **API Gateway:** ~$0.0000035 per request

### Monthly Estimate (1000 queries)
- **LLM Calls (50%):** $0.05
- **Lambda:** $0.0002
- **DynamoDB:** $0.0003
- **API Gateway:** $0.0035
- **Total:** ~$0.054/month

**Essentially free for demo purposes!**

## 🔒 Security Features

1. **No Hardcoded Credentials** - User enters credentials at login
2. **JWT Authentication** - Cognito tokens for API access
3. **IAM Roles** - Least privilege access for Lambda
4. **CORS Configuration** - Proper cross-origin handling
5. **Input Validation** - Regex and type checking

### Production Recommendations
- Use Cognito Hosted UI
- Enable HTTPS with CloudFront
- Add rate limiting
- Implement request signing
- Enable CloudWatch alarms

## 📈 Monitoring & Debugging

### CloudWatch Logs
```bash
# Lambda logs
aws logs tail /aws/lambda/PetStoreFunction --follow

# API Gateway logs (enable first)
aws logs tail /aws/apigateway/66gd6g08ie/prod --follow
```

### Key Metrics
- Lambda duration: ~600ms average
- LLM call: ~400ms
- DynamoDB query: ~50ms
- Cold start: ~2s (first request)

## 🧪 Testing

### Manual Testing
```bash
# Test LLM endpoint
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/pets/query \
  -H "Content-Type: application/json" \
  -d '{"query":"expensive dogs under 700"}'

# Test add pet
curl -X POST https://YOUR-API-ID.execute-api.us-east-1.amazonaws.com/prod/pets \
  -H "Content-Type: application/json" \
  -d '{"name":"Max","type":"dog","breed":"Labrador","age":3,"price":500}'
```

### Automated Tests
```bash
cd scripts
./test-queries.sh
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- AWS Bedrock team for Nova Micro model
- AWS AgentCore team for MCP gateway
- Community feedback and testing

## 📞 Support

- **Issues:** https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock/issues
- **Discussions:** https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock/discussions

## 🎯 Next Steps

1. **Try the Demo** - Follow Quick Start guide
2. **Read the Docs** - Understand the architecture
3. **Customize** - Adapt for your use case
4. **Deploy** - Take it to production
5. **Share** - Star the repo and spread the word!

---

**Built with ❤️ using AWS Serverless + AI**
