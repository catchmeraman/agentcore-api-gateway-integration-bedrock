# Deployment Scripts

## Available Scripts

### 1. deploy.sh
**Purpose:** Deploy the complete Pet Store infrastructure
**Time:** ~5 minutes
**What it does:**
- Creates DynamoDB table
- Creates IAM roles and policies
- Deploys Lambda function
- Creates S3 bucket for frontend
- Uploads frontend files

**Usage:**
```bash
./scripts/deploy.sh
```

### 2. setup-https-cloudfront.sh
**Purpose:** Enable HTTPS with CloudFront and custom domain
**Time:** ~20 minutes
**What it does:**
- Requests SSL certificate from ACM
- Waits for DNS validation
- Creates CloudFront distribution
- Configures custom domain
- Provides DNS records to add

**Usage:**
```bash
./scripts/setup-https-cloudfront.sh
```

**Requirements:**
- Domain name (e.g., petstore.cloudopsinsights.com)
- Access to DNS management
- Completed deploy.sh first

**DNS Records Needed:**
1. CNAME for certificate validation (automatic)
2. CNAME pointing to CloudFront domain (manual)

**Example:**
```
# Certificate validation (add this first)
Name:  _abc123.petstore.cloudopsinsights.com
Type:  CNAME
Value: _xyz456.acm-validations.aws.

# Domain pointing to CloudFront (add after distribution created)
Name:  petstore
Type:  CNAME
Value: d123abc.cloudfront.net
```

### 3. cleanup.sh (Coming Soon)
**Purpose:** Remove all deployed resources
**Time:** ~2 minutes

## Quick Start

### Option A: HTTP Only (Free)
```bash
./scripts/deploy.sh
# Access: http://petstore-chat-demo-ACCOUNT_ID.s3-website-us-east-1.amazonaws.com
```

### Option B: HTTPS with CloudFront
```bash
# Step 1: Deploy infrastructure
./scripts/deploy.sh

# Step 2: Enable HTTPS
./scripts/setup-https-cloudfront.sh

# Step 3: Add DNS records (shown by script)

# Step 4: Wait 5-10 minutes for deployment

# Access: https://petstore.cloudopsinsights.com
```

## Troubleshooting

### Certificate validation stuck
**Check DNS record:**
```bash
dig _abc123.petstore.cloudopsinsights.com CNAME
```

### CloudFront shows 403
**Check S3 bucket policy:**
```bash
aws s3api get-bucket-policy --bucket petstore-chat-demo-ACCOUNT_ID
```

### CORS errors after HTTPS
**Update Lambda CORS headers:**
```python
cors_headers = {
    'Access-Control-Allow-Origin': 'https://petstore.cloudopsinsights.com',
    ...
}
```

## Cost Estimates

**HTTP Only:**
- S3: $0.023 per GB
- Lambda: $0.20 per 1M requests
- DynamoDB: On-demand (pay per request)
- **Total:** ~$0.05/month for 1000 queries

**HTTPS with CloudFront:**
- Above costs +
- CloudFront: Free tier (1TB + 10M requests)
- After free tier: ~$0.50/month
- SSL Certificate: Free (ACM)
- **Total:** ~$0.55/month for 10K queries

## Support

Issues? Check:
1. [Quick Start Guide](../docs/QUICK_START.md)
2. [HTTPS Setup Guide](../docs/HTTPS_SETUP.md)
3. [GitHub Issues](https://github.com/catchmeraman/agentcore-api-gateway-integration-bedrock/issues)
