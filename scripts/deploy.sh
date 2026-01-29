#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TABLE_NAME="PetStore"
LAMBDA_ROLE="PetStoreLambdaRole"
LAMBDA_FUNCTION="PetStoreFunction"
S3_BUCKET="petstore-chat-demo-${ACCOUNT_ID}"

echo "🚀 Deploying Pet Store Chatbot..."
echo "Account: $ACCOUNT_ID"
echo "Region: $REGION"
echo ""

# 1. Create DynamoDB Table
echo "📊 Creating DynamoDB table..."
aws dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION 2>/dev/null || echo "Table already exists"

# 2. Create IAM Role
echo "🔐 Creating IAM role..."
aws iam create-role \
  --role-name $LAMBDA_ROLE \
  --assume-role-policy-document file://iam/lambda-trust-policy.json \
  2>/dev/null || echo "Role already exists"

sleep 2

# 3. Attach Policies
echo "📋 Attaching policies..."
aws iam put-role-policy \
  --role-name $LAMBDA_ROLE \
  --policy-name BedrockInvokePolicy \
  --policy-document file://iam/bedrock-policy.json

aws iam put-role-policy \
  --role-name $LAMBDA_ROLE \
  --policy-name DynamoDBAccessPolicy \
  --policy-document file://iam/dynamodb-policy.json

sleep 5

# 4. Deploy Lambda
echo "⚡ Deploying Lambda function..."
cd lambda
zip -q lambda.zip lambda_function.py
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE}"

aws lambda create-function \
  --function-name $LAMBDA_FUNCTION \
  --runtime python3.11 \
  --role $ROLE_ARN \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda.zip \
  --timeout 30 \
  --memory-size 256 \
  --region $REGION 2>/dev/null || \
aws lambda update-function-code \
  --function-name $LAMBDA_FUNCTION \
  --zip-file fileb://lambda.zip \
  --region $REGION

cd ..

# 5. Create S3 Bucket
echo "🪣 Creating S3 bucket..."
aws s3 mb s3://$S3_BUCKET --region $REGION 2>/dev/null || echo "Bucket already exists"

aws s3 website s3://$S3_BUCKET \
  --index-document petstore-chat-secure.html

# 6. Upload Frontend
echo "🌐 Uploading frontend..."
aws s3 cp frontend/petstore-chat-secure.html s3://$S3_BUCKET/ --cache-control "no-cache"

# 7. Make Bucket Public
cat > /tmp/bucket-policy.json << POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::${S3_BUCKET}/*"
  }]
}
POLICY

aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file:///tmp/bucket-policy.json

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Create API Gateway (see api-gateway/deployment-steps.md)"
echo "2. Create Cognito User Pool (see cognito/setup-steps.md)"
echo "3. Update frontend with your API Gateway URL and Cognito details"
echo "4. Access: http://${S3_BUCKET}.s3-website-${REGION}.amazonaws.com/petstore-chat-secure.html"
echo ""
echo "💰 Estimated Cost: ~$0.05/month for 1000 queries"
