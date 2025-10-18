terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project   = "CI/CD-platform"
      Creator   = "Ali-G"
      ManagedBy = "Terraform"
    }
  }
}
