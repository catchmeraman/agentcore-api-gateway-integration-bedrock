# Architecture Deep Dive

## System Components

### 1. Frontend (Browser)
**File:** `frontend/petstore-chat-secure.html`

**Responsibilities:**
- User authentication via Cognito
- Message display and input handling
- API calls to backend
- Response formatting

**Key Features:**
- No business logic (all in backend)
- Session management with sessionStorage
- Error handling and user feedback
- Responsive design

**Security:**
- No hardcoded credentials
- JWT token authentication
- CORS-compliant requests

### 2. AWS Cognito
**Purpose:** User authentication and authorization

**Configuration:**
- User Pool ID: `us-east-1_RNmMBC87g`
- Client ID: `435iqd7cgbn2slmgn0a36fo9lf`
- Auth Flow: `USER_PASSWORD_AUTH`

**Features:**
- Password policies
- MFA support (optional)
- User management
- Token generation

### 3. API Gateway
**Type:** REST API
**ID:** `66gd6g08ie`
**Stage:** `prod`

**Endpoints:**

| Method | Path | Purpose | Integration |
|--------|------|---------|-------------|
| GET | /pets | List all pets | Lambda Proxy |
| GET | /pets/{petId} | Get specific pet | Lambda Proxy |
| POST | /pets | Add new pet | Lambda Proxy |
| POST | /pets/query | LLM-powered query | Lambda Proxy |
| OPTIONS | /* | CORS preflight | Lambda Proxy |

**CORS Configuration:**
```json
{
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,Accept"
}
```

### 4. Lambda Function
**Name:** `PetStoreFunction`
**Runtime:** Python 3.11
**Memory:** 256 MB
**Timeout:** 30 seconds

**Handler:** `lambda_function.lambda_handler`

**Key Functions:**

#### a) OPTIONS Handler (CORS)
```python
if event['httpMethod'] == 'OPTIONS':
    return {
        'statusCode': 200,
        'headers': cors_headers,
        'body': ''
    }
```

#### b) GET /pets - List All
```python
response = dynamodb.scan(TableName='PetStore')
pets = response.get('Items', [])
return {'statusCode': 200, 'body': json.dumps(pets)}
```

#### c) POST /pets - Add Pet
```python
pet_data = json.loads(event['body'])
pet_data['id'] = str(uuid.uuid4())
dynamodb.put_item(TableName='PetStore', Item=pet_data)
```

#### d) POST /pets/query - LLM Query
```python
# Try LLM first
try:
    result = query_with_llm(query)
except Exception as e:
    # Fallback to keyword matching
    result = simple_filter(query)
```

**LLM Integration:**
```python
def query_with_llm(query):
    response = bedrock.converse(
        modelId="us.amazon.nova-micro-v1:0",
        messages=[{
            "role": "user",
            "content": [{"text": query}]
        }],
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
    
    # Extract tool call
    tool_use = response['output']['message']['content'][0]
    params = tool_use['toolUse']['input']
    
    # Apply filters to DynamoDB data
    return filter_pets(**params)
```

### 5. Amazon Bedrock
**Model:** Nova Micro (`us.amazon.nova-micro-v1:0`)
**API:** Converse API with tool calling

**Why Nova Micro?**
- Cheapest model (~$0.0001 per query)
- Fast response time (~400ms)
- Sufficient for parameter extraction
- Supports tool calling

**Tool Definition:**
```json
{
  "name": "filter_pets",
  "description": "Filter and sort pets based on criteria",
  "inputSchema": {
    "type": "object",
    "properties": {
      "type_filter": {
        "type": "string",
        "description": "Pet type (dog, cat, etc.)"
      },
      "max_price": {
        "type": "number",
        "description": "Maximum price"
      },
      "min_price": {
        "type": "number",
        "description": "Minimum price"
      },
      "sort_by": {
        "type": "string",
        "enum": ["price_asc", "price_desc", "age_asc", "age_desc"],
        "description": "Sort order"
      }
    }
  }
}
```

### 6. DynamoDB
**Table:** `PetStore`
**Partition Key:** `id` (String)
**Billing:** On-demand

**Schema:**
```json
{
  "id": "string (UUID)",
  "name": "string",
  "type": "string (dog|cat|bird|...)",
  "breed": "string",
  "age": "number",
  "price": "number"
}
```

**Sample Data:**
```json
{
  "id": "1",
  "name": "Buddy",
  "type": "dog",
  "breed": "Golden Retriever",
  "age": 3,
  "price": 500
}
```

### 7. AgentCore Gateway (Optional)
**Gateway ID:** `petstoregateway-remqjziohl`
**Protocol:** MCP (Model Context Protocol)

**Purpose:**
- Expose API endpoints as standardized tools
- Enable integration with AI agents
- Provide tool discovery

**Target Configuration:**
```json
{
  "name": "PetStoreTarget",
  "targetConfiguration": {
    "mcp": {
      "apiGateway": {
        "restApiId": "66gd6g08ie",
        "stage": "prod",
        "toolOverrides": [
          {
            "name": "ListPets",
            "path": "/pets",
            "method": "GET"
          },
          {
            "name": "QueryPets",
            "path": "/pets/query",
            "method": "POST"
          }
        ]
      }
    }
  }
}
```

## Data Flow Diagrams

### Query Flow (LLM-Powered)

```
┌─────────┐
│ Browser │
└────┬────┘
     │ 1. POST /pets/query
     │    {"query": "expensive dogs"}
     ▼
┌─────────────┐
│ API Gateway │
└──────┬──────┘
       │ 2. Lambda Proxy Integration
       ▼
┌──────────────┐
│    Lambda    │
└──┬────────┬──┘
   │        │
   │ 3a.    │ 3b. Scan
   │ Converse  │
   ▼        ▼
┌─────────┐ ┌──────────┐
│ Bedrock │ │ DynamoDB │
│  Nova   │ │ PetStore │
│  Micro  │ └──────────┘
└────┬────┘
     │ 4. Tool Call Response
     │    {type_filter: "dog", sort_by: "price_desc"}
     ▼
┌──────────────┐
│    Lambda    │
│ (Apply       │
│  Filters)    │
└──────┬───────┘
       │ 5. Filtered Results
       ▼
┌─────────────┐
│ API Gateway │
└──────┬──────┘
       │ 6. JSON Response
       ▼
┌─────────┐
│ Browser │
│ Display │
└─────────┘
```

### Add Pet Flow

```
┌─────────┐
│ Browser │
└────┬────┘
     │ 1. POST /pets
     │    {name, type, breed, age, price}
     ▼
┌─────────────┐
│ API Gateway │
└──────┬──────┘
       │ 2. Lambda Proxy
       ▼
┌──────────────┐
│    Lambda    │
│              │
│ • Generate   │
│   UUID       │
│ • Validate   │
│   Data       │
└──────┬───────┘
       │ 3. PutItem
       ▼
┌──────────────┐
│  DynamoDB    │
│  PetStore    │
└──────┬───────┘
       │ 4. Success
       ▼
┌──────────────┐
│    Lambda    │
└──────┬───────┘
       │ 5. Confirmation
       ▼
┌─────────────┐
│ API Gateway │
└──────┬──────┘
       │ 6. JSON Response
       ▼
┌─────────┐
│ Browser │
└─────────┘
```

## Security Architecture

### Authentication Flow

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. Enter credentials
     ▼
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ 2. InitiateAuth
       ▼
┌─────────────────┐
│  AWS Cognito    │
│  User Pool      │
└──────┬──────────┘
       │ 3. JWT Tokens
       │    • AccessToken
       │    • IdToken
       │    • RefreshToken
       ▼
┌─────────────┐
│   Browser   │
│ (Store in   │
│  session)   │
└──────┬──────┘
       │ 4. API calls with
       │    Authorization: Bearer <token>
       ▼
┌─────────────┐
│ API Gateway │
│ (Optional   │
│  Cognito    │
│  Authorizer)│
└─────────────┘
```

### IAM Permissions

**Lambda Execution Role:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "bedrock:InvokeModel",
      "Resource": [
        "arn:aws:bedrock:*::foundation-model/*",
        "arn:aws:bedrock:*:*:inference-profile/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:Scan",
        "dynamodb:PutItem",
        "dynamodb:GetItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/PetStore"
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
```

## Performance Characteristics

### Latency Breakdown

**Cold Start (First Request):**
- Lambda initialization: ~2000ms
- Total: ~2600ms

**Warm Request (LLM Query):**
- API Gateway: ~10ms
- Lambda execution: ~50ms
- Bedrock API call: ~400ms
- DynamoDB scan: ~50ms
- Response formatting: ~10ms
- **Total: ~520ms**

**Warm Request (Simple Query):**
- API Gateway: ~10ms
- Lambda execution: ~30ms
- DynamoDB scan: ~50ms
- Response formatting: ~10ms
- **Total: ~100ms**

### Scalability

**Concurrent Requests:**
- Lambda: 1000 concurrent executions (default)
- API Gateway: Unlimited
- DynamoDB: On-demand (auto-scales)
- Bedrock: 100 requests/second (default)

**Bottlenecks:**
- Bedrock rate limits (can request increase)
- Lambda cold starts (use provisioned concurrency)

## Monitoring & Observability

### CloudWatch Metrics

**Lambda:**
- Invocations
- Duration
- Errors
- Throttles
- Concurrent Executions

**API Gateway:**
- Count
- Latency
- 4XXError
- 5XXError

**DynamoDB:**
- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- UserErrors
- SystemErrors

### CloudWatch Logs

**Log Groups:**
- `/aws/lambda/PetStoreFunction`
- `/aws/apigateway/66gd6g08ie/prod` (if enabled)

**Key Log Patterns:**
```
# LLM Success
"LLM extracted parameters: {type_filter: 'dog', sort_by: 'price_desc'}"

# LLM Fallback
"LLM Error: ... Falling back to keyword matching"

# Request Timing
"Duration: 520.45 ms  Billed Duration: 521 ms"
```

### X-Ray Tracing (Optional)

Enable for detailed request tracing:
```bash
aws lambda update-function-configuration \
  --function-name PetStoreFunction \
  --tracing-config Mode=Active
```

## Disaster Recovery

### Backup Strategy

**DynamoDB:**
- Point-in-time recovery (enable)
- On-demand backups
- Cross-region replication (optional)

**Lambda:**
- Code stored in S3 (automatic)
- Version control in Git

**Configuration:**
- Infrastructure as Code (CloudFormation/Terraform)
- All configs in Git repository

### Recovery Procedures

**Lambda Failure:**
1. Check CloudWatch logs
2. Rollback to previous version
3. Redeploy if needed

**DynamoDB Failure:**
1. Restore from backup
2. Verify data integrity
3. Update application if needed

**API Gateway Failure:**
1. Check deployment history
2. Redeploy to stage
3. Update DNS if needed

## Future Enhancements

### Phase 2
- [ ] Add update/delete operations
- [ ] Implement pagination
- [ ] Add image upload for pets
- [ ] Multi-language support

### Phase 3
- [ ] Real-time updates (WebSocket)
- [ ] Advanced analytics
- [ ] Recommendation engine
- [ ] Mobile app

### Phase 4
- [ ] Multi-region deployment
- [ ] CDN integration
- [ ] Advanced caching
- [ ] A/B testing framework
