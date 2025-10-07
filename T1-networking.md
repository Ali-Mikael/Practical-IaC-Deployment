# Task 1: Networking

### Terraform code
```
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
}



# Networking
# Note: us-east-1 has 6 AZs (a-f) to choose from

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

```
<br>

Running `$ terraform apply`, will effectively create you a new VPC `name = main` (indifferent to default VPC), and by using `aws_vpc.main.id` within your code, always deploy your stuff in this VPC. <br>

This also creates 5 subnets. 1 public and 4 private ones! <br>
VPC CIDR = 10.0.0.0/16 <br> 
Public subnet = 10.0.1.0/24 <br>
Private subnet1 =
