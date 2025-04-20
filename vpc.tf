resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-subnet"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}a"
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-private-subnet"
  })
}

resource "aws_subnet" "efs_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.efs_subnet_cidr
  availability_zone = "${var.region}a"
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-efs-subnet"
  })
}

resource "aws_subnet" "bastion_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_az2
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-subnet-az2"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-natgw"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-nat-eip"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-rt"
  })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-private-rt"
  })

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "bastion_az2" {
  subnet_id      = aws_subnet.bastion_az2.id
  route_table_id = aws_route_table.public.id
}
