terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"  # Always specify version!
  
  name = "registry-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost savings
  enable_dns_hostnames = true
  
  # Tags
  tags = {
    Environment = "dev"
    Project     = "registry-demo"
    ManagedBy   = "Terraform"
  }
  
  vpc_tags = {
    Name = "registry-vpc"
  }
}
# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance Module
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"
  
  name = "registry-web-server"
  
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.amazon_linux_2.id
  vpc_security_group_ids      = [module.security_group_web.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  
  # User data
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Registry Module!</h1>" > /var/www/html/index.html
              EOF
  
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
module "security_group_web" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  
  name        = "web-server-sg"
  description = "Security group for web server"
  vpc_id      = module.vpc.vpc_id
  
  # Ingress rules
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  
  # Custom SSH rule
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  
  # Egress
  egress_rules = ["all-all"]
  
  tags = {
    Environment = "dev"
  }
}
