# Task 2: Create a Firewall

**Instructions from Pekka:**   
Task goals:  
- Public Subnet firewall: allow 22, 80, 443 from the Internet
- Private Subnet firewall: allow 22, 80, 443 from Public Subnet

## locals.tf:
```hcl
locals {
  # Port values to be used in NACLs & SGs etc..
  port = {
    http            = 80
    https           = 443
    ssh             = 22
    ephemeral_start = 1024
    ephemeral_end   = 65535
    db              = 3306
  }
}

# NACL rules
# ----------
locals {
  nacl_rules = {
    # Public subnet NACL rules
    public = {
      ingress = [
        { rule_no = 100, description = "Allow HTTP into the public subnet", protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = local.port.http, to_port = local.port.http },
        { rule_no = 110, description = "Allow HTTPS into the public subnet", protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = local.port.https, to_port = local.port.https },
        { rule_no = 120, description = "Allow SSH into public subnet", protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = local.port.ssh, to_port = local.port.ssh }
      ]
      egress = [
        { rule_no = 100, description = "Allow all outbound", protocol = "-1", rule_action = "allow", cidr_block = var.main_cidr, from_port = 0, to_port = 0 }
      ]
    }
    # Private subnets NACL rules
    private = {
      ingress = [
        { rule_no = 100, description = "Allow HTTP from public subnet", protocol = "tcp", rule_action = "allow", cidr_block = var.public_subnets["main"].cidr, from_port = local.port.http, to_port = local.port.http },
        { rule_no = 110, description = "Allow HTTPS from public subnet", protocol = "tcp", rule_action = "allow", cidr_block = var.public_subnets["main"].cidr, from_port = local.port.https, to_port = local.port.https },
        { rule_no = 120, description = "Allow SSH from public subnet", protocol = "tcp", rule_action = "allow", cidr_block = var.public_subnets["main"].cidr, from_port = local.port.http, to_port = local.port.http }
      ]
      egress = [
        { rule_no = 100, description = "Allow all outgoing traffic from private subnets", protocol = "-1", rule_action = "allow", cidr_block = var.main_cidr, from_port = 0, to_port = 0 }
      ]
    }
  }
}
```
## security.tf
```hcl
# NACLs
# -----
resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.main.id

  for_each = {
    public  = "Public-Subnet-NACL"
    private = "Private-Subnet-NACL"
  }

  tags = {
    Name = each.value
  }

  # Create ingress and egress rules dynamically for each NACL.
  # The [each.key] ensures rules are matched to the correct NACL defined in locals.tf.
  dynamic "ingress" {
    for_each = lookup(local.nacl_rules[each.key], "ingress", [])

    content {
      rule_no    = ingress.value.rule_no
      protocol   = ingress.value.protocol
      action     = ingress.value.action
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      cidr_block = ingress.value.cidr_block
    }
  }

  dynamic "egress" {
    for_each = lookup(local.nacl_rules[each.key], "egress", [])

    content {
      rule_no    = egress.value.rule_no
      protocol   = egress.value.protocol
      action     = egress.value.action
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      cidr_block = egress.value.cidr_block
    }
  }
}


# NACL Associations
# -----------------

resource "aws_network_acl_association" "public" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.nacl["public"].id
}

resource "aws_network_acl_association" "private" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.nacl["private"].id
}
```

```bash
$ terraform init
```
```bash
$ terrafrom apply -auto-approve
```

This Terraform code creates NACLs and their rules *dynamically*, using values derived from `locals.tf`, and then associates them (the NACLs) with correct subnets, building on information from previous configurations in `networking.tf`.     

### ACLs
<img width="1657" height="250" alt="Screenshot 2025-10-22 at 12 28 34" src="https://github.com/user-attachments/assets/1dc2093a-a3d9-4e98-b019-f4b8e57f78f0" />    

### Private NACL
<img width="1647" height="552" alt="Screenshot 2025-10-22 at 12 33 41" src="https://github.com/user-attachments/assets/cd00e2e2-057e-4035-a7f6-1ea7dab72ae9" /> <br>    
<img width="1637" height="355" alt="Screenshot 2025-10-22 at 12 34 06" src="https://github.com/user-attachments/assets/9d4bc6ac-983c-4dc4-ab80-084839929778" /> <br>   
<img width="308" height="229" alt="Screenshot 2025-10-22 at 12 37 07" src="https://github.com/user-attachments/assets/5582fb24-f807-41ee-97d4-ae99cef2ba3f" /> <br>   

# Public NACL
<img width="1646" height="555" alt="Screenshot 2025-10-22 at 12 34 40" src="https://github.com/user-attachments/assets/be0a7396-b28c-43d3-b2a2-857714c2f63b" /> <br>   
<img width="1635" height="209" alt="Screenshot 2025-10-22 at 12 35 10" src="https://github.com/user-attachments/assets/5279e2e0-3803-4049-832d-2b983493bf26" /> <br>    
<img width="319" height="223" alt="Screenshot 2025-10-22 at 12 36 37" src="https://github.com/user-attachments/assets/6fd736bd-be90-479e-989c-8a670536830e" /> <br>   
   
Everything seems to be working. 💯   
We also created security groups, which we will illuminate more upon in the `VM` task!  
Thank you for watching and till next time! 😄
