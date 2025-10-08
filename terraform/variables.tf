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


