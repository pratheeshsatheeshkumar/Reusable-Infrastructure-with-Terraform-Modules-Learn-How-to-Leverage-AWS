/*==== Gatthering of availability zones in the present region from datasource ======*/

data "aws_availability_zones" "available_azs" {
  state = "available"
}
data "aws_route53_zone" "selected" {
  name         = "${var.public_domain}."
  private_zone = false
}


data "template_file" "setup_frontend" {
    template = file("${path.module}/setup_frontend.sh")
    vars = {
         DB_NAME = var.db_name
         DB_USER = var.db_user
         DB_PASSWD = var.db_passwd 
         DB_DOMAIN = local.db_domain
    }
}
data "template_file" "setup_backend" {
    template = file("${path.module}/setup_backend.sh")
    vars = {
         DB_NAME = var.db_name
         DB_USER = var.db_user
         DB_PASSWD = var.db_passwd 
    }
}
