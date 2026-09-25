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

module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  region      = var.region
}

module "compute" {
  source = "../../modules/compute"

  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  subnet_ids       = module.networking.public_subnet_ids
  instance_type    = "t3.micro"
  desired_capacity = 2
  min_size         = 1
  max_size         = 3
}

output "asg_name" {
  value = module.compute.asg_name
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}