terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "ap-southeast-2"
}

variable "environment" {
  default = "dev"
}

# -------------------------------------------------------------------
# Layer 1: Networking
# -------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  region      = var.region
}

# -------------------------------------------------------------------
# Layer 3: Load Balancer (created before compute so we can pass its
# target group ARN into the ASG)
# -------------------------------------------------------------------
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.public_subnet_ids
}

# -------------------------------------------------------------------
# Layer 2: Compute (now wired to the ALB's target group)
# -------------------------------------------------------------------
module "compute" {
  source = "../../modules/compute"

  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  subnet_ids       = module.networking.public_subnet_ids
  instance_type    = "t3.micro"
  desired_capacity = 2
  min_size         = 1
  max_size         = 3

  # The magic wiring — the ASG auto-registers into this target group
  target_group_arn = module.loadbalancer.target_group_arn
}

# -------------------------------------------------------------------
# Outputs
# -------------------------------------------------------------------
output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "alb_dns_name" {
  description = "Hit this in a browser to test the site"
  value       = module.loadbalancer.alb_dns_name
}

output "asg_name" {
  value = module.compute.asg_name
}