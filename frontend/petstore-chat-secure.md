# PetStore Chat Secure - Frontend Documentation

## Overview

A secure, AI-powered chat interface for the PetStore application that integrates with AWS Cognito for authentication and Amazon Bedrock AgentCore Gateway for API communication using the Model Context Protocol (MCP).

## Architecture

### Technology Stack
- **Frontend**: Pure HTML/CSS/JavaScript (no frameworks)
- **Authentication**: AWS Cognito User Pools
- **API Gateway**: Amazon Bedrock AgentCore Gateway (MCP Protocol)
- **Backend**: AWS Lambda + DynamoDB + Bedrock
- **Protocol**: JSON-RPC 2.0 (MCP standard)

### Key Components
1. **Login System**: Cognito-based authentication
2. **Chat Interface**: Real-time messaging UI
3. **MCP Client**: JSON-RPC 2.0 protocol implementation
4. **Natural Language Processing**: Query parsing and tool selection

## Configuration

```javascript
const CONFIG = {
    userPoolId: 'us-east-1_RNmMBC87g',
    clientId: '435iqd7cgbn2slmgn0a36fo9lf',
    region: 'us-east-1',
    gatewayUrl: 'https://petstoregateway-remqjziohl.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp'
};
```

### Configuration Parameters
- **userPoolId**: AWS Cognito User Pool identifier
- **clientId**: Cognito App Client ID
- **region**: AWS region for Cognito service
- **gatewayUrl**: AgentCore Gateway endpoint (MCP protocol)

## Authentication Flow

### 1. Login Process

```javascript
async function login()
```

**Steps**:
1. Collects username and password from form
2. Calls Cognito `InitiateAuth` API directly via HTTPS
3. Uses `USER_PASSWORD_AUTH` flow
4. Receives `AccessToken` on success
5. Stores token in `sessionStorage`
6. Transitions to chat interface

**API Call**:
```javascript
fetch(`https://cognito-idp.${region}.amazonaws.com/`, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
    },
    body: JSON.stringify({
        AuthFlow: 'USER_PASSWORD_AUTH',
        ClientId: CONFIG.clientId,
        AuthParameters: {
            USERNAME: username,
            PASSWORD: password
        }
    })
})
```

**Response Handling**:
- Success: `data.AuthenticationResult.AccessToken`
- Error: `data.__type` or `data.message`

### 2. Session Management

- **Storage**: `sessionStorage.setItem('accessToken', token)`
- **Persistence**: Token persists during browser session
- **Auto-login**: Checks `sessionStorage` on page load
- **Security**: Token cleared when browser tab closes

## Chat Interface

### UI Components

#### 1. Login Form
```html
<div class="login-form">
    <input type="text" id="username" value="testuser">
    <input type="password" id="password">
    <button id="loginBtn">Sign In</button>
</div>
```

#### 2. Chat Messages
```html
<div id="chatMessages">
    <div class="message user">
        <div class="message-content">User message</div>
    </div>
    <div class="message assistant">
        <div class="message-content">Assistant response</div>
    </div>
</div>
```

#### 3. Input Container
```html
<div class="input-container">
    <input type="text" id="userInput" placeholder="Try: 'List all pets'">
    <button id="sendBtn">Send</button>
</div>
```

### Styling Features

- **Gradient Background**: Purple-blue gradient (`#667eea` to `#764ba2`)
- **Responsive Design**: 90% width, max 600px
- **Message Bubbles**: User (purple) vs Assistant (gray)
- **Auto-scroll**: Messages container scrolls to bottom
- **Disabled State**: Send button disabled during API calls

## MCP Protocol Implementation

### Model Context Protocol (MCP)

MCP is a standardized protocol for AI agents to interact with tools and resources. This application implements the MCP client side using JSON-RPC 2.0.

### JSON-RPC 2.0 Request Format

```javascript
{
    jsonrpc: '2.0',
    id: Date.now(),
    method: 'tools/call',
    params: {
        name: 'PetStoreTarget___AddPet',
        arguments: { name: 'Max', type: 'dog', ... }
    }
}
```

### Available MCP Tools

#### 1. PetStoreTarget___ListPets
**Purpose**: Retrieve all pets from the store

**Arguments**: None

**Usage**: Simple queries like "list all pets", "show pets"

**Example**:
```javascript
{
    name: 'PetStoreTarget___ListPets',
    arguments: {}
}
```

#### 2. PetStoreTarget___QueryPets
**Purpose**: Natural language query with AI filtering

**Arguments**:
- `query` (string): Natural language query

**Usage**: Complex queries with filters, sorting, limits

**Examples**:
- "Show me 5 cheapest dogs"
- "List cats under $300"
- "Find oldest pets"

**Example**:
```javascript
{
    name: 'PetStoreTarget___QueryPets',
    arguments: { query: 'Show me 5 cheapest dogs' }
}
```

#### 3. PetStoreTarget___AddPet
**Purpose**: Add a new pet to the store

**Arguments**:
- `name` (string): Pet name
- `type` (string): Pet type (dog, cat, bird, fish, hamster, rabbit, turtle, guinea pig, lizard, frog)
- `breed` (string): Breed (default: 'Mixed')
- `age` (integer): Age in years (default: 1)
- `price` (integer): Price in dollars (default: 100)

**Example**:
```javascript
{
    name: 'PetStoreTarget___AddPet',
    arguments: {
        name: 'Max',
        type: 'dog',
        breed: 'Golden Retriever',
        age: 3,
        price: 500
    }
}
```

## Message Processing Flow

### 1. User Input Parsing

```javascript
async function handleMessage(userMessage)
```

**Decision Logic**:

```
User Message
    |
    ├─ Contains "add" → Extract pet details → AddPet tool
    |
    ├─ Simple "list all" → ListPets tool
    |
    └─ Complex query → QueryPets tool (AI-powered)
```

### 2. Pet Details Extraction (for AddPet)

Uses regex patterns to extract:

```javascript
// Name extraction
const nameMatch = userMessage.match(/name[d:\s]+([A-Z][a-z]+)/i);

// Type extraction (validates against allowed types)
const typeMatch = userMessage.match(/\b(dog|cat|bird|fish|hamster|rabbit|turtle|guinea pig|lizard|frog)\b/i);

// Breed extraction
const breedMatch = userMessage.match(/breed[:\s]+([A-Za-z\s]+?)(?:,|age|\.|$)/i);

// Age extraction
const ageMatch = userMessage.match(/age[:\s]+(\d+)/i);

// Price extraction
const priceMatch = userMessage.match(/price[:\s]+\$?(\d+)/i) || userMessage.match(/\$(\d+)/);
```

**Validation**:
- Pet type must be in allowed list
- Name is required for AddPet
- Other fields use defaults if missing

### 3. Tool Selection Logic

```javascript
if (msg.includes('add')) {
    // AddPet tool
} else if ((msg.includes('list') || msg.includes('all')) && 
           !msg.includes('costlier') && 
           !msg.includes('cheaper') && 
           msg.split(' ').length <= 3) {
    // ListPets tool (simple queries only)
} else {
    // QueryPets tool (complex queries)
}
```

**ListPets Conditions**:
- Contains "list" or "all"
- Does NOT contain filter keywords (costlier, cheaper, expensive, under, over)
- Short query (≤3 words)

### 4. API Communication

```javascript
const res = await fetch(CONFIG.gatewayUrl, {
    method: 'POST',
    headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
    },
    body: JSON.stringify({
        jsonrpc: '2.0',
        id: Date.now(),
        method: 'tools/call',
        params: {
            name: toolName,
            arguments: toolArgs
        }
    })
});
```

**Authorization**: Bearer token from Cognito login

### 5. Response Parsing

```javascript
const mcpResponse = await res.json();
if (mcpResponse.error) {
    throw new Error(mcpResponse.error.message);
}

const result = JSON.parse(mcpResponse.result.content[0].text);
```

**MCP Response Structure**:
```javascript
{
    jsonrpc: '2.0',
    id: 123456789,
    result: {
        content: [
            { text: '{"pets": [...], "count": 10}' }
        ]
    }
}
```

## Response Formatting

### AddPet Response

```javascript
✅ Added Max! (via AgentCore Gateway)

🐾 Max
Type: dog
Breed: Golden Retriever
Age: 3 years
Price: $500
```

### ListPets/QueryPets Response

```javascript
Found 15 pets (🤖 AI via AgentCore Gateway → Bedrock):

🐾 Buddy - dog (Golden Retriever)
   Age: 3 years | Price: $500

🐾 Whiskers - cat (Persian)
   Age: 2 years | Price: $400

(13 more available)
```

**Response Components**:
- **Count Summary**: "Found X pets" or "Showing X of Y pets"
- **AI Indicator**: Shows if Bedrock AI was used for filtering
- **Pet Details**: Name, type, breed, age, price
- **Pagination Info**: Shows if more results available

### AI Filter Detection

```javascript
if (result.filters_applied && !result.filters_applied.fallback) {
    response += ` (🤖 AI via AgentCore Gateway → Bedrock)`;
} else {
    response += ` (via AgentCore Gateway)`;
}
```

Shows "🤖 AI" badge when Bedrock LLM processed the query.

## Error Handling

### Login Errors

```javascript
if (data.AuthenticationResult) {
    // Success
} else if (data.__type) {
    errorDiv.textContent = data.message || data.__type;
} else {
    errorDiv.textContent = 'Invalid credentials';
}
```

**Common Errors**:
- `NotAuthorizedException`: Wrong password
- `UserNotFoundException`: User doesn't exist
- `UserNotConfirmedException`: Email not verified

### API Errors

```javascript
try {
    const response = await handleMessage(message);
    addMessage('assistant', response);
} catch (error) {
    addMessage('assistant', '❌ Error: ' + error.message);
}
```

**Error Types**:
- HTTP errors (4xx, 5xx)
- MCP protocol errors
- JSON parsing errors
- Network errors

### Validation Errors

```javascript
if (!typeMatch) {
    return '❌ Invalid pet type. We only accept:\n• dog, cat, bird, fish\n• hamster, rabbit, turtle\n• guinea pig, lizard, frog';
}

if (!nameMatch) {
    return 'Please include pet name: "Add a dog named Max..."';
}
```

## Event Listeners

```javascript
// Login button
document.getElementById('loginBtn').addEventListener('click', login);

// Send button
document.getElementById('sendBtn').addEventListener('click', sendMessage);

// Enter key in chat input
document.getElementById('userInput').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendMessage();
});

// Enter key in password field
document.getElementById('password').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') login();
});
```

## Security Features

### 1. Authentication
- AWS Cognito User Pools
- Bearer token authorization
- Session-based token storage

### 2. HTTPS
- All API calls use HTTPS
- Secure token transmission

### 3. Token Management
- Stored in `sessionStorage` (not `localStorage`)
- Cleared on browser tab close
- Not exposed in URL or cookies

### 4. Input Validation
- Pet type whitelist
- Required field checks
- Regex-based extraction

## Usage Examples

### Example 1: Login
```
Username: testuser
Password: [user's password]
Click "Sign In"
```

### Example 2: List All Pets
```
User: "list all pets"
Tool: PetStoreTarget___ListPets
Response: Shows all pets in database
```

### Example 3: Natural Language Query
```
User: "Show me 5 cheapest dogs"
Tool: PetStoreTarget___QueryPets
AI Processing: Bedrock analyzes query
Filters Applied: type=dog, sort=price_asc, limit=5
Response: 5 cheapest dogs
```

### Example 4: Add Pet
```
User: "Add a dog named Max, breed: Golden Retriever, age: 3, price: $500"
Tool: PetStoreTarget___AddPet
Arguments: {name: 'Max', type: 'dog', breed: 'Golden Retriever', age: 3, price: 500}
Response: Confirmation with pet details
```

### Example 5: Complex Query
```
User: "Find cats under $300"
Tool: PetStoreTarget___QueryPets
AI Processing: Bedrock interprets "under $300" as max_price filter
Filters Applied: type=cat, max_price=300
Response: Filtered cat list
```

## Integration Points

### 1. AWS Cognito
- **Endpoint**: `https://cognito-idp.us-east-1.amazonaws.com/`
- **Method**: `InitiateAuth`
- **Flow**: `USER_PASSWORD_AUTH`

### 2. AgentCore Gateway
- **Endpoint**: `https://petstoregateway-remqjziohl.gateway.bedrock-agentcore.us-east-1.amazonaws.com/mcp`
- **Protocol**: JSON-RPC 2.0 (MCP)
- **Method**: `tools/call`
- **Auth**: Bearer token

### 3. Backend Lambda
- **Invoked by**: AgentCore Gateway
- **Tools**: ListPets, QueryPets, AddPet
- **Database**: DynamoDB (PetStore table)
- **AI**: Amazon Bedrock (Nova Micro model)

## Data Flow Diagram

```
User Input
    ↓
Frontend (petstore-chat-secure.html)
    ↓
Parse & Select Tool
    ↓
MCP Request (JSON-RPC 2.0)
    ↓
AgentCore Gateway (with Cognito token)
    ↓
Lambda Function (PetStoreFunction)
    ↓
┌─────────────┬──────────────┐
│             │              │
DynamoDB   Bedrock AI    Response
(PetStore)  (Nova Micro)     ↓
    │             │       Format & Display
    └─────────────┘           ↓
         ↓              User sees result
    Return Data
```

## Performance Considerations

### 1. UI Responsiveness
- Disable send button during API calls
- Show loading state implicitly
- Auto-scroll to latest message

### 2. API Efficiency
- Single API call per user message
- Efficient tool selection logic
- Minimal data transfer

### 3. Caching
- Session token cached in `sessionStorage`
- No redundant authentication calls

## Browser Compatibility

- **Modern Browsers**: Chrome, Firefox, Safari, Edge
- **Requirements**: ES6+ support (async/await, fetch API)
- **Mobile**: Responsive design works on mobile browsers

## Deployment

### Prerequisites
1. AWS Cognito User Pool configured
2. AgentCore Gateway deployed
3. Lambda function deployed
4. DynamoDB table created

### Configuration Steps
1. Update `CONFIG` object with your values
2. Host HTML file on web server or S3
3. Enable CORS on AgentCore Gateway
4. Test authentication flow

### Testing
1. Create test user in Cognito
2. Login with test credentials
3. Try each operation type:
   - List all pets
   - Natural language query
   - Add new pet

## Troubleshooting

### Login Issues
- **Problem**: "Invalid credentials"
- **Solution**: Verify Cognito User Pool ID and Client ID

### Gateway Errors
- **Problem**: HTTP 401 Unauthorized
- **Solution**: Check token validity, re-login if expired

### Tool Not Found
- **Problem**: MCP tool name mismatch
- **Solution**: Verify tool names match Gateway configuration

### CORS Errors
- **Problem**: Browser blocks request
- **Solution**: Configure CORS on AgentCore Gateway

## Future Enhancements

1. **Token Refresh**: Implement automatic token refresh
2. **Typing Indicator**: Show when assistant is processing
3. **Message History**: Persist chat history
4. **File Upload**: Support pet image uploads
5. **Voice Input**: Add speech-to-text
6. **Multi-language**: Support multiple languages
7. **Dark Mode**: Add theme toggle
8. **Offline Mode**: Cache responses for offline viewing
