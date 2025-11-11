#!/bin/bash
set -e

# --- Docker Engine Setup ---
apt update -y
apt install -y ca-certificates curl gnupg git 

# Get Distribution Codename
DIST_CODENAME=$(lsb_release -cs)

# Add Docker's official GPG key and repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $${DIST_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose Plugin
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and Start Docker Service
systemctl start docker
systemctl enable docker

# --- 2. Clone Repository (Using Terraform Variables) ---
mkdir -p /home/ubuntu/
cd /home/ubuntu/staging/
# Variables are now injected by Terraform's templatefile()
git clone --branch ${repo_branch} ${repo_url} n8n_repo
cd n8n_repo/staging

# --- 3. Create .env File and Volumes ---

# Create the .env file 
cat > .env <<EOC
DATA_FOLDER=${data_folder}
SUBDOMAIN=${subdomain}
DOMAIN_NAME=${domain_name}
GENERIC_TIMEZONE=${timezone}
EOC

# Create the required configuration folders and volumes based on DATA_FOLDER
mkdir -p ${data_folder}/caddy_config
mkdir -p ${data_folder}/local_files
cp Caddyfile ${data_folder}/caddy_config/Caddyfile

# create docker network
docker network create ${docker_network}

# Docker volumes are external in the docker-compose file, so they must be created first
docker volume create caddy_data
docker volume create n8n_data

# --- 4. Start n8n using Docker Compose ---
usermod -aG docker ubuntu
docker compose up -d