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