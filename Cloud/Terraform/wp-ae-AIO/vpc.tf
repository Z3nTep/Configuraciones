resource "aws_vpc" "wp_ae_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "wp-ae-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.wp_ae_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "us-east-1${element(["a", "b"], count.index)}"
  map_public_ip_on_launch = true
  tags = {
    Name = "public${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 4
  vpc_id            = aws_vpc.wp_ae_vpc.id
  cidr_block        = "10.0.${10 + count.index}.0/24"
  availability_zone = "us-east-1${element(["a", "b", "a", "b"], count.index)}"
  tags = {
    Name = "private${count.index + 1}"
  }
}

resource "aws_internet_gateway" "wp_igw" {
  vpc_id = aws_vpc.wp_ae_vpc.id
  tags = {
    Name = "wp-ae-igw"
  }
}

resource "aws_eip" "nat" {
  count = 2
  domain   = "vpc"
  tags = {
    Name = "nat-eip-${element(["a", "b"], count.index)}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.wp_igw]
  tags = {
    Name = "nat-${element(["a", "b"], count.index)}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.wp_ae_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wp_igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.wp_ae_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "private-rt-${element(["a", "b"], count.index)}"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 4
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % 2].id
}
