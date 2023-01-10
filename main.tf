module "vpc_module" {

    source = "github.com/pratheeshsatheeshkumar/vpc-module"
    
    project = var.project
    environment = var.environment
    cidr_vpc = var.cidr_vpc
    enable_nat_gateway = var.enable_nat_gateway
}

/*==== Security Group ======*/
/*Creation of security group for Bastion Server */

resource "aws_security_group" "bastion_sg" {
  name_prefix = "${var.project}-${var.environment}-"
  description = "Allow ssh from anywhere"
  vpc_id      = module.vpc_module.vpc_id


  ingress {
    from_port        = var.bastion_ssh_port
    to_port          = var.bastion_ssh_port
    protocol         = "tcp"
   # prefix_list_ids = [aws_ec2_managed_prefix_list.ip_pool_prefix_list.id]
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-bastion-sg"

  }
  lifecycle {
    create_before_destroy = true
  }
}

/*==== Security Group ======*/
/*Creation of security group for frontend Server with ssh access from bastion security group*/

resource "aws_security_group" "frontend_sg" {
  name_prefix = "${var.project}-${var.environment}-"
  description = "Allow http from anywhere and ssh from bastion-sg"
   vpc_id      = module.vpc_module.vpc_id


  dynamic "ingress" {
  
    for_each = toset(var.frontend_ports)
    iterator = port
    content {
    
      from_port        = port.value
      to_port          = port.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
   }
 }

ingress {
    from_port       = var.frontend_ssh_port
    to_port         = var.frontend_ssh_port
    protocol        = "tcp"
    cidr_blocks     = var.frontend_public_ssh == true ? ["0.0.0.0/0"] : null   
    security_groups = [aws_security_group.bastion_sg.id]
    
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-frontend-sg"

  }
  lifecycle {
    create_before_destroy = true
  }
}
/*==== Security Group ======*/
/*Creation of security group for backend Server */
resource "aws_security_group" "backend_sg" {
  name_prefix = "${var.project}-${var.environment}-"
  description = "Allow sql from frontend-sg and ssh from bastion-sg"
   vpc_id      = module.vpc_module.vpc_id


  ingress {
     
    from_port       = var.database_port
    to_port         = var.database_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    
    from_port       = var.backend_ssh_port
    to_port         = var.backend_ssh_port
    protocol        = "tcp"
    cidr_blocks     = var.backend_public_ssh == true ? ["0.0.0.0/0"] : null
    security_groups = [aws_security_group.bastion_sg.id]
    
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-backend-sg"

  }
  lifecycle {
    create_before_destroy = true
  }
  
}
/*==== Keypair ======*/
/*Creation of key pair for server access */

resource "aws_key_pair" "ssh_key" {

  key_name   = "${var.project}-${var.environment}"
  public_key = file("mykey.pub")
  tags = {
    Name = "${var.project}-${var.environment}"
  }
}


/*==== EC2 Instance Launch ======*/
/*Creation of EC2 instance for bastion server */
resource "aws_instance" "bastion" {

  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true
  subnet_id                   = module.vpc_module.public_subnets[1]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  user_data                   = file("setup_bastion.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project}-${var.environment}-bastion"
  }
}
/*====Local_file====*/
/*==== local_file resource creation to save template_file rendered data======*/
resource "local_file" "frontend_rendered" {
    content  = data.template_file.setup_frontend.rendered
    filename = "${path.module}/frontend_rendered.txt"
}

/*==== EC2 Instance Launch ======*/
/*Creation of EC2 instance for frontend server */
resource "aws_instance" "frontend" {

  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = true
  subnet_id                   = module.vpc_module.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  user_data                   = data.template_file.setup_frontend.rendered
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project}-${var.environment}-frontend"
  }
  
}

/*====Local_file====*/
/*==== local_file resource creation to save template_file rendered data======*/
resource "local_file" "backend_rendered" {
    content  = data.template_file.setup_backend.rendered
    filename = "${path.module}/backend_rendered.txt"
}


/*==== EC2 Instance Launch ======*/
/*Creation of EC2 instance for backend server */
resource "aws_instance" "backend" {

  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = false
  subnet_id                   = module.vpc_module.private_subnets[1]
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  user_data                   = data.template_file.setup_backend.rendered
  user_data_replace_on_change = true

  # To ensure proper ordering, it is recommended to add an explicit dependency
  depends_on = [module.vpc_module.nat_gw]
  

  tags = {
    Name = "${var.project}-${var.environment}-backend"
  }
}
/*==== Private Zone  ======*/
/*Creation of private zone for private domain */
resource "aws_route53_zone" "private" {
  name = var.private_domain

  vpc {
    vpc_id = module.vpc_module.vpc_id
  }
}

/*===== Private Zone : A record  ======*/
/*=====Creation of A record to backend private IP.=====*/
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "db.${var.private_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.backend.private_ip]
}

/*==== Public Zone : A record  ======*/
/*====Creation of A record to frontend public IP.====*/

resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.selected.id
  name    = "wordpress.${var.public_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.frontend.public_ip]
}

/*==== Prefix_list ======*/

resource "aws_ec2_managed_prefix_list" "ip_pool_prefix_list" {
  name           = "${var.project}-${var.environment}-ip_pool_prefix_list"
  address_family = "IPv4"
  max_entries    = length(var.ip_pool)
   
  dynamic "entry" {
    for_each = toset(var.ip_pool)
    iterator = ip
     content {
       cidr  = ip.value
     }
  }

  tags = {
   Name = "${var.project}-${var.environment}-ip_pool_prefix_list"
  }
}



