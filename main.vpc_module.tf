/*==== vpc ======*/
/*create vpc in the cidr "172.16.0.0/16" */

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}

/*==== IGW ======*/
/* Create internet gateway for the public subnets and attach with vpc */

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${var.environment}"
  }
}
/*==== Public Subnets ======*/
/* Creation of Public subnets, one for each availability zone in the region  */

resource "aws_subnet" "public" {
  count = local.subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-${var.environment}-public${count.index + 1}"
  }
}

/*==== Private Subnets ======*/
/* Creation of Private  subnets, one for each availability zone in the region  */

resource "aws_subnet" "private" {
  count = local.subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_vpc, 4, (count.index + local.subnets))
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-${var.environment}-private${count.index + 1}"
  }
}

/*==== Elastic IP ======*/
/* Creation of Elastic IP for  NAT Gateway */

resource "aws_eip" "nat_ip" {

  count = var.enable_nat_gateway ? 1 : 0
  vpc = true
}

/*==== NAT GW creation and attachment of EIP ======*/
/* Attachment of Elastic IP for the public access of NAT Gateway */

resource "aws_nat_gateway" "nat_gw" {

  count = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_ip[count.index].id
  subnet_id     = aws_subnet.public[2].id

  tags = {
    Name = "${var.project}-${var.environment}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

/*==== Public Route Table ======*/
/* Creation of route for public access via the Internet gateway for the vpc */

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project}-${var.environment}-public"
  }
}

/*==== Private Route Table =======*/
/*Creation of Private Route Table with route for public access via the NAT gateway */

resource "aws_route_table" "private" {
  
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project}-${var.environment}-private"
  }
}

/*==== Private Route for NAT GW =======*/
/*Creation of Private Route for public access via the NAT gateway */

resource "aws_route" "private_route" {

  route_table_id  = aws_route_table.private.id
  count = var.enable_nat_gateway ? 1 : 0
  destination_cidr_block     = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
}

/*==== Association Public Route Table ======*/
/*Association of Public route table with public subnets. */

resource "aws_route_table_association" "public" {
  count = local.subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

/*==== Association Private Route Table ======*/
/*Association of Private route table with private subnets. */

resource "aws_route_table_association" "private" {
  count = local.subnets
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}





