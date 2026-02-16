# Manual Amplify Deployment with Custom Domain

## Your Page Already Has Login! ✅

The `petstore-chat-secure.html` already includes:
- ✅ Username/Password login form
- ✅ AWS Cognito authentication
- ✅ Session management
- ✅ No hardcoded credentials

**Default credentials:**
- Username: `testuser`
- Password: `********`

## Deploy via Amplify Console (5 minutes)

### Step 1: Open Amplify Console

1. Go to: https://console.aws.amazon.com/amplify/home?region=us-east-1
2. Click "New app" → "Host web app"

### Step 2: Connect GitHub

1. Choose "GitHub"
2. Authorize AWS Amplify
3. Select repository: `catchmeraman/agentcore-api-gateway-integration-bedrock`
4. Select branch: `main`
5. Click "Next"

### Step 3: Configure Build Settings

```yaml
version: 1
frontend:
  phases:
    build:
      commands:
        - echo "No build needed - static HTML"
  artifacts:
    baseDirectory: frontend
    files:
      - '**/*'
```

Click "Next"

### Step 4: Review and Deploy

1. Review settings
2. Click "Save and deploy"
3. Wait 2-3 minutes for deployment

**You'll get:** `https://main.d123abc.amplifyapp.com`

### Step 5: Add Custom Domain

1. In Amplify Console → Domain management
2. Click "Add domain"
3. Enter: `cloudopsinsights.com`
4. Add subdomain: `petstore`
5. Click "Configure domain"

**Amplify will:**
- ✅ Create SSL certificate automatically
- ✅ Show DNS records to add
- ✅ Validate certificate
- ✅ Configure domain

### Step 6: Add DNS Records

Amplify will show you records like:

**For SSL validation:**
```
Name:  _abc123.cloudopsinsights.com
Type:  CNAME
Value: _xyz456.acm-validations.aws.
```

**For domain:**
```
Name:  petstore
Type:  CNAME (or ANAME/ALIAS)
Value: d123abc.cloudfront.net
```

Add these to your DNS provider (Route 53, GoDaddy, etc.)

### Step 7: Wait for Deployment

- SSL validation: 5-10 minutes
- DNS propagation: 5-10 minutes
- **Total: ~15 minutes**

## Result

✅ **https://petstore.cloudopsinsights.com**
- With login page (username/password)
- Free SSL certificate
- Auto-deploy on git push
- Cognito authentication

## Test Login

1. Open: https://petstore.cloudopsinsights.com
2. You'll see login form
3. Enter:
   - Username: `testuser`
   - Password: `********`
4. Click "Sign In"
5. Start chatting!

## Screenshots

**Login Page:**
```
┌─────────────────────────────────┐
│     🐾 Pet Store Chat          │
│   AI-Powered Pet Assistant      │
├─────────────────────────────────┤
│                                 │
│  Username: [testuser        ]  │
│  Password: [••••••••••••••••]  │
│                                 │
│      [     Sign In     ]        │
│                                 │
└─────────────────────────────────┘
```

**After Login:**
```
┌─────────────────────────────────┐
│     🐾 Pet Store Chat          │
├─────────────────────────────────┤
│ Welcome! Try:                   │
│ • "List all pets"               │
│ • "Show me dogs"                │
│ • "Add a dog named Max..."      │
├─────────────────────────────────┤
│ [Type your message...    ] Send │
└─────────────────────────────────┘
```

## Cost

- **Build:** $0.01 per minute (first 1000 min free)
- **Hosting:** $0.15 per GB served
- **SSL:** Free (automatic)
- **Typical:** ~$0.50/month

## Troubleshooting

### Can't login?
Check Cognito user exists:
```bash
aws cognito-idp admin-get-user \
  --user-pool-id us-east-1_xxxxxxxxx\
  --username testuser \
  --region us-east-1
```

### DNS not working?
Check DNS propagation:
```bash
dig petstore.cloudopsinsights.com
```

### SSL pending?
Wait 10 minutes, then check Amplify console for status.

## Add More Users

```bash
# Create new user
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_xxxxxxxxx \
  --username newuser \
  --temporary-password xxxxxxxxx! \
  --region us-east-1

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_xxxxxxxxx \
  --username newuser \
  --password xxxxxxxxx! \
  --permanent \
  --region us-east-1
```

## Summary

✅ **Login page already exists** in the code
✅ **Cognito authentication** configured
✅ **No hardcoded credentials** - users enter at login
✅ **Free SSL** with Amplify
✅ **Custom domain** support
✅ **Auto-deploy** on git push

**Just deploy via Amplify Console and add DNS records!**
