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