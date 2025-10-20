# ----------
# Networking
# ----------

# VPC
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
    Name = "main-vpc-igw"
  }
}


# EIP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "main-nat-eip"
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.public_subnets["main"].id
  allocation_id = aws_eip.nat.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "main-nat-gw"
  }
}



# Public subnet(s)
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
  }
}

# Private subnet(s)
resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = each.value.name
  }
}

# Routing
# -------

# rt for public subnets
resource "aws_route_table" "public_subnet_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-subnet-rt"
  }
}
resource "aws_route_table_association" "public_subnet" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

# rt for private subnets 
resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.main.id

  # Internet bound traffic through the nat gw
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private-subnet-rt"
  }
} 
resource "aws_route_table_association" "private_subnet" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_subnet_rt.id
}