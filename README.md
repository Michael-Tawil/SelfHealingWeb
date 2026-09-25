# Auto-Healing Web Tier

Terraform code for a self-healing and load-balanced web tier on AWS.

## Cloud Choice

AWS: mature well-documented for TerraForm and im most familiar with its patterns.

## Architecture

- VPC with 2 public subnets across 2 AZs (ap-southeast-2a, ap-southeast-2b)
- Internet Gateway for public access
- Launch Template running Amazon Linux 2 + NGINX via `user_data`
- Auto Scaling Group: desired = 2, min = 1, max = 3, spread across both AZs
- Application Load Balancer + Target Group + HTTP listener

## How It Works

The ASG maintains 2 healthy instances. If an instance fails the ALB health check or is terminated, the ASG replaces it automatically. The ALB only routes traffic to healthy instances, so there's no downtime during replacement.

## How to Run

```bash
cd environments/dev
terraform init
terraform plan
