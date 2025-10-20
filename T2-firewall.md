# Task 2: Create a Firewall

**Instructions from Pekka:**   
Task goals:  
- Public Subnet firewall: allow 22, 80, 443 from the Internet
- Private Subnet firewall: allow 22, 80, 443 from Public Subnet   

## security.tf:
```
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
You might want to check out the `/terraform` folder to see how this all plays together!  

Cheerio!
