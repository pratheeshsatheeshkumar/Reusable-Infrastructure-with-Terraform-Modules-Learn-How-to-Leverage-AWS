locals {
  subnets = length(data.aws_availability_zones.available.names)
}
variable "cidr_vpc" {}
variable "project" {
  default ="demo"
}
variable "environment" {}
variable "enable_nat_gateway" {
  type = bool
}