locals {

  # Port values to be used in NACLs & SGs etc..
  port = {
    http            = 80
    https           = 443
    ssh             = 22
    ephemeral_start = 1024
    ephemeral_end   = 65535
  }


  # NACL rules
  nacl_rules = {

    # Public subnet NACL rules
    public = {
      ingress = [
        { rule_no = 100, description = "Allow HTTP into the public subnet", protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = local.port.http, to_port = local.port.http },
        { rule_no = 110, description = "Allow HTTPS into the public subnet" ,protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = local.port.https, to_port = local.port.https },
        { rule_no = 120, description = "Allow SSH into public subnet", protocol = "tcp", rule_action = "allow", cidr_block = "0.0.0.0/0", from_port = local.port.ssh, to_port = local.port.ssh }
      ]
      egress = [
        { rule_no = 100,description = "Allow all outbound", protocol = "-1", rule_action = "allow", cidr_block = var.main_cidr, from_port = 0, to_port = 0 }
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