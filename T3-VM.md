# Task 3: VM   

### Task goals
- Create Key Pair
- Create Linux VM
- Launch Linux VM to Public Subnet (requires Public IP Address)
- Tag Created Resources
- SSH to VM
- Read VM metadata with curl on VM and inlude screenshot to task README.txt
  
Creating new key-pair locally for my instance:  
```
$ ssh-keygen -t ed25519 -C ali.g@bastion
```
  
<img width="473" height="72" alt="Screenshot 2025-10-20 at 23 20 46" src="https://github.com/user-attachments/assets/44182ecc-1e79-40d5-aa2f-1f1a857cb957" /> <br> 
**Now we can reference it in our code!**   
<img width="606" height="147" alt="Screenshot 2025-10-20 at 23 22 15" src="https://github.com/user-attachments/assets/9244144b-e44b-48bb-a3c4-e12d3ccddf83" />  <br> 

Creating linux VM, assigning it to public subnet and associating SG   

```hcl
# File: /terraform/compute.tf
resource "aws_instance" "bastion_host" {
  ami           = var.ami_id
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
variable "ami_id" {
  description = "Ubuntu AMI for instances"
  default = data.aws_ami.ubuntu.id
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  type = string
  description = "SSH key name"
  default = "bh-key"
}
```
Getting the latest battle tested ubuntu image for our instance automatically using the data block, and then referencing it in our variable, so that if we want we can overide this default.
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
Note: If you want to check out the security groups configurations. Go through `/locals.tf` section: **security_groups{}**.   
After that you can examine `/security.tf`   
But anyway lets crack on.   

Because of the following section in our public subnet configuration:
```
map_public_ip_on_launch = true
```
We don't have to manually configure a public IPv4-address, we simply assign the VM to the public subnet and we're good to go!   

### Logging in

