# --- Locals and AMI Data Source ---
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
  # Ingress rules (Fixed nesting issue)
  ingress {
    description = "Allow SSH from corp lan"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/22"] 
  }
  ingress { 
    description = "Allow SSH from Jade's lan"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["67.199.173.110/32"]
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

# --- EC2 Instance Creation ---
resource "aws_instance" "n8n_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type 
  key_name      = var.key_name 
  subnet_id     = var.subnet_id 
  
  # User data script execution
  user_data = templatefile("${path.module}/scripts/installdocker.sh", {
    repo_branch    = local.repo_branch
    repo_url       = local.repo_url
    data_folder    = local.data_folder
    subdomain      = local.subdomain
    domain_name    = local.domain_name
    timezone       = local.timezone
    docker_network = local.docker_network
  })

  vpc_security_group_ids = [aws_security_group.n8n_sg.id]

  tags = {
    Name = "${local.subdomain}-${local.domain_name}-Server"
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
  value       = "ssh -i ${var.key_name} ubuntu@${aws_eip.n8n_eip.public_ip}"
}

output "boostn8n_access_key_id" {
  description = "Access Key ID for the boostn8n IAM user."
  value       = aws_iam_access_key.boostn8n_key.id
  sensitive   = true
}

output "boostn8n_secret_access_key" {
  description = "Secret Access Key for the boostn8n IAM user. SAVE THIS NOW!"
  value       = aws_iam_access_key.boostn8n_key.secret
  sensitive   = true
}