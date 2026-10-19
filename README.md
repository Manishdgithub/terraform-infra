<div align="center">

# ☁️ Enterprise AWS Multi-AZ Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-844FBA?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E5.0-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Architecture](https://img.shields.io/badge/Architecture-High%20Availability-success?style=for-the-badge&logo=awsorganizations&logoColor=white)](#architecture-overview)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

*Production-ready, highly available, multi-tier AWS infrastructure orchestrated across multiple Availability Zones with reusable Terraform modules for **Dev**, **QC**, and **Production** environments.*

[Architecture](#architecture-overview) • [Repository Structure](#repository-structure) • [Environment Comparison](#environment-comparison) • [Quick Start](#getting-started) • [Security](#security--key-management) • [Author](#author)

---

</div>

## 📌 Architecture Overview

This project designs a secure, resilient, and auto-scaling cloud topology across **two Availability Zones (AZs)**, enforcing least-privilege traffic flow and automated key lifecycle management.

```text
                    ┌──────────────────────────────────────────────────────── ┐
                    │               AWS Region (Multi-AZ VPC)                 │
                    │                                                         │
                    │   ┌────────────────────────────────────────────────┐    │
                    │   │       Internet Gateway & S3 Gateway VPC EP     │    │
                    │   └───────────────────────┬────────────────────────┘    │
                    │                           │                             │
                    │        ┌──────────────────┴──────────────────┐          │
                    │        ▼                                     ▼          │
                    │  [Public Subnet 1]                     [Public Subnet 2]│
                    │  ├── NAT Gateway 1                     ├── NAT Gateway 2│
                    │  └── Public Application Load Balancer (ALB) ────────┐   │
                    │                                                     │   │
                    │        ┌────────────────────────────────────────────┘   │
                    │        ▼                                                │
                    │  [Private Subnet 1]                   [Private Subnet 2]│
                    │  ├── EC2 (App Instance 1)             ├── EC2 (App 2)   │
                    │  └─────────── Auto Scaling Group (ASG) ─────────────┘   │
                    │                                                         │
                    │  Regional Services: S3 Bucket • DynamoDB • CloudWatch   │
                    └──────────────────────────────────────────────────────── ┘

Key Pillars
🌐 Resilient Networking (VPC)

Dual Availability Zone coverage (ap-south-1a, ap-south-1b).

2 Public Subnets with Internet Gateway (IGW) and dedicated NAT Gateways per AZ.

2 Isolated Private Subnets housing backend EC2 instances without direct public routing.

S3 Gateway Endpoint to route object storage traffic internally without NAT egress costs.

🛡️ Zero-Trust Security & Traffic Routing

Public-facing Application Load Balancer (ALB) accepting only HTTP/HTTPS (80/443).

Tiered Security Groups: Private EC2 workloads only accept inbound HTTP from the ALB security group.

Automatic cryptographic key generation: aws_login Key Pair provisioned on the fly via tls_private_key, outputting an access-controlled .pem (chmod 0400).

📈 Elastic Compute & Observability

Auto Scaling Group (ASG) dynamically matching demand using Amazon Linux 2023 launch templates.

Rolling deployments configured with zero-downtime instance refresh strategies.

CloudWatch alarms continuously tracking ASG CPU metrics with linked log retention rules.

🗂️ Repository Structure

terraform-infra/
├── .gitignore                      # Excludes .pem keys, state files, and cache
├── README.md                       # Repository documentation
├── modules/
│   ├── vpc/                        # Multi-AZ subnets, IGW, Dual NATs, S3 Gateway EP
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/                   # Least-privilege Ingress/Egress Security Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/                        # Public Application Load Balancer & Target Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── asg/                        # Launch Template, Auto Scaling Group & Health Checks
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── regional_services/          # Encrypted S3, DynamoDB state table, CloudWatch alarms
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/                        # Development sandbox (t3.micro, min=1, max=2)
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── outputs.tf
    ├── qc/                         # Staging / Quality Control (t3.small, min=2, max=4)
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── outputs.tf
    └── prod/                       # Production setup (t3.medium, min=2, max=8)
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── outputs.tf
		
⚖️ Environment Comparison
🚀 Getting Started
Prerequisites
Terraform CLI >= 1.5.0

AWS CLI v2 installed and configured:

Bash
aws configure
Step-by-Step Deployment
1. Navigate to your target environment
Bash
cd environments/dev
# Alternately: cd environments/qc or cd environments/prod
2. Initialize provider plugins and modules
Bash
terraform init
3. Validate & preview changes
Bash
terraform validate
terraform plan
4. Provision infrastructure
Bash
terraform apply


🔒 Security & Key Management
Dynamic Key Generation (aws_login)
Terraform handles the SSH key pair creation using the tls and local providers so that no secrets need to be checked into version control.

Automatic Generation: Creates an unencrypted 4096-bit RSA key pair during execution.

Local Key Export: Saves aws_login_<env>.pem directly into the targeted environment folder with restrictive permissions (0400).

Connecting via SSH:

Bash
# Verify local key permissions
ls -l aws_login_*.pem

# Connect through your private subnet route or EC2 Instance Connect / SSM
ssh -i aws_login_dev.pem ec2-user@<PRIVATE_INSTANCE_IP>
Accessing the Web Application
Retrieve the DNS name of the newly created Application Load Balancer directly from Terraform outputs:

Bash
terraform output alb_dns_name
Paste this endpoint into your browser to verify routing and instance health.

🧹 Environment Teardown
To avoid unnecessary AWS charges, destroy resources when they are no longer required:

Bash
cd environments/dev
terraform destroy
Note: For prod, disable deletion_protection on the ALB and clear S3 objects before running destroy.

📦 Step-by-Step Commands to Push to GitHub
From the root of your project directory (terraform-infra/):

Bash
# 1. Initialize git
git init

# 2. Stage files
git add .

# 3. Check status to confirm .pem and .tfstate files are ignored
git status

# 4. Commit files
git commit -m "feat: complete multi-az modular terraform architecture for dev, qc, and prod"

# 5. Set branch name to main
git branch -M main

# 6. Add your GitHub remote repository
git remote add origin [https://github.com/](https://github.com/)<YOUR_GITHUB_USERNAME>/<YOUR_REPOSITORY_NAME>.git

# 7. Push to GitHub
git push -u origin main


👤 Author
Manish D

DevOps & Platform Engineer

LinkedIn: linkedin.com/in/manish-d-0779b01aa[cite: 1]

Location: Bangalore, India[cite: 1]