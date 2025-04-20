This is a cleaned and published version of a private repo, containing only the final version for demonstration purposes.

# Terraform Infrastructure for LLM-Powered Assistant

This repository contains Terraform modules and configurations to provision and manage the cloud infrastructure required for a serverless, LLM-powered assistant backend.

---

## 📦 What’s Included

### ✅ Core Components
- **VPC & Networking**: Secure VPC with private/public subnets, route tables, NAT, etc.
- **IAM**: Roles and policies for Lambda, API Gateway, and S3 access.
- **API Gateway**:
    - Public endpoint for user-facing interaction
    - Private endpoint for internal services
- **Lambda Functions**:
    - Chatbot handler function
    - Environment variables, permissions, and deployment bucket
- **S3 Buckets**:
    - Lambda artifact storage
    - Prompt/template/config storage
- **ECS-compatible VPN Bastion**:
    - Optional secure access to private subnets via StrongSwan
- **Budgets Module**:
    - Enforces spend limits for safe experimentation

---

## 🌱 Getting Started

### 1. Configure Variables
Edit `terraform.tfvars` or define via CLI:
```hcl
aws_region       = "eu-west-2"
project_name     = "llm-assistant"
environment       = "staging"
allowed_ips       = ["YOUR.IP.HERE/32"]
```

### 2. Initialize and Apply
```bash
terraform init
terraform plan
terraform apply
```

---

## 📁 Directory Structure

```
├── vpc.tf                   # VPC, subnets, routing
├── vpn_bastion.tf          # Optional VPN access point
├── iam.tf                  # Roles and permissions
├── lambda_chatbot.tf       # Lambda function + permissions
├── lambda_s3_buckets.tf    # Buckets for code and prompts
├── public_api_gateway.tf   # Public-facing API Gateway
├── private_api_gateway.tf  # Internal API Gateway
├── budgets.tf              # Cost control
├── variables.tf            # Input variable declarations
├── terraform.tfvars        # Default values
```

---

## 🔐 Security Considerations
- VPC access is locked to specific IPs where required
- Separate IAM roles with least privilege
- Artifacts are stored in private S3 buckets
- VPN bastion is optional but recommended for private debugging

---

## ✅ Requirements
- Terraform 1.3+
- AWS CLI & credentials configured
- IAM user with permissions to manage the services above

---

## 🧹 Cleanup
```bash
terraform destroy
```

---

## 👤 Author
Built and maintained by [Alberto Zuin](https://moyd.co.uk)
