/*==== Variable declerations ======*/

variable "project" {

  default     = "zomato"
  description = "Name of the project"
}

variable "instance_type" {}

variable "instance_ami" {}

variable "cidr_vpc" {}

variable "environment" {}

variable "enable_nat_gateway" {}

variable "region" {

  default     = "ap-south-1"
  description = "Region: Mumbai"
}

variable "access_key" {

  #default     = "AKIAVMDQREWV2AMXBIA7"
  default      = "AKIAYHVF6JBOY34ZLHWR" #DevOps LAB
  description = "access key of the provider"
}

variable "secret_key" {

 # default     = "IpM31fx/SXy/38Dj9O+Jw8SfoDAfd0wD8N0DuY0Z"
   default     = "CylWiXG1J8mKO5P9bOVkEJ5r/WL9HkT6eeMmQ39E" #DevOps LAB
  description = "secret key of the provider"
}



variable "owner" {

  default = "pratheesh"
}

variable "application" {

  default = "food-order"
}

variable "public_domain" {
  
  default = "pratheesh.tech"
}
variable "private_domain" {
  
  default = "pratheesh.local"
}

variable "db_name" {

  default = "wp_db"
}

variable "db_user" {
  
  default = "wp_user"
}

variable "db_passwd" {
  
  default = "wp_user@123"
}

/*== ip_pool list for assigning prefix_list==*/
variable "ip_pool" {

  type = list(string)
  default = [
    "117.216.234.255/32",
    "1.1.1.1/32",
    "2.2.2.2/32",
    "3.3.3.3/32",
    "4.4.4.4/32",
  ]
  
}

variable "frontend_ports" {

  type = list(number)
  default = [80,443]
  }

variable "backend_ports" {

  type = list(number)
  default = [80,443,8080]
  }

variable "frontend_public_ssh" {
  
  default = true
}

variable "backend_public_ssh" {
  
  default = true
}

variable "database_port" {

 default = 3306  
}

variable "bastion_ssh_port" {
  
  default = 22
}

variable "frontend_ssh_port" {
  
  default = 22
}

variable "backend_ssh_port" {
  
  default = 22
}

locals  {
  
  db_domain = aws_route53_record.db.name
  
}



locals {
  common_tags = {
    project     = var.project
    environment = var.environment
    owner       = var.owner
    application = var.application
  }
}



locals {
  subnets = length(data.aws_availability_zones.available_azs.names)
}