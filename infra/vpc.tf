# vault + boundary worker

data "aws_availability_zones" "vault" {}

resource "aws_vpc" "vault_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = local.vault_tags
}

resource "aws_subnet" "vault_subnet" {
  vpc_id                  = aws_vpc.vault_vpc.id
  cidr_block              = aws_vpc.vault_vpc.cidr_block
  availability_zone       = data.aws_availability_zones.vault.names[0]
  map_public_ip_on_launch = true
  tags                    = local.vault_tags
}

resource "aws_internet_gateway" "vault_gateway" {
  vpc_id = aws_vpc.vault_vpc.id
  tags   = local.vault_tags
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vault_vpc.id
  tags   = local.vault_tags
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vault_gateway.id
}

resource "aws_route_table_association" "vault_subnet_assocs" {
  route_table_id = aws_route_table.route_table.id
  subnet_id      = aws_subnet.vault_subnet.id
}

# session recording

data "aws_availability_zones" "azs" {}

resource "aws_vpc" "target_vpc" {
  count                = var.instance_count
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${format("target-vpc-${local.deployment_name}-%03d", count.index + 1)}",
    User = "${local.deployment_name}"
  }
}

resource "aws_subnet" "target_subnet" {
  count                   = var.instance_count
  vpc_id                  = aws_vpc.target_vpc[count.index].id
  cidr_block              = aws_vpc.target_vpc[count.index].cidr_block
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${format("target-subnet-${local.deployment_name}-%03d", count.index + 1)}",
    User = "${local.deployment_name}"
  }
}

resource "aws_internet_gateway" "target_gateway" {
  count  = var.instance_count
  vpc_id = aws_vpc.target_vpc[count.index].id
  tags = {
    Name = "${format("target-ig-${local.deployment_name}-%03d", count.index + 1)}",
    User = "${local.deployment_name}"
  }
}

resource "aws_route_table" "target_route_table" {
  count  = var.instance_count
  vpc_id = aws_vpc.target_vpc[count.index].id
  tags = {
    Name = "${format("target-rt-${local.deployment_name}-%03d", count.index + 1)}",
    User = "${local.deployment_name}"
  }
}

resource "aws_route" "target_route" {
  count                  = var.instance_count
  route_table_id         = aws_route_table.target_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.target_gateway[count.index].id
}

resource "aws_route_table_association" "target_subnet_assocs" {
  count          = var.instance_count
  route_table_id = aws_route_table.target_route_table[count.index].id
  subnet_id      = aws_subnet.target_subnet[count.index].id
}

