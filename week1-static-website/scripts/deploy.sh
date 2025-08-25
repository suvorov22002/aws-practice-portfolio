#!/bin/bash

# deploy.sh - Script to deploy a static website to S3
# Supports AWS profile specification and various deployment options

set -e  # Exit on any error

# Default values
DEFAULT_BUCKET="toupel-static-website-$(date +%s)"
DEFAULT_REGION="us-east-1"
DEFAULT_PROFILE="default"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_config() {
    echo -e "${BLUE}[CONFIG]${NC} $1"
}

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -b, --bucket-name    S3 bucket name (default: auto-generated)"
    echo "  -r, --region         AWS region (default: $DEFAULT_REGION)"
    echo "  -p, --profile        AWS CLI profile (default: $DEFAULT_PROFILE)"
    echo "  -d, --domain         Custom domain name (optional)"
    echo "  -f, --force          Skip confirmation prompts"
    echo "  -h, --help           Show this help message"
    exit 1
}

# Parse command line arguments
BUCKET_NAME=""
REGION=""
PROFILE=""
DOMAIN=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket-name)
            BUCKET_NAME="$2"
            shift
            shift
            ;;
        -r|--region)
            REGION="$2"
            shift
            shift
            ;;
        -p|--profile)
            PROFILE="$2"
            shift
            shift
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Set default values if not provided
if [ -z "$BUCKET_NAME" ]; then
    BUCKET_NAME=$DEFAULT_BUCKET
    print_warning "No bucket name provided. Using auto-generated name: $BUCKET_NAME"
fi

if [ -z "$REGION" ]; then
    REGION=$DEFAULT_REGION
fi

if [ -z "$PROFILE" ]; then
    PROFILE=$DEFAULT_PROFILE
fi

# Build AWS CLI profile argument
if [ "$PROFILE" = "default" ]; then
    AWS_PROFILE_ARG=""
else
    AWS_PROFILE_ARG="--profile $PROFILE"
    print_status "Using AWS profile: $PROFILE"
fi

# Confirm deployment
if [ "$FORCE" = false ]; then
    echo "=============================================="
    print_config "Deployment Configuration:"
    echo "Bucket: $BUCKET_NAME"
    echo "Region: $REGION"
    echo "Profile: $PROFILE"
    if [ -n "$DOMAIN" ]; then
        echo "Domain: $DOMAIN"
    fi
    echo "=============================================="
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
fi

# Check if AWS CLI is configured with the specified profile
print_status "Checking AWS CLI configuration..."
if ! aws sts get-caller-identity $AWS_PROFILE_ARG > /dev/null 2>&1; then
    print_warning "AWS CLI not configured with profile '$PROFILE'"
    print_warning "Please configure it using: aws configure --profile $PROFILE"
    exit 1
fi

# Create S3 bucket
print_status "Creating S3 bucket..."
if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" $AWS_PROFILE_ARG; then
    print_status "Bucket created successfully."
else
    print_warning "Failed to create bucket. It might already exist. Continuing..."
fi

# Enable static website hosting
print_status "Configuring static website hosting..."
aws s3 website "s3://$BUCKET_NAME" \
    --index-document index.html \
    --error-document error.html \
    $AWS_PROFILE_ARG

# Configure public access
print_status "Configuring public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
    $AWS_PROFILE_ARG

# Apply bucket policy for public read access
print_status "Applying bucket policy..."
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"PublicReadGetObject\",
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::$BUCKET_NAME/*\"
    }
  ]
}" $AWS_PROFILE_ARG

# Upload files to S3
print_status "Uploading website files..."
aws s3 sync src/ "s3://$BUCKET_NAME/" --delete $AWS_PROFILE_ARG

# If custom domain provided, configure it
if [ -n "$DOMAIN" ]; then
    print_status "Configuring custom domain: $DOMAIN"
    # Note: This is a placeholder for domain configuration
    # Actual implementation would involve Route53 and CloudFront
    print_warning "Custom domain configuration requires manual setup with Route53 and/or CloudFront"
fi

# Output website URL
WEBSITE_URL="http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
print_status "Deployment completed successfully!"
echo "Website URL: $WEBSITE_URL"

# Test the website (optional)
print_status "Testing website..."
if curl -s -o /dev/null -w "%{http_code}" "$WEBSITE_URL" | grep -q "200"; then
    print_status "Website is accessible and returning HTTP 200"
else
    print_warning "Website might not be accessible yet (S3 propagation can take time)"
fi

echo "=============================================="
print_config "Deployment Summary:"
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo "Profile: $PROFILE"
echo "Website URL: $WEBSITE_URL"
if [ -n "$DOMAIN" ]; then
    echo "Custom Domain: $DOMAIN (requires manual setup)"
fi
echo "=============================================="