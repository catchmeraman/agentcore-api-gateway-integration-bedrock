# PetStore Lambda Function Documentation

## Overview

This AWS Lambda function implements a REST API for a pet store application with AI-powered natural language query capabilities. It integrates with DynamoDB for data storage and Amazon Bedrock for intelligent query processing.

## Architecture Components

### AWS Services Used
- **AWS Lambda**: Serverless compute for API handling
- **Amazon DynamoDB**: NoSQL database (table: `PetStore`)
- **Amazon Bedrock**: AI/LLM service for natural language query processing (model: `us.amazon.nova-micro-v1:0`)

### Dependencies
```python
import json
import boto3
from decimal import Decimal
```

## API Endpoints

### 1. OPTIONS (Preflight) - All Paths
**Purpose**: Handle CORS preflight requests from browsers

**Response Headers**:
- `Access-Control-Allow-Origin: *` - Allow all origins
- `Access-Control-Allow-Methods: GET,POST,OPTIONS`
- `Access-Control-Allow-Headers: Content-Type,Authorization`
- `Access-Control-Max-Age: 86400` - Cache preflight for 24 hours

### 2. POST /pets/query
**Purpose**: Natural language query interface powered by AI

**Request Body**:
```json
{
  "query": "Show me 5 cheapest dogs"
}
```

**Process Flow**:
1. Scans all pets from DynamoDB
2. Sends user query to Bedrock LLM with tool definition
3. LLM analyzes query and calls `filter_pets` tool with parameters
4. Applies filters (type, price range, sorting, limit)
5. Returns filtered results

**Response**:
```json
{
  "pets": [...],
  "count": 15,
  "filters_applied": {
    "type_filter": "dog",
    "sort_by": "price_asc",
    "limit": 5
  }
}
```

**Supported Query Patterns**:
- Type filtering: "show me cats", "list all dogs"
- Price filtering: "pets under $200", "between $100 and $300"
- Sorting: "cheapest pets", "oldest animals", "sort by name"
- Limiting: "top 5 pets", "show 3 results"

### 3. GET /pets
**Purpose**: Retrieve all pets from the store

**Response**:
```json
[
  {
    "id": 1,
    "name": "Buddy",
    "type": "dog",
    "breed": "Golden Retriever",
    "age": 3,
    "price": 500
  }
]
```

### 4. POST /pets
**Purpose**: Add a new pet to the store

**Request Body**:
```json
{
  "name": "Max",
  "type": "dog",
  "breed": "Labrador",
  "age": 2,
  "price": 450
}
```

**Process**:
1. Scans existing pet IDs
2. Generates next sequential ID (max + 1)
3. Creates pet object with defaults for missing fields
4. Stores in DynamoDB

**Response** (201 Created):
```json
{
  "id": 5,
  "name": "Max",
  "type": "dog",
  "breed": "Labrador",
  "age": 2,
  "price": 450
}
```

## Core Functions

### `lambda_handler(event, context)`
Main entry point for Lambda execution.

**Parameters**:
- `event`: API Gateway proxy event containing HTTP request data
- `context`: Lambda runtime context

**Event Structure**:
```python
{
  'path': '/pets',
  'httpMethod': 'GET',
  'body': '{"name": "Buddy"}',
  'headers': {...}
}
```

### `query_with_llm(user_query, pets)`
AI-powered query processor using Amazon Bedrock.

**Tool Definition**:
Defines a `filter_pets` tool with schema for the LLM to use:
- `type_filter`: Pet type (dog, cat, bird, etc.)
- `sort_by`: Sorting method (price_asc, price_desc, age_asc, age_desc, name)
- `max_price`: Maximum price filter
- `min_price`: Minimum price filter
- `limit`: Result count limit

**LLM Interaction**:
1. Calls Bedrock Converse API with tool configuration
2. LLM analyzes natural language query
3. LLM invokes `filter_pets` tool with appropriate parameters
4. Function applies filters and returns results

**Error Handling**:
Falls back to `simple_filter()` if Bedrock call fails.

### `simple_filter(query, pets)`
Fallback filtering using basic keyword matching.

**Logic**:
- Detects pet types (dog, cat, bird, fish) in query text
- Identifies price sorting keywords (expensive, cheap, affordable)
- Returns top 10 results

## Data Model

### Pet Object Schema
```python
{
  'id': int,           # Auto-generated sequential ID
  'name': str,         # Pet name (default: 'Unknown')
  'type': str,         # Pet type (default: 'unknown')
  'breed': str,        # Breed (default: 'Mixed')
  'age': int,          # Age in years (default: 1)
  'price': int         # Price in dollars (default: 100)
}
```

## CORS Configuration

All endpoints return CORS headers to allow cross-origin requests:
```python
'Access-Control-Allow-Origin': '*'
'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
'Access-Control-Allow-Headers': 'Content-Type,Authorization'
```

## Error Handling

### 404 Not Found
Returned when path/method combination doesn't match any endpoint:
```json
{
  "error": "Not found"
}
```

### LLM Fallback
If Bedrock API fails, the function automatically falls back to simple keyword-based filtering to ensure service availability.

## AI/LLM Integration Details

### Model Selection
Uses `us.amazon.nova-micro-v1:0` - Amazon's cheapest Bedrock model for cost optimization.

### Tool-Based Approach
Implements function calling pattern where:
1. LLM receives tool definition with structured schema
2. LLM analyzes user intent
3. LLM generates structured tool call with parameters
4. Lambda executes filtering logic based on tool parameters

### Benefits
- Natural language interface for non-technical users
- Flexible query patterns without hardcoded logic
- Extensible through tool definition updates

## Performance Considerations

### DynamoDB Scans
- Uses `table.scan()` which reads entire table
- Suitable for small datasets
- For production with large datasets, consider:
  - Query with indexes
  - Pagination
  - Caching layer

### ID Generation
- Scans all IDs to find max value
- Consider using DynamoDB atomic counters for better performance

## Security Notes

1. **CORS**: Currently allows all origins (`*`) - restrict in production
2. **Authentication**: No authentication implemented - add API Gateway authorizers
3. **Input Validation**: Minimal validation - add comprehensive checks
4. **IAM Permissions Required**:
   - `dynamodb:Scan`
   - `dynamodb:PutItem`
   - `bedrock:InvokeModel` (Converse API)

## Example Usage

### Natural Language Queries
```bash
# Find cheap dogs
curl -X POST https://api.example.com/pets/query \
  -d '{"query": "show me 5 cheapest dogs"}'

# Find cats under $300
curl -X POST https://api.example.com/pets/query \
  -d '{"query": "list cats under 300 dollars"}'

# Find oldest pets
curl -X POST https://api.example.com/pets/query \
  -d '{"query": "show oldest animals"}'
```

### Standard REST Operations
```bash
# List all pets
curl https://api.example.com/pets

# Add new pet
curl -X POST https://api.example.com/pets \
  -d '{"name": "Whiskers", "type": "cat", "breed": "Persian", "age": 2, "price": 400}'
```

## Future Enhancements

1. **Pagination**: Add limit/offset for large result sets
2. **Individual Pet Operations**: GET/PUT/DELETE by ID
3. **Advanced Filters**: Age ranges, breed search, availability status
4. **Caching**: Redis/ElastiCache for frequently accessed data
5. **Authentication**: Cognito or API key-based auth
6. **Monitoring**: CloudWatch metrics and alarms
7. **Validation**: Pydantic models for request/response validation
