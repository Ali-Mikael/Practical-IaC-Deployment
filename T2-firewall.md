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

This Terraform code creates NACLs and their rules *dynamically*, using values derived from `locals.tf`, and then associates them (the NACLs) with correct subnets, building on information from previous configurations in `networking.tf`.  


Cheerio!
