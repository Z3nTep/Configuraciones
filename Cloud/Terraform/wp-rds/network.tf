resource "aws_vpc" "wp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "wp_vpc" }
}

resource "aws_subnet" "wp_subnet_1" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "wp_subnet_1" }
}

resource "aws_subnet" "wp_subnet_2" {
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "wp_subnet_2" }
}

resource "aws_internet_gateway" "wp_igw" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = { Name = "wp_igw" }
}

resource "aws_route_table" "wp_route_table" {
  vpc_id = aws_vpc.wp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_igw.id
  }
  tags = { Name = "wp_route_table" }
}

resource "aws_route_table_association" "wp_route_assoc_1" {
  subnet_id      = aws_subnet.wp_subnet_1.id
  route_table_id = aws_route_table.wp_route_table.id
}

resource "aws_route_table_association" "wp_route_assoc_2" {
  subnet_id      = aws_subnet.wp_subnet_2.id
  route_table_id = aws_route_table.wp_route_table.id
}
