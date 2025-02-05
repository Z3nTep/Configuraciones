resource "aws_vpc" "wp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "wp_vpc" }
}

resource "aws_subnet" "wp_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.wp_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
  tags = { Name = "wp_subnet_${count.index + 1}" }
}

resource "aws_internet_gateway" "wp_igw" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = { Name = "wp_igw" }
}

resource "aws_route_table" "wp_rt" {
  vpc_id = aws_vpc.wp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_igw.id
  }
  tags = { Name = "wp_rt" }
}

resource "aws_route_table_association" "wp_rta" {
  count          = 2
  subnet_id      = aws_subnet.wp_subnet[count.index].id
  route_table_id = aws_route_table.wp_rt.id
}
