terraform {
  required_version = ">= 1.6.1" # required Terraform version to be greater than or equal to 1.6.1.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # version >= 5.0 but less than 6.0 is acceptable for aws providers.
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.0" # version >= 2.0 but less than 3.0 is acceptable for random providers. 
    }
  }
}

provider "aws" {
  region = var.aws_region
}


