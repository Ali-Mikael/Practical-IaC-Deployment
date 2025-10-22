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
        { rule_no = 100, description = "Allow all outbound", protocol = "-1", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = 0, to_port = 0 }
      ]
    }
    # Private subnets NACL rules
    private = {
      ingress = [
        { rule_no = 100, description = "Allow HTTP from public subnet", protocol = "tcp", rule_action = "allow", cidr_block = var.public_subnets["main"].cidr, from_port = local.port.http, to_port = local.port.http },
        { rule_no = 110, description = "Allow HTTPS from public subnet", protocol = "tcp", rule_action = "allow", cidr_block = var.public_subnets["main"].cidr, from_port = local.port.https, to_port = local.port.https },
        { rule_no = 120, description = "Allow SSH from public subnet", protocol = "tcp", rule_action = "allow", cidr_block = var.public_subnets["main"].cidr, from_port = local.port.ssh, to_port = local.port.ssh }
      ]
      egress = [
        { rule_no = 100, description = "Allow all outgoing traffic from private subnets", protocol = "-1", rule_action = "allow", cidr_block = var.main_cidr, from_port = 0, to_port = 0 }
      ]
    }
  }
}


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
    # Web server SG
    webserver = {
      ingress = [
        { from_port = local.port.http, to_port = local.port.http, ip_protocol = "tcp", cidr_ipv4 = var.main_cidr },
        { from_port = local.port.https, to_port = local.port.https, ip_protocol = "tcp", cidr_ipv4 = var.main_cidr }
      ]
      egress = [
        { from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
    # Database server SG
    dbserver = {
      ingress = [
        { from_port = local.port.db, to_port = local.port.db, ip_protocol = "tcp", cidr_ipv4 = var.main_cidr }
      ]
      egress = [
        { from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
    # Application Load Balancer SG
    alb = {
      ingress = [
        { from_port = local.port.http, to_port = local.port.http, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
        { from_port = local.port.https, to_port = local.port.https, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
      ]
      egress = [
        { from_port = 0, to_port = 0, ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      ]
    }
  }

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


# Public key
# ----------
locals {
  public_key = file("~/.ssh/bastion_key.pub")
}
