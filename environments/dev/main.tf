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

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}