#!/bin/bash

# destroy.sh - Script to tear down S3 static website resources
# Usage: ./destroy.sh [bucket-name] [region]

set -e  # Exit on any error

# Default values
DEFAULT_BUCKET="my-static-website-$(date +%s)"
DEFAULT_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -b, --bucket-name    S3 bucket name to delete (default: $DEFAULT_BUCKET)"
    echo "  -r, --region         AWS region (default: $DEFAULT_REGION)"
    echo "  -f, --force          Skip confirmation prompt"
    echo "  -h, --help           Show this help message"
    exit 1
}

# Parse command line arguments
FORCE=false
BUCKET_NAME=""
REGION=""

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
    print_warning "No bucket name provided. Checking for Terraform state..."
    
    # Try to get bucket name from Terraform state if exists
    if [ -f "terraform/terraform.tfstate" ]; then
        BUCKET_NAME=$(cd terraform && terraform output -raw bucket_name 2>/dev/null || echo "")
    fi
    
    if [ -z "$BUCKET_NAME" ]; then
        print_error "Could not determine bucket name. Please specify with -b option."
        exit 1
    else
        print_status "Found bucket name from Terraform: $BUCKET_NAME"
    fi
fi

if [ -z "$REGION" ]; then
    REGION=$DEFAULT_REGION
    print_status "Using default region: $REGION"
fi

# Confirm deletion
if [ "$FORCE" = false ]; then
    echo "=============================================="
    print_warning "This will PERMANENTLY delete the S3 bucket:"
    echo "Bucket: $BUCKET_NAME"
    echo "Region: $REGION"
    echo "=============================================="
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
fi

# Check if bucket exists
print_status "Checking if bucket exists..."
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
    print_error "Bucket $BUCKET_NAME does not exist or you don't have permission to access it."
    exit 1
fi

# Empty the bucket before deletion
print_status "Emptying bucket contents..."
if aws s3 rm "s3://$BUCKET_NAME" --recursive --region "$REGION" 2>/dev/null; then
    print_status "Bucket emptied successfully."
else
    print_warning "Failed to empty bucket. Trying to continue with deletion..."
fi

# Delete the bucket
print_status "Deleting S3 bucket..."
if aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"; then
    print_status "Bucket $BUCKET_NAME deleted successfully."
else
    print_error "Failed to delete bucket $BUCKET_NAME."
    print_warning "The bucket might not be empty or you may not have sufficient permissions."
    exit 1
fi

# If using Terraform, destroy those resources too
if [ -f "terraform/terraform.tfstate" ]; then
    print_status "Destroying Terraform resources..."
    cd terraform
    terraform destroy -auto-approve
    cd ..
    print_status "Terraform resources destroyed."
fi

print_status "Cleanup completed successfully!"
echo "Resources deleted:"
echo "- S3 Bucket: $BUCKET_NAME"