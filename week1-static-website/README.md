# S3 Static Website Deployment Guide

## 1. Overview
This project provides a pratical implementation of hosting a static website on **Amazon Simple Storage (S3)**. It serves as a learning tool for those who want to understand:
- Configuring an S3 bucket for static website hosting
- Setting proper bucket policies for public read access
- Automating deployment using shell scripts and infrastructure as Code (Terraform)
- The core principles of cloud storage and web hosting on AWS 
- **AWS CLI Script** (Quickest method) 
- **Terraform** (Infrastructure as Code approach) 

## 2. Prerequisites
### AWS Account Setup
- Create an AWS account at https://aws.amazon.com 
- Sign in to the AWS Management Console 
- Create an IAM user with programmatic access (or use your root credentials - not recommended for production) 
### Required Tools
- **AWS CLI**: [Installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform**(optional): [Installation guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) 

## 3. AWS Credentials Configuration
Configure your AWS credentials using one of these methods:  
**Method 1: AWS Configure command**  
```bash
aws configure
```
You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (e.g., `us-east-1`)
- Default output format (e.g., `json`)  

**Method 2: Environment variables**  
```bash
export AWS_ACCESS_KEY_ID=<your_access_key_id>
export AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
export AWS_DEFAULT_REGION=us-east-1
```

## 4. Method 1: Deployment using AWS CLI Script
**Step-by-Step instructions**
1. Clone the repository
```bash
git clone https://github.com/suvorov22002/portfolio.git
cd portfolio
```
2. Review the deployment script  
Open `scripts/deploy.sh` and customize if needed  
    ° Change `BUCKET_NAME` to unique name (S3 bucket names are globally unique)  
    ° Modify `REGION` if needed
3. Make the script executable  
`chmod +x scripts/deploy.sh`
4. Run the deployment script  
`./scripts/deploy.sh`
5. Verify the deployment  
° The script will output your browser URL  
° Open the URL in a web browser  
° Check the S3 bucket in AWS Console to confirm files were uploaded

## 5. Method 2: Deployment Using Terraform
...

## 6. Testing your deployment
After deployment, test your website  
1. Basic functionality: load the website URL in a browser
2. Error page: Try accessing a non-existent page to test error handling
3. Content verification: Ensure all CSS, JS, and images load properly

## 7. Cleaning Up Resources  
### Using CLI Script  
`./scripts/destroy.sh`
### Using Terraform
```bash
cd terraform
terraform destroy
```
## 8. Project Structure
```bash
week1-static-website/
├── docs/
│   └── deployment-guide.md
├── src/
│   ├── index.html
│   ├── error.html
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── script.js
├── scripts/
│   ├── deploy.sh
│   └── setup-s3.sh
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── README.md
```
