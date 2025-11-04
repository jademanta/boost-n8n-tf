#!/bin/bash
set -e

# --- 1. Official Docker Engine Setup ---
apt update -y
apt install -y ca-certificates curl gnupg git 

# Add Docker's official GPG key and repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo 'deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Docker Compose Plugin
apt update -y
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and Start Docker Service
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# --- 2. Clone Repository ---
mkdir -p /home/ubuntu/
cd /home/ubuntu/
git clone --branch ${repo_branch} ${repo_url} n8n_repo

cd n8n_repo

# --- 3. Create .env File and Volumes ---

# Create the .env file using values passed by Terraform
cat > .env <<EOC
DATA_FOLDER=${data_folder}
SUBDOMAIN=${subdomain}
DOMAIN_NAME=${domain_name}
GENERIC_TIMEZONE=${timezone}
EOC

# Create the required configuration folders and volumes based on DATA_FOLDER
mkdir -p ${data_folder}/caddy_config
mkdir -p ${data_folder}/local_files

#Create the docker network
docker network create ${docker_network}

# The docker-compose file uses external volumes, so they must be created first
docker volume create caddy_data
docker volume create n8n_data

# --- 4. Start n8n using Docker Compose ---
docker compose up -d