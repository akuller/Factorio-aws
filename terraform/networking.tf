data "aws_availability_zones" "available" { state = "available" }

resource "aws_vpc" "factorio_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "factorio"
  }
}

resource "aws_subnet" "factorio_a" {
  vpc_id                  = aws_vpc.factorio_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "factorio_a"
  }
}

resource "aws_subnet" "factorio_b" {
  vpc_id                  = aws_vpc.factorio_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "factorio_b"
  }
}

resource "aws_internet_gateway" "factorio_igw" {
  vpc_id = aws_vpc.factorio_vpc.id
  tags = {
    Name = "facotorio_igw"
  }
}

resource "aws_route_table" "factorio_route_table" {
  vpc_id = aws_vpc.factorio_vpc.id
  tags   = { Name = "factorio-rt-public" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.factorio_igw.id
  }
}

resource "aws_route_table_association" "factorio_a" {
  route_table_id = aws_route_table.factorio_route_table.id
  subnet_id      = aws_subnet.factorio_a.id
}

resource "aws_route_table_association" "factorio_b" {
  route_table_id = aws_route_table.factorio_route_table.id
  subnet_id      = aws_subnet.factorio_b.id
}


resource "aws_security_group" "instance_sg" {
  name   = "factorio-instance-sg"
  vpc_id = aws_vpc.factorio_vpc.id
  ingress {
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 27015
    to_port     = 27015
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "factorio-efs-sg" {
  name        = "factorio-efs-sg"
  description = "factorio efs security group"
  vpc_id      = aws_vpc.factorio_vpc.id
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}