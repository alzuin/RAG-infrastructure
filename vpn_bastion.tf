resource "aws_eip" "vpn_bastion" {
  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-bastion-eip"
  })
}

locals {
  vpc_cidr         = var.vpc_cidr
  vpn_right_subnet = var.vpn_peer_cidr_block
  vpn_right_ip     = var.my_home_ip_cidr
  vpn_left_id      = "@aws-vpn"
  vpn_right_id     = "@unifi-vpn"
}

locals {
  rendered_ipsec_conf = templatefile("${path.module}/vpn-config/ipsec.conf.tmpl", {
    left_id      = local.vpn_left_id
    right_id     = local.vpn_right_id
    left_subnet  = local.vpc_cidr
    right_subnet = local.vpn_right_subnet
    right_ip     = local.vpn_right_ip
  })

  rendered_user_data = templatefile("${path.module}/vpn_bastion_user_data.sh.tmpl", {
    files = concat(
      [
        {
          name    = "ipsec.conf"
          content = local.rendered_ipsec_conf
        },
        {
          name    = "strongswan.conf"
          content = file("${path.module}/vpn-config/strongswan.conf")
        }
      ]
    )
    ipsec_secrets = var.ipsec_secrets
  })
}

resource "aws_security_group" "vpn_bastion_sg" {
  name        = "${local.name_prefix}-vpn-bastion-sg"
  description = "Allow SSH and IPSec from home"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_home_ip_cidr]
  }

  ingress {
    description = "IPSec IKE (UDP 500)"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = [var.my_home_ip_cidr]
  }

  ingress {
    description = "IPSec NAT-T (UDP 4500)"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = [var.my_home_ip_cidr]
  }

  ingress {
    description = "ESP"
    from_port   = -1
    to_port     = -1
    protocol    = "50"
    cidr_blocks = [var.my_home_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "external_key" {
  key_name   = "alberto-local-key"
  public_key = var.ssh_public_key
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "vpn_bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.vpn_bastion_instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.external_key.key_name
  vpc_security_group_ids      = [aws_security_group.vpn_bastion_sg.id]

  source_dest_check = false

  user_data = local.rendered_user_data

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-vpn-bastion"
  })
}

resource "aws_network_interface" "vpn_bastion_eni" {
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.vpn_bastion_sg.id]
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-vpn-bastion-eni"
  })
}

resource "aws_network_interface_attachment" "vpn_bastion_attachment" {
  instance_id          = aws_instance.vpn_bastion.id
  network_interface_id = aws_network_interface.vpn_bastion_eni.id
  device_index         = 1
}

resource "aws_eip_association" "vpn_bastion_assoc" {
  instance_id   = aws_instance.vpn_bastion.id
  allocation_id = aws_eip.vpn_bastion.id
}

resource "aws_route" "route_to_home_network" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.vpn_peer_cidr_block
  network_interface_id   = aws_network_interface.vpn_bastion_eni.id
}

resource "aws_route" "route_to_home_network_efs_subnet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = var.vpn_peer_cidr_block
  network_interface_id   = aws_network_interface.vpn_bastion_eni.id
}

