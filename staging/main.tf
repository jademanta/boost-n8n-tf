locals {
  repo_url       = "https://github.com/jademanta/boost-n8n-tf.git" # <-- CHANGE THIS
  repo_branch    = "main"
  data_folder    = "/mnt/n9n_data" 
  domain_name    = "boocorp.com"
  subdomain      = "n8n"
  timezone       = "America/Denver"
  docker_network = "n8n_network"
}

data "aws_ami" "ubuntu" {

 most_recent = true

 filter {

   name   = "name"
   values = ["ubuntu/images/hvm-ssd/ubuntu-**jammy-22.04**-amd64-server-*"]
 }

 filter {

   name   = "virtualization-type"
   values = ["hvm"]
 }

 filter {
   name   = "architecture"
   values = ["x86_64"]
 }
 owners = ["099720109477"] #canonical
}



resource "aws_security_group" "n8n_sg" {
  name        = "n8n-caddy-access-sg"
  description = "Allow HTTP, HTTPS, and SSH traffic"
  vpc_id      = var.vpc_id # Assume you have a variable for your VPC ID

  # Ingress rules (MUST NOT be nested)
  
  ingress {
    description = "Allow SSH from corp lan"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/22"] 
  }

  ingress { # <-- This block was nested incorrectly
    description = "Allow SSH from Jade home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.199.173.110/32"]
  }

  ingress { # <-- This block was nested incorrectly
    description = "Allow HTTP for Caddy/n8n access (used for certificate challenge)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS for Caddy/n8n access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule (Allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Represents all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "n8n-Caddy-SG"
  }
}