
output "vpc_id" {
  value = aws_vpc.factorio_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.factorio_vpc.cidr_block
}

output "vpc_arn" {
  value = aws_vpc.factorio_vpc.arn
}

output "subnet_a_arn" {
  value = aws_subnet.factorio_a.arn
}

output "subnet_a_cidr" {
  value = aws_subnet.factorio_a.cidr_block
}

output "subnet_a_id" {
  value = aws_subnet.factorio_a.id
}

output "subnet_a_zone" {
  value = aws_subnet.factorio_a.availability_zone
}

output "sbunet_b_arn" {
  value = aws_subnet.factorio_b.arn
}

output "sbunet_b_cidr" {
  value = aws_subnet.factorio_b.cidr_block
}

output "sbunet_b_id" {
  value = aws_subnet.factorio_b.id
}

output "sbunet_b_zone" {
  value = aws_subnet.factorio_b.availability_zone
}