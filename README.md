# Lab M4.06 - Terraform Registry Modules

## Overview

This lab demonstrates deploying production-ready AWS infrastructure using official [Terraform Registry](https://registry.terraform.io/) modules. Rather than writing raw resources, we leverage community-maintained modules to provision a fully networked VPC with a web server in minutes.

## Architecture

```
Internet
    │
    ▼
[Security Group] ─── HTTP/HTTPS/SSH
    │
[EC2 t3.micro] ─── Apache Web Server
    │
[Public Subnet us-east-1a] (10.0.101.0/24)
    │
[VPC 10.0.0.0/16]
    ├── Public Subnets:  10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24
    ├── Private Subnets: 10.0.1.0/24,   10.0.2.0/24,   10.0.3.0/24
    └── NAT Gateway (single, cost-optimized)
```

## Modules Used

| Module | Source | Version | Purpose |
|--------|--------|---------|---------|
| VPC | `terraform-aws-modules/vpc/aws` | 5.1.0 | Network with public/private subnets |
| EC2 Instance | `terraform-aws-modules/ec2-instance/aws` | 5.5.0 | Web server instance |
| Security Group | `terraform-aws-modules/security-group/aws` | 5.1.0 | Firewall rules |

## Infrastructure Details

### VPC
- **CIDR**: `10.0.0.0/16`
- **Availability Zones**: `us-east-1a`, `us-east-1b`, `us-east-1c`
- **Public Subnets**: 3 (one per AZ)
- **Private Subnets**: 3 (one per AZ)
- **NAT Gateway**: Single (cost-optimized for dev)
- **DNS Hostnames**: Enabled

### EC2 Instance
- **Name**: `registry-web-server`
- **Type**: `t3.micro`
- **AMI**: Latest Amazon Linux 2 (dynamic lookup)
- **Subnet**: First public subnet (`us-east-1a`)
- **Public IP**: Assigned automatically
- **Web Server**: Apache (httpd), started via user data

### Security Group
- **Inbound**: HTTP (80), HTTPS (443), SSH (22) from `0.0.0.0/0`
- **Outbound**: All traffic allowed

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with valid credentials
- AWS provider ~> 5.0

## Usage

```bash
# Initialize and download registry modules
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Get web server URL
terraform output web_url

# Destroy when done
terraform destroy
```

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `public_subnets` | List of public subnet IDs |
| `private_subnets` | List of private subnet IDs |
| `instance_id` | EC2 instance ID |
| `instance_public_ip` | Public IP address |
| `web_url` | Web server URL (`http://<public-ip>`) |
| `security_group_id` | Security group ID |

## Access

After `terraform apply`, retrieve the web server URL:

```bash
terraform output web_url
```

Then open in your browser or test with:

```bash
curl $(terraform output -raw web_url)
```

## Key Concepts Demonstrated

- **Registry modules**: Reusing battle-tested, community modules instead of raw resources
- **Version pinning**: Explicit module versions prevent unexpected drift
- **Data sources**: Dynamic AMI lookup ensures latest Amazon Linux 2
- **Module composition**: Modules referencing each other's outputs (VPC → SG → EC2)
- **Cost optimization**: Single NAT Gateway for non-production workloads
