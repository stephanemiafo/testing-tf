
output "public_ip_address" {
  value = aws_instance.linux_server.public_ip
}

output "private_ip_address" {
  value = aws_instance.linux_server.private_ip
}

output "public_dns" {
  value = aws_instance.linux_server.public_dns
}

output "vpc_id" {
    value = aws_vpc.my_vpc.id
    description = "the vpc id"
}

output "public_subnets_id" {
    value       = slice(aws_subnet.subnet[*].id, 0, 3)
    description = "the list of public subnet ids"
}

output "private_subnets_id" {
    value       = slice(aws_subnet.subnet[*].id, 3, 6)
    description = "the list of private subnet ids"
}

output "database_subnets_id" {
    value       = slice(aws_subnet.subnet[*].id, 6, 9)
    description = "the list of database subnet ids"
}

output "public_subnets_cidr" {
    value =  slice(aws_subnet.subnet[*].cidr_block, 0, 3)
    description = "the list of public subnet cidrs"
}

output "private_subnets_cidr" {
    value =  slice(aws_subnet.subnet[*].cidr_block, 3, 6)
    description = "the list of private subnet cidrs"
}

output "database_subnets_cidr" {
    value =  slice(aws_subnet.subnet[*].cidr_block, 6, 9)
    description = "the list of database subnet cidrs"
}

output "availability_zone" {
    value = slice(data.aws_availability_zones.my_az.names, 0, 3)
    description = "the list of availability_zone"
}