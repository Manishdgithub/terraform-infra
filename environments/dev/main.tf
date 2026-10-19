terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform" # Comment this line if you are using AWS CLI default profile
}

# 1. Automated RSA Key Pair Generation for SSH Login
resource "tls_private_key" "login_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aws_login" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.login_key.public_key_openssh

  tags = {
    Name        = var.key_pair_name
    Environment = var.environment
  }
}

# 2. Export Private Key Locally as a .pem file with 0400 permissions
resource "local_file" "private_pem" {
  content         = tls_private_key.login_key.private_key_pem
  filename        = "${path.module}/${var.key_pair_name}.pem"
  file_permission = "0400"
}

# 3. VPC Module
module "vpc" {
  source               = "../../modules/vpc"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# 4. Security Groups..Module
module "security" {
  source      = "../../modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

# 5. Application Load Balancer Module
module "alb" {
  source                = "../../modules/alb"
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

# 6. Auto Scaling Group Module (Bound with aws_login Key)
module "asg" {
  source                     = "../../modules/asg"
  environment                = var.environment
  instance_type              = var.instance_type
  private_subnet_ids         = module.vpc.private_subnet_ids
  instance_security_group_id = module.security.instance_security_group_id
  target_group_arn           = module.alb.target_group_arn
  key_name                   = aws_key_pair.aws_login.key_name
  min_size                   = var.min_size
  max_size                   = var.max_size
  desired_capacity           = var.desired_capacity
}

# 7. Regional Services Module
module "regional_services" {
  source      = "../../modules/regional_services"
  environment = var.environment
  asg_name    = module.asg.asg_name
}