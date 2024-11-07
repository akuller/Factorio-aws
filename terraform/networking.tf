

resource "aws_vpc" "factorio_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "factorio"
  }
}

resource "aws_subnet" "factorio_a" {
  vpc_id     = aws_vpc.factorio_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "factorio_a"
  }
}

resource "aws_subnet" "factorio_b" {
  vpc_id     = aws_vpc.factorio_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "factorio_b"
  }
}

# resource "aws_subnet" "factorio_c" {
#   vpc_id     = aws_vpc.factorio_vpc.id
#   cidr_block = "10.0.3.0/24"
#
#   tags = {
#     Name = "factorio_c"
#   }
# }

resource "aws_internet_gateway" "factorio_igw" {
  vpc_id = aws_vpc.factorio_vpc.id

  tags = {
    Name = "facotorio_igw"
  }
}

resource "aws_route_table" "factorio_route_table" {
  vpc_id = aws_vpc.factorio_vpc.id
}

resource "aws_route" "route_a" {
  route_table_id         = aws_route_table.factorio_route_table.id
  gateway_id             = aws_internet_gateway.factorio_igw.id
  destination_cidr_block = aws_subnet.factorio_a.cidr_block
}

resource "aws_route" "route_b" {
  route_table_id         = aws_route_table.factorio_route_table.id
  gateway_id             = aws_internet_gateway.factorio_igw.id
  destination_cidr_block = aws_subnet.factorio_b.cidr_block
}

# resource "aws_route" "route_c" {
#   route_table_id = aws_route_table.factorio_route_table.id
#   gateway_id = aws_internet_gateway.factorio_igw.id
#   destination_cidr_block = aws_subnet.factorio_c.cidr_block
# }