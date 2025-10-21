# NACLs
# -----
resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.main.id

  for_each = {
    public  = "public-Subnet-nacl"
    private = "private-Subnet-nacl"
  }

  tags = {
    Name = each.value
  }

  # Create ingress and egress rules dynamically for each NACL.
  # The [each.key] ensures rules are matched to the correct NACL defined in locals.tf
  dynamic "ingress" {
    for_each = lookup(local.nacl_rules[each.key], "ingress", [])

    content {
      rule_no    = ingress.value.rule_no
      protocol   = ingress.value.protocol
      action     = ingress.value.rule_action
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
      action     = egress.value.rule_action
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      cidr_block = egress.value.cidr_block
    }
  }
}

# NACL Associations
# -----------------
# Public subnet association with the public nacl
resource "aws_network_acl_association" "public" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.nacl["public"].id
}
# Private subnet association w the private nacl
resource "aws_network_acl_association" "private" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.nacl["private"].id
}


# Security Groups
# ---------------

# Creating SGs dynamically. Config in locals.tf/ security_groups{}
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

resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  # Check locals.tf for flattening of rules 
  for_each = {
    for rule in local.sg_rules_flattened : "${rule.sg_name}-${rule.direction}-${rule.from_port}" => rule
    if rule.direction == "egress"
  }

  security_group_id = aws_security_group.sg[each.value.sg_name].id
  # If all protocols are specified, you cannot declare ports per AWS rules
  from_port         = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
  depends_on        = [aws_security_group.sg]
}
