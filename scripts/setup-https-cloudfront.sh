#!/bin/bash
# CloudFront + Custom Domain Setup for petstore.cloudopsinsights.com
# Estimated time: 20 minutes

set -e

DOMAIN="petstore.cloudopsinsights.com"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="petstore-chat-demo-${ACCOUNT_ID}"

echo "🚀 Setting up HTTPS for ${DOMAIN}"
echo "================================================"
echo ""

# Step 1: Request SSL Certificate (must be in us-east-1 for CloudFront)
echo "📜 Step 1: Requesting SSL Certificate..."
CERT_ARN=$(aws acm request-certificate \
  --domain-name $DOMAIN \
  --validation-method DNS \
  --region us-east-1 \
  --query 'CertificateArn' \
  --output text)

echo "✅ Certificate requested: $CERT_ARN"
echo ""

# Step 2: Get DNS validation record
echo "📋 Step 2: Get DNS validation record..."
sleep 5  # Wait for AWS to generate validation record

VALIDATION_RECORD=$(aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
  --output json)

VALIDATION_NAME=$(echo $VALIDATION_RECORD | jq -r '.Name')
VALIDATION_VALUE=$(echo $VALIDATION_RECORD | jq -r '.Value')

echo "✅ Add this CNAME record to your DNS (cloudopsinsights.com):"
echo ""
echo "  Name:  ${VALIDATION_NAME}"
echo "  Type:  CNAME"
echo "  Value: ${VALIDATION_VALUE}"
echo ""
echo "⏳ Waiting for DNS validation (this may take 5-30 minutes)..."
echo "   Press Ctrl+C if you want to add DNS record manually and run this script again"
echo ""

# Wait for certificate validation
while true; do
    STATUS=$(aws acm describe-certificate \
      --certificate-arn $CERT_ARN \
      --region us-east-1 \
      --query 'Certificate.Status' \
      --output text)
    
    if [ "$STATUS" = "ISSUED" ]; then
        echo "✅ Certificate validated and issued!"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ Certificate validation failed. Check DNS records."
        exit 1
    fi
    
    echo "   Status: $STATUS (checking again in 30 seconds...)"
    sleep 30
done

echo ""

# Step 3: Create CloudFront Distribution
echo "☁️  Step 3: Creating CloudFront distribution..."

cat > /tmp/cloudfront-config.json << EOF
{
  "CallerReference": "petstore-$(date +%s)",
  "Comment": "Pet Store Chatbot - ${DOMAIN}",
  "Enabled": true,
  "Aliases": {
    "Quantity": 1,
    "Items": ["${DOMAIN}"]
  },
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-${BUCKET}",
        "DomainName": "${BUCKET}.s3-website-us-east-1.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${BUCKET}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"},
      "Headers": {
        "Quantity": 0
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true,
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    }
  },
  "DefaultRootObject": "petstore-chat-secure.html",
  "PriceClass": "PriceClass_100",
  "ViewerCertificate": {
    "ACMCertificateArn": "${CERT_ARN}",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021",
    "Certificate": "${CERT_ARN}",
    "CertificateSource": "acm"
  },
  "HttpVersion": "http2"
}
EOF

DISTRIBUTION_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cloudfront-config.json \
  --query 'Distribution.Id' \
  --output text)

echo "✅ CloudFront distribution created: $DISTRIBUTION_ID"
echo ""

# Get CloudFront domain
CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DomainName' \
  --output text)

echo "☁️  CloudFront Domain: $CLOUDFRONT_DOMAIN"
echo ""

# Step 4: DNS Configuration
echo "📋 Step 4: Add DNS record for your domain..."
echo ""
echo "  Add this CNAME record to cloudopsinsights.com DNS:"
echo ""
echo "  Name:  petstore"
echo "  Type:  CNAME"
echo "  Value: ${CLOUDFRONT_DOMAIN}"
echo "  TTL:   300"
echo ""

# Step 5: Wait for CloudFront deployment
echo "⏳ Step 5: Waiting for CloudFront deployment (5-10 minutes)..."
echo ""

while true; do
    STATUS=$(aws cloudfront get-distribution \
      --id $DISTRIBUTION_ID \
      --query 'Distribution.Status' \
      --output text)
    
    if [ "$STATUS" = "Deployed" ]; then
        echo "✅ CloudFront distribution deployed!"
        break
    fi
    
    echo "   Status: $STATUS (checking again in 30 seconds...)"
    sleep 30
done

echo ""
echo "================================================"
echo "✅ HTTPS Setup Complete!"
echo "================================================"
echo ""
echo "📝 Summary:"
echo "  Domain:       https://${DOMAIN}"
echo "  CloudFront:   https://${CLOUDFRONT_DOMAIN}"
echo "  Certificate:  ${CERT_ARN}"
echo "  Distribution: ${DISTRIBUTION_ID}"
echo ""
echo "🧪 Test your site:"
echo "  curl -I https://${DOMAIN}"
echo ""
echo "📊 Monitor CloudFront:"
echo "  aws cloudfront get-distribution --id ${DISTRIBUTION_ID}"
echo ""
echo "🔄 Invalidate cache (after updates):"
echo "  aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths '/*'"
echo ""
echo "💰 Cost: Free tier (1TB + 10M requests), then ~\$0.50/month"
echo ""
echo "🎉 Your Pet Store Chatbot is now live at: https://${DOMAIN}"
