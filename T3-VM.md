# Task 3: VM   

### Task goals
- Create Key Pair
- Create Linux VM
- Launch Linux VM to Public Subnet (requires Public IP Address)
- Tag Created Resources
- SSH to VM
- Read VM metadata with curl on VM and inlude screenshot to task README.txt
  
# Creating new key-pair locally for my instance
```
$ ssh-keygen -t ed25519 -C ali.g@bastion
```
  
<img width="473" height="72" alt="Screenshot 2025-10-20 at 23 20 46" src="https://github.com/user-attachments/assets/44182ecc-1e79-40d5-aa2f-1f1a857cb957" /> <br> 
**Now we can reference it in our code!**   
<img width="606" height="147" alt="Screenshot 2025-10-20 at 23 22 15" src="https://github.com/user-attachments/assets/9244144b-e44b-48bb-a3c4-e12d3ccddf83" />  <br> 
(Variables cannot contain expressions, so we're storing the value in locals)  
### Creating linux VM, assigning it to public subnet & associating SG   

```hcl
# File: /terraform/compute.tf
resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnets["main"].id
  key_name      = aws_key_pair.bastion_host.key_name
  vpc_security_group_ids = [
    aws_security_group.sg["instance"].id,
    aws_security_group.sg["admin"].id
  ]

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_key_pair" "bastion_host" {
  # Configure file path to your pub key in locals.tf
  key_name   = var.key_name
  public_key = local.public_key
}

# The following local exists really in /terraform/locals.tf but appended here for readability
locals {
  public_key = file("~/.ssh/bastion_key.pub")
}
```

```hcl
# File: /terraform/variables.tf
variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  type = string
  description = "SSH key name"
  default = "bh-key"
}
```
Getting the latest battle tested `Ubuntu` image for our instance automatically using the data block.
```hcl
# File: /terraform/data.tf
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

## Security group(s)
The `locals file` contains values that terraform uses as input in `/security.tf` for building SG's and their rules (and associations) dynamically. So it does all the heavy lifting for us.   

### Locals
```hcl
# File: /terraform/locals.tf

# Security groups
# --------------
locals {
  security_groups = {
    # Instance SG 
    instance = {
      ingress = [
        { from_port = local.port.http, to_port = local.port.http, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
        { from_port = local.port.https, to_port = local.port.https, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
      egress = [
        { from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
    # Admin SG to attach to an instance to enable ssh access
    admin = {
      ingress = [
        { from_port = local.port.ssh, to_port = local.port.ssh, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
      egress = [
        { from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
  }

# ---- shortened for brevity (only including the relevant details for our spesific VM -----

  # Flattening the SGs so that they can be used to dynamically create rules
  # Pre-processing it like this simplifies:
  #    resource creation, readability & maintainability
  sg_rules_flattened = flatten([
    for sg_name, sg_content in local.security_groups : [
      for direction, rules in sg_content : [
        for rule in rules : {
          sg_name     = sg_name
          direction   = direction
          from_port   = rule.from_port
          to_port     = rule.to_port
          ip_protocol = rule.ip_protocol
          cidr_ipv4   = rule.cidr_ipv4
        }
      ]
    ]
  ])
}
```
### Security.tf
```hcl
# File: /terraform/security.tf

# Security Groups
# ---------------

# Creating SGs dynamically. Input values stored in /locals.tf > security_groups{}
resource "aws_security_group" "sg" {
  for_each = local.security_groups

  name        = "${each.key}-sg"
  description = "Security group for ${each.key}"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${each.key}-sg"
  }
}

# Creating & attaching SG rules dynamically
# -----------------------------------------

# Ingress rules
resource "aws_vpc_security_group_ingress_rule" "ingress_rule" {
  # Check locals.tf for flattening of rules 
  for_each = {
    for rule in local.sg_rules_flattened : "${rule.sg_name}-${rule.direction}-${rule.from_port}" => rule
    if rule.direction == "ingress"
  }

  security_group_id = aws_security_group.sg[each.value.sg_name].id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
  depends_on        = [aws_security_group.sg]
}

# Egress rules
resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  # Check locals.tf for flattening of rules 
  for_each = {
    for rule in local.sg_rules_flattened : "${rule.sg_name}-${rule.direction}-${rule.from_port}" => rule
    if rule.direction == "egress"
  }

  security_group_id = aws_security_group.sg[each.value.sg_name].id
  # If all protocols are specified, you cannot declare ports -per AWS rules
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
  depends_on        = [aws_security_group.sg]
}
```
## Tags and IP

Because of the following section in our public subnet configuration:
```
map_public_ip_on_launch = true
```
We don't have to manually configure a public IPv4-address, we simply assign the VM to the public subnet and we're good to go!    
   
**As far as tagging goes:**
We have a default tags section in our `providers.tf` that looks like this:
```hcl
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project   = "CI/CD-platform"
      Creator   = "Ali-G"
      ManagedBy = "Terraform"
    }
  }
}
```
So this automatically applies tags to all created resources (except a few, for example: instances in ASG)    

## Routing
In order to have internet access from our subnets, we have to point all internet bound traffic to our internet-gw (if from private subnet, it has to go through the NAT gw first).  
Building upon our previous network configurations:
```hcl
# File: /terraform/networking.tf

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
```



## Logging in
```bash
$ terraform init
```

```bash
$ terraform -auto-apply
```

<img width="298" height="144" alt="Screenshot 2025-10-21 at 21 18 04" src="https://github.com/user-attachments/assets/37b3def8-8782-41f4-aa74-c855071444a7" /> <br>  
Because of the output variables we have configured, we get the public ip to our instance, which we can then connect to!   
First we want to make sure everything looks good.   
<img width="1372" height="630" alt="Screenshot 2025-10-21 at 21 11 33" src="https://github.com/user-attachments/assets/b994f35a-2218-4aef-90d1-46d3e5c1b8fe" /> <br>   

### Instance details
<img width="848" height="339" alt="Screenshot 2025-10-21 at 21 21 43" src="https://github.com/user-attachments/assets/4932399c-0d11-4d81-b8e4-d11061c3fca1" /> <br>   
<img width="1234" height="512" alt="Screenshot 2025-10-21 at 21 22 29" src="https://github.com/user-attachments/assets/d577974b-f5ad-46c4-8724-ff87aa0ba415" /> <br>   

#### Good to go!
<img width="1029" height="304" alt="Screenshot 2025-10-21 at 21 58 24" src="https://github.com/user-attachments/assets/633c5228-6f3b-450e-9744-eded3f8e5823" /> <br>   
<img width="848" height="346" alt="Screenshot 2025-10-21 at 22 00 37" src="https://github.com/user-attachments/assets/481d3fca-7589-463f-9e98-b6ecdff7a881" />







