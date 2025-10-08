# Task 1: Networking && Task 9: NAT GW

### Terraform code
```
/terraform/variables.tf 
>>
variable "main_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet config"
  type = map(object({
    name = string
    az   = string
    cidr = string
  }))

  default = {
    main = { name = "public-subnet-main", az = "us-east-1a", cidr = "10.0.1.0/24" }
  }
}


variable "private_subnets" {

  description = "Private subnet config"
  type = map(object({
    name = string
    az   = string
    cidr = string
  }))

  default = {
    websubnet1  = { name = "webb-subnet-private1", az = "us-east-1b", cidr = "10.0.5.0/24" },
    websubnet2  = { name = "webb-subnet-private2", az = "us-east-1c", cidr = "10.0.6.0/24" },
    appsubnet1  = { name = "app-subnet-private1", az = "us-east-1d", cidr = "10.0.7.0/24" },
    appsubnet2  = { name = "app-subnet-private2", az = "us-east-1e", cidr = "10.0.8.0/24" },
    datasubnet1 = { name = "data-subnet-private1", az = "us-east-1a", cidr = "10.0.9.0/24" },
    datasubnet2 = { name = "data-subnet-private2", az = "us-east-1f", cidr = "10.0.10.0/24" }
  }
}



/terraform/main.tf
# Networking
resource "aws_vpc" "main" {
  cidr_block       = var.main_cidr
  instance_tenancy = "default"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}


# The Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-vpc-IGW"
  }
}


# EIP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "main-NAT-EIP"
  }
}
# NAT gateway
resource "aws_nat_gateway" "NAT_GW" {
  subnet_id     = aws_subnet.public["main"].id
  allocation_id = aws_eip.nat.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "main-NAT-gw"
  }
}

# Public subnet(s)
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

# Private subnets
resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
  }
}
```
<br>

Running `$ terraform apply`, will effectively create you a new VPC `name = main-vpc` (indifferent to default VPC), and by using `aws_vpc.main.id` within your code, always deploy your stuff in this VPC. <br>

### This also creates:
- 5 subnets. 1 public and 4 private ones! <br>
- VPC CIDR = 10.0.0.0/16 <br> 
- Public subnet = 10.0.1.0/24 <br>
- Private subnets = 10.0.x.0/24 <br>
- An internet gateway (with association)
- A NAT gateway with an EIP, associated with the public subnet.
<br>
`$ Apply complete! Resources: 11 added, 0 changed, 0 destroyed.`
<br>
<img width="1133" height="188" alt="Screenshot 2025-10-08 at 15 56 21" src="https://github.com/user-attachments/assets/c40f313e-b9f3-4e8f-9109-39be700d5681" />
<br>
<img width="704" height="628" alt="Screenshot 2025-10-08 at 16 10 22" src="https://github.com/user-attachments/assets/b471f3ee-9e5f-46c2-90b5-ebc39d23cbba" />
<br>
<img width="1252" height="354" alt="Screenshot 2025-10-08 at 15 52 44" src="https://github.com/user-attachments/assets/ca237f63-b0cb-48df-ae10-a20073c5e685" />
<br>
<img width="1066" height="184" alt="Screenshot 2025-10-08 at 15 53 05" src="https://github.com/user-attachments/assets/3bc1a931-2a90-4737-915b-a98882affe1a" />
<br>
<img width="1107" height="147" alt="Screenshot 2025-10-08 at 15 56 54" src="https://github.com/user-attachments/assets/0f588946-eec1-4dbf-b7cf-689cfa27a621" />
<br>
<img width="1397" height="134" alt="Screenshot 2025-10-08 at 16 08 27" src="https://github.com/user-attachments/assets/93c5b0d1-4e8d-448a-8153-513a25471561" />
