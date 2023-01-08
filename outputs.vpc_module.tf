output "vpc_id"{
    value = aws_vpc.vpc.id
}
output "public_subnets" {
   value = aws_subnet.public[*].id
}
output "private_subnets" {
   value = aws_subnet.private[*].id
}

output "nat_gw" {
  
  value = aws_nat_gateway.nat_gw
}
