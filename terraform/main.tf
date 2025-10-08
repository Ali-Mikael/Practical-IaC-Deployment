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

