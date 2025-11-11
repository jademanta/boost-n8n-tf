locals {
  repo_url       = "https://github.com/jademanta/boost-n8n-tf.git"
  repo_branch    = "main"
  data_folder    = "/home/ubuntu/n8n_data"
  domain_name    = "boocorp.com"
  subdomain      = "n8n"
  timezone       = "America/Denver"
  docker_network = "n8n_network"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from corp lan"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/22"]
  }
  ingress {
    description = "Allow SSH from Jade home lan"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.199.173.110/32"]
  }
  ingress {
    description = "Allow SSH from ssl vpn"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["205.197.213.195/32"]
  }
  ingress {
    description = "Allow HTTP for Caddy/n8n access"
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
  # Egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "n8n-Caddy-SG"
  }
}

resource "aws_instance" "n8n_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  launch_template {
    id      = aws_launch_template.n8n_lt.id
    version = "$Latest"
  }

  tags = {
    Name = "${local.subdomain}-${local.domain_name}-Server"
    Stack = "Production"
  }
}

# --- Data Source to render and encode the script ---
data "template_file" "n8n_docker_setup" {
  template = file("${path.module}/scripts/installdocker.sh")
  vars = {
    repo_branch    = local.repo_branch
    repo_url       = local.repo_url
    data_folder    = local.data_folder
    subdomain      = local.subdomain
    domain_name    = local.domain_name
    timezone       = local.timezone
    docker_network = local.docker_network
  }
}

resource "aws_launch_template" "n8n_lt" {
  name_prefix   = "n8n-launch-template"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  # VPC and Security Group Configuration
  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    security_groups             = [aws_security_group.n8n_sg.id]
    subnet_id                   = var.subnet_id
  }

  # Root Volume Configuration
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # Pass the encoded user data
  user_data = base64encode(data.template_file.n8n_docker_setup.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.subdomain}-${local.domain_name}-Server-LT"
    }
  }
}
# --- Elastic IP Allocation and Association ---
resource "aws_eip" "n8n_eip" {
  tags = {
    Name = "n8n-static-IP"
  }
}

resource "aws_eip_association" "n8n_eip_assoc" {
  instance_id   = aws_instance.n8n_server.id
  allocation_id = aws_eip.n8n_eip.id
}

output "n8n_elastic_ip" {
  description = "The static IP address for the n8n server."
  value       = aws_eip.n8n_eip.public_ip
}

output "ssh_connect_command" {
  description = "SSH command to connect to the n8n server."
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.n8n_eip.public_ip}"
}
