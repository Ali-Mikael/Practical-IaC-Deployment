# Instances
# ---------

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
