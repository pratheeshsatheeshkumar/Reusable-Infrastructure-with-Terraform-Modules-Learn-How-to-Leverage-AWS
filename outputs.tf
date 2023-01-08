
output "bastion_access" {
  value = "ssh -i mykey ec2-user@${aws_instance.bastion.public_ip}"
}
output "frontend_access" {
  value = "ssh -i mykey ec2-user@${aws_instance.frontend.private_ip}"
}

output "backend_access" {
  value = "ssh -i mykey ec2-user@${aws_instance.backend.private_ip}"
} 

output "setup_frontend_sh" {
  value = data.template_file.setup_frontend.rendered
  }

output "setup_backend_sh" {
  value = data.template_file.setup_backend.rendered
  }

 output "wordpress_url" {
  value = "http://${aws_route53_record.wordpress.name}"
 }