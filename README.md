# AWS Multi-AZ Modular Infrastructure with Terraform

An enterprise-grade, modular Infrastructure-as-Code (IaC) project built using **Terraform (HCL)** to deploy a highly available, multi-tier AWS architecture across multiple Availability Zones for **Development (`dev`)**, **Quality Control (`qc`)**, and **Production (`prod`)** environments.

---

## Architecture Overview

The infrastructure provisions a redundant, secure, and self-healing environment:

- **Networking (VPC)**:
  - Custom VPC spanned across **2 Availability Zones**.
  - **2 Public Subnets** hosting Internet Gateways and Dual NAT Gateways for outbound internet connectivity.
  - **2 Private Subnets** hosting application instances with no direct public route.
  - **S3 Gateway Endpoint** for direct, cost-free, high-performance internal access to S3.
- **Security & Traffic Management**:
  - Independent Security Groups enforcing least privilege.
  - Public **Application Load Balancer (ALB)** accepting HTTP/HTTPS traffic.
  - Backend instances only accept HTTP traffic routed directly through the ALB Security Group.
  - Automated **`aws_login` Key Pair** generated at deploy time with local `.pem` export.
- **Compute & Auto Scaling**:
  - **Auto Scaling Group (ASG)** spanning across private subnets.
  - Amazon Linux 2023 launch templates configured with rolling updates and health checks.
- **Regional Services**:
  - S3 bucket with default server-side encryption (AES256) and versioning.
  - DynamoDB state/lock table with point-in-time recovery.
  - Amazon CloudWatch metric alarms monitoring ASG CPU utilization.

---

## Repository Structure

```text
terraform-infra/
├── .gitignore
├── README.md
├── modules/
│   ├── vpc/                  # Multi-AZ subnets, IGW, dual NAT GWs, S3 Gateway endpoint
│   │   ├── main.tf
│   │   ├── variables.tf      # Fully documented inputs
│   │   └── outputs.tf
│   ├── security/             # Ingress/Egress rules for ALB and EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/                  # Internet-facing ALB, listeners, and target groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── asg/                  # Launch template, Auto Scaling Group, health checks
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── regional_services/    # S3 bucket, DynamoDB table, CloudWatch alarms
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/                  # Development environment (t3.micro, min=1, max=2)
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── outputs.tf
    ├── qc/                   # Staging / QC environment (t3.small, min=2, max=4)
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── outputs.tf
    └── prod/                 # Production environment (t3.medium, min=2, max=8)
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── outputs.tf
```

--- 

## Environment Comparison

| Attribute                     | Dev (`environments/dev`) | QC (`environments/qc`) | Prod (`environments/prod`) |
|-------------------------------|--------------------------|------------------------|----------------------------|
| **CIDR Block**                | 10.10.0.0/16             | 10.20.0.0/16           | 10.0.0.0/16                |
| **Instance Type**             | t3.micro                 | t3.small               | t3.medium                  |
| **ASG Scaling (Min/Max/Desired)** | 1 / 2 / 1             | 2 / 4 / 2              | 2 / 8 / 4                  |
| **ALB Deletion Protection**   | Disabled                 | Disabled               | Enabled                    |
| **CloudWatch Log Retention**  | 14 Days                  | 14 Days                | 90 Days                    |
| **S3 Bucket Force Destroy**   | Enabled                  | Enabled                | Disabled                   |

---

## Prerequisites

- **Terraform**: CLI >= 1.5.0 installed  
- **AWS CLI**: Configured with credentials that have administrative permissions  

```bash
aws configure

Deployment Instructions
Select and Navigate to Environment

bash
cd environments/dev    # or environments/qc, environments/prod
Initialize Providers & Modules

bash
terraform init
Review the Plan

bash
terraform plan
Deploy Infrastructure

bash
terraform apply
Accessing the Infrastructure
Web Access
Once provisioning completes, copy the ALB DNS name from the Terraform outputs:

bash
terraform output alb_dns_name
Open the returned DNS URL in your web browser to confirm instance responses.

EC2 Access via aws_login Key
During terraform apply, Terraform uses tls_private_key to build an RSA key pair, creates the key in AWS, and saves the .pem file directly into your environment directory:

bash
# Confirm permissions (automatically set to 0400 by Terraform)
ls -l aws_login_*.pem

# Connect to your backend instance via internal routing or EC2 Instance Connect / SSM
ssh -i aws_login_dev.pem ec2-user@<PRIVATE_INSTANCE_IP>
Teardown / Destroy
To remove all provisioned cloud resources and stop recurring billing:

bash
cd environments/dev
terraform destroy
Author
Manish D — DevOps & Platform Engineer  
LinkedIn: linkedin.com/in/manish-d-0779b01aa (linkedin.com in Bing)