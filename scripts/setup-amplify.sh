#!/bin/bash
# AWS Amplify Setup with Custom Domain: petstore.cloudopsinsights.com
# Estimated time: 10 minutes (simplest option!)

set -e

DOMAIN="petstore.cloudopsinsights.com"
APP_NAME="petstore-chatbot"
GITHUB_REPO="catchmeraman/agentcore-api-gateway-integration-bedrock"
BRANCH="main"

echo "🚀 Setting up Amplify with ${DOMAIN}"
echo "================================================"
echo ""

# Step 1: Create Amplify App
echo "📱 Step 1: Creating Amplify app..."

APP_ID=$(aws amplify create-app \
  --name $APP_NAME \
  --repository "https://github.com/${GITHUB_REPO}" \
  --platform WEB \
  --region us-east-1 \
  --query 'app.appId' \
  --output text)

echo "✅ Amplify app created: $APP_ID"
echo ""

# Step 2: Create Branch
echo "🌿 Step 2: Connecting branch..."

BRANCH_ARN=$(aws amplify create-branch \
  --app-id $APP_ID \
  --branch-name $BRANCH \
  --framework "Web" \
  --stage PRODUCTION \
  --enable-auto-build \
  --region us-east-1 \
  --query 'branch.branchArn' \
  --output text)

echo "✅ Branch connected: $BRANCH"
echo ""

# Step 3: Configure Build Settings
echo "⚙️  Step 3: Configuring build settings..."

cat > /tmp/amplify-build.yml << 'EOF'
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
  cache:
    paths: []
EOF

aws amplify update-app \
  --app-id $APP_ID \
  --build-spec file:///tmp/amplify-build.yml \
  --region us-east-1 > /dev/null

echo "✅ Build settings configured"
echo ""

# Step 4: Start Deployment
echo "🚀 Step 4: Starting deployment..."

JOB_ID=$(aws amplify start-job \
  --app-id $APP_ID \
  --branch-name $BRANCH \
  --job-type RELEASE \
  --region us-east-1 \
  --query 'jobSummary.jobId' \
  --output text)

echo "✅ Deployment started: $JOB_ID"
echo ""

# Wait for deployment
echo "⏳ Waiting for deployment to complete (2-3 minutes)..."
while true; do
    STATUS=$(aws amplify get-job \
      --app-id $APP_ID \
      --branch-name $BRANCH \
      --job-id $JOB_ID \
      --region us-east-1 \
      --query 'job.summary.status' \
      --output text)
    
    if [ "$STATUS" = "SUCCEED" ]; then
        echo "✅ Deployment successful!"
        break
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ Deployment failed. Check Amplify console for details."
        exit 1
    fi
    
    echo "   Status: $STATUS (checking again in 10 seconds...)"
    sleep 10
done

echo ""

# Get default domain
DEFAULT_DOMAIN=$(aws amplify get-app \
  --app-id $APP_ID \
  --region us-east-1 \
  --query 'app.defaultDomain' \
  --output text)

echo "✅ App deployed at: https://${BRANCH}.${DEFAULT_DOMAIN}"
echo ""

# Step 5: Add Custom Domain
echo "🌐 Step 5: Adding custom domain..."

DOMAIN_ARN=$(aws amplify create-domain-association \
  --app-id $APP_ID \
  --domain-name cloudopsinsights.com \
  --sub-domain-settings "prefix=petstore,branchName=${BRANCH}" \
  --enable-auto-sub-domain \
  --region us-east-1 \
  --query 'domainAssociation.domainAssociationArn' \
  --output text)

echo "✅ Custom domain added"
echo ""

# Wait for SSL certificate
echo "📜 Step 6: Waiting for SSL certificate (5-10 minutes)..."
echo "   Amplify is automatically creating and validating SSL certificate..."
echo ""

while true; do
    DOMAIN_STATUS=$(aws amplify get-domain-association \
      --app-id $APP_ID \
      --domain-name cloudopsinsights.com \
      --region us-east-1 \
      --query 'domainAssociation.domainStatus' \
      --output text)
    
    if [ "$DOMAIN_STATUS" = "AVAILABLE" ]; then
        echo "✅ SSL certificate issued and domain ready!"
        break
    elif [ "$DOMAIN_STATUS" = "FAILED" ]; then
        echo "❌ Domain setup failed. Check Amplify console for details."
        exit 1
    fi
    
    echo "   Status: $DOMAIN_STATUS (checking again in 30 seconds...)"
    sleep 30
done

echo ""

# Get DNS records
echo "📋 Step 7: DNS Configuration"
echo ""

DNS_RECORDS=$(aws amplify get-domain-association \
  --app-id $APP_ID \
  --domain-name cloudopsinsights.com \
  --region us-east-1 \
  --query 'domainAssociation.subDomains[0].dnsRecord' \
  --output json)

DNS_TYPE=$(echo $DNS_RECORDS | jq -r '.type')
DNS_NAME=$(echo $DNS_RECORDS | jq -r '.name')
DNS_VALUE=$(echo $DNS_RECORDS | jq -r '.value')

echo "Add this DNS record to cloudopsinsights.com:"
echo ""
echo "  Name:  ${DNS_NAME}"
echo "  Type:  ${DNS_TYPE}"
echo "  Value: ${DNS_VALUE}"
echo ""

echo "================================================"
echo "✅ Amplify Setup Complete!"
echo "================================================"
echo ""
echo "📝 Summary:"
echo "  App ID:        ${APP_ID}"
echo "  Default URL:   https://${BRANCH}.${DEFAULT_DOMAIN}"
echo "  Custom Domain: https://${DOMAIN} (after DNS update)"
echo ""
echo "🔧 Next Steps:"
echo "  1. Add the DNS record shown above to cloudopsinsights.com"
echo "  2. Wait 5-10 minutes for DNS propagation"
echo "  3. Access your site at: https://${DOMAIN}"
echo ""
echo "📊 Amplify Console:"
echo "  https://console.aws.amazon.com/amplify/home?region=us-east-1#/${APP_ID}"
echo ""
echo "🔄 Auto-Deploy:"
echo "  Every git push to 'main' will automatically deploy!"
echo ""
echo "💰 Cost:"
echo "  - Build: \$0.01 per minute (first 1000 min free)"
echo "  - Hosting: \$0.15 per GB served"
echo "  - SSL: Free (automatic)"
echo "  - Typical: ~\$0.50/month"
echo ""
echo "🎉 Your Pet Store Chatbot will be live at: https://${DOMAIN}"
