# HTTPS Setup with CloudFront (Free SSL)

Enable HTTPS for your Pet Store Chatbot at **zero extra cost** using CloudFront and AWS Certificate Manager.

## Why CloudFront?

✅ **Free SSL Certificate** - AWS Certificate Manager (ACM) provides free SSL/TLS certificates
✅ **No Extra Cost** - CloudFront Free Tier: 1TB data transfer out, 10M HTTP/HTTPS requests per month
✅ **Better Performance** - CDN caching reduces latency
✅ **DDoS Protection** - AWS Shield Standard included

## Cost Breakdown

**CloudFront Free Tier (12 months):**
- 1 TB data transfer out
- 10 million HTTP/HTTPS requests
- 2 million CloudFront Function invocations

**After Free Tier:**
- $0.085 per GB (first 10 TB)
- $0.0075 per 10,000 HTTPS requests
- **Estimated:** ~$0.50/month for 10,000 requests

**SSL Certificate:** $0 (ACM is free for CloudFront)

## Quick Setup (10 minutes)

### Step 1: Create CloudFront Distribution

```bash
# Get your S3 bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="petstore-chat-demo-${ACCOUNT_ID}"

# Create CloudFront distribution
cat > /tmp/cloudfront-config.json << EOF
{
  "CallerReference": "petstore-$(date +%s)",
  "Comment": "Pet Store Chatbot HTTPS",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${BUCKET}",
        "DomainName": "${BUCKET}.s3-website-us-east-1.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"]
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"}
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true
  },
  "DefaultRootObject": "petstore-chat-secure.html",
  "PriceClass": "PriceClass_100",
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "TLSv1.2_2021"
  }
}
EOF

# Create distribution
DISTRIBUTION_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cloudfront-config.json \
  --query 'Distribution.Id' \
  --output text)

# Get CloudFront domain
CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DomainName' \
  --output text)

echo "✅ CloudFront Distribution Created!"
echo "HTTPS URL: https://${CLOUDFRONT_DOMAIN}/petstore-chat-secure.html"
echo "Distribution ID: $DISTRIBUTION_ID"
```

**Wait 5-10 minutes for deployment to complete.**

### Step 2: Test HTTPS Access

```bash
# Check distribution status
aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.Status' \
  --output text

# When status is "Deployed", test:
curl -I https://${CLOUDFRONT_DOMAIN}/petstore-chat-secure.html
```

### Step 3: Update CORS (Optional)

If you get CORS errors, update API Gateway CORS to allow CloudFront domain:

```bash
# Update Lambda CORS headers
# Edit lambda/lambda_function.py:

cors_headers = {
    'Access-Control-Allow-Origin': 'https://YOUR_CLOUDFRONT_DOMAIN',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Accept'
}
```

## Option 2: Custom Domain with Free SSL

If you have a domain (e.g., `petstore.example.com`):

### Step 1: Request SSL Certificate

```bash
# Request certificate in us-east-1 (required for CloudFront)
CERT_ARN=$(aws acm request-certificate \
  --domain-name petstore.example.com \
  --validation-method DNS \
  --region us-east-1 \
  --query 'CertificateArn' \
  --output text)

echo "Certificate ARN: $CERT_ARN"

# Get validation records
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'
```

### Step 2: Add DNS Record

Add the CNAME record to your DNS provider (Route 53, GoDaddy, etc.):

```
Name: _abc123.petstore.example.com
Type: CNAME
Value: _xyz456.acm-validations.aws.
```

### Step 3: Wait for Validation

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.Status' \
  --output text
```

### Step 4: Create CloudFront with Custom Domain

```bash
cat > /tmp/cloudfront-custom.json << EOF
{
  "CallerReference": "petstore-custom-$(date +%s)",
  "Aliases": {
    "Quantity": 1,
    "Items": ["petstore.example.com"]
  },
  "ViewerCertificate": {
    "ACMCertificateArn": "$CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  ... (rest same as above)
}
EOF

aws cloudfront create-distribution \
  --distribution-config file:///tmp/cloudfront-custom.json
```

### Step 5: Update DNS

Add CNAME record pointing to CloudFront:

```
Name: petstore.example.com
Type: CNAME
Value: d123abc.cloudfront.net
```

## Option 3: AWS Amplify (Simplest)

AWS Amplify provides automatic HTTPS with zero configuration:

### Step 1: Push to GitHub

```bash
cd /Users/ramandeep_chandna/agentcore-api-gateway-integration-bedrock
git add .
git commit -m "Prepare for Amplify deployment"
git push origin main
```

### Step 2: Deploy with Amplify Console

1. Go to AWS Amplify Console
2. Click "New app" → "Host web app"
3. Connect to GitHub repository
4. Select branch: `main`
5. Build settings:
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
6. Click "Save and deploy"

**Amplify automatically provides:**
- ✅ Free SSL certificate
- ✅ HTTPS URL: `https://main.d123abc.amplifyapp.com`
- ✅ Auto-deploy on git push
- ✅ Custom domain support (free SSL)

### Step 3: Add Custom Domain (Optional)

1. In Amplify Console → Domain management
2. Add domain: `petstore.example.com`
3. Amplify creates SSL certificate automatically
4. Add DNS records shown by Amplify

**Cost:** $0.01 per build minute (first 1000 minutes free)

## Comparison

| Method | Setup Time | Cost | Custom Domain | Auto-Deploy |
|--------|-----------|------|---------------|-------------|
| CloudFront (default) | 10 min | Free tier, then ~$0.50/mo | ❌ | ❌ |
| CloudFront (custom) | 20 min | Free tier, then ~$0.50/mo | ✅ | ❌ |
| Amplify | 5 min | $0.01/build min | ✅ | ✅ |

## Recommended: Amplify for Simplicity

**Why Amplify?**
- ✅ Automatic HTTPS (no manual setup)
- ✅ Free SSL certificate
- ✅ Auto-deploy on git push
- ✅ Custom domain with free SSL
- ✅ Built-in CI/CD
- ✅ Preview deployments for branches

**Cost:**
- Free tier: 1000 build minutes/month
- After: $0.01 per build minute
- Hosting: $0.15 per GB served
- **Typical:** ~$0.50/month

## Quick Amplify Deployment

```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Configure
amplify configure

# Initialize
cd /Users/ramandeep_chandna/agentcore-api-gateway-integration-bedrock
amplify init

# Add hosting
amplify add hosting
# Choose: "Hosting with Amplify Console"
# Choose: "Manual deployment"

# Publish
amplify publish
```

**Output:**
```
✅ Deployment complete!
HTTPS URL: https://main.d123abc.amplifyapp.com
```

## Update Frontend for HTTPS

After deploying with HTTPS, update your frontend:

```javascript
// frontend/petstore-chat-secure.html
const CONFIG = {
    userPoolId: 'us-east-1_RNmMBC87g',
    clientId: '435iqd7cgbn2slmgn0a36fo9lf',
    region: 'us-east-1',
    apiUrl: 'https://66gd6g08ie.execute-api.us-east-1.amazonaws.com/prod'
    // API Gateway already has HTTPS!
};
```

## Security Benefits

**With HTTPS:**
- ✅ Encrypted data in transit
- ✅ Browser security warnings removed
- ✅ Required for production apps
- ✅ Better SEO ranking
- ✅ Required for modern browser features

**Without HTTPS:**
- ❌ Data sent in plain text
- ❌ Browser shows "Not Secure"
- ❌ Some features disabled
- ❌ Poor SEO ranking

## Troubleshooting

### Issue: Certificate validation pending
**Solution:** Check DNS records are correct
```bash
dig _abc123.petstore.example.com CNAME
```

### Issue: CloudFront shows 403
**Solution:** Check S3 bucket policy allows CloudFront
```bash
aws s3api get-bucket-policy --bucket $BUCKET
```

### Issue: CORS errors with HTTPS
**Solution:** Update Lambda CORS headers to include HTTPS origin

## Cost Summary

**Free Tier (12 months):**
- CloudFront: 1TB + 10M requests
- ACM: Free SSL certificates
- Amplify: 1000 build minutes

**After Free Tier:**
- CloudFront: ~$0.50/month (10K requests)
- Amplify: ~$0.50/month (typical usage)
- ACM: Always free

**Recommendation:** Use Amplify for simplicity, CloudFront for more control.

## Next Steps

1. Choose deployment method (Amplify recommended)
2. Deploy with HTTPS
3. Test with `https://` URL
4. Update documentation with new URL
5. (Optional) Add custom domain

---

**Result: Production-ready HTTPS at minimal cost!** 🔒
