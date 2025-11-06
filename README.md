Based on https://github.com/n8n-io/n8n-docker-caddy

# 🚀 n8n.io on AWS EC2 with Docker and Terraform

This repository provisions an **n8n.io** workflow automation server on **AWS EC2** using Docker, Docker Compose, and Caddy as a reverse proxy. Caddy automatically handles TLS/SSL certificate generation for a secure **HTTPS** connection.

---

## 🛑 Prerequisites

Before deploying, ensure you have the following installed and configured:

1. **Terraform:** Must be installed locally.
    
2. **AWS CLI:** Must be installed and configured.
    
3. **AWS Key Pair:** A **pre-existing SSH Key Pair** must be uploaded to or created within your target AWS region. The key name must be referenced in `variables.tf`, as EC2 requires keys before launch.
    
4. **AWS Profile:** An AWS CLI profile configured with credentials that have permission to create EC2, VPC, EIP, Launch Template, and IAM resources.
    

---

## ⚙️ Configuration and Setup

This repository is designed for easy environment configuration. You must update specific files to match your AWS account and domain details.

### 1. Configure AWS Profile

Set your deployment profile as the default for your terminal session:

export AWS_PROFILE=YOURAWSCLIPROFILE

### 2. Update Configuration Files

- **`main.tf`:** Verify the `locals` block contains the correct GitHub repository URL, Docker network name, and domain details.
    
- **`variables.tf`:** Update the default values for `vpc_id`, `subnet_id`, and the name of your **existing AWS SSH Key Pair** (`key_name`).
    

---

## 🚀 Deployment Instructions

Follow these steps to deploy the n8n server to AWS. The provisioning (installing Docker, cloning the repo, and running Docker Compose) is handled non-interactively by the **Launch Template's User Data** script upon instance launch.

### Step 1: Initialize Terraform

Navigate to your target environment folder (e.g., `staging`) and initialize Terraform:

cd staging 
terraform init

### Step 2: Review and Save the Plan

Create an execution plan and save it to a file (`tfplan`). This ensures consistency and safety during the apply step.

	terraform plan -out tfplan

### Step 3: Apply the Plan

Apply the saved plan to begin provisioning. Terraform will create the Launch Template, the EC2 instance (which runs the `installdocker.sh` script immediately), and associate the static Elastic IP.

	terraform apply tfplan

## ⚠️ Post-Deployment Actions (CRITICAL)

The deployment is not complete until you have performed the following **mandatory networking step**:

### DNS Setup (MANDATORY)

Since the Caddy server is configured to handle HTTPS for a specific domain, you **MUST** point your DNS records:

1. Get the static IP address from the Terraform output.

		terraform output n8n_elastic_ip
		
2.   In your domain registrar or AWS Route 53, create an **A Record** pointing your full subdomain (e.g., `n8nstaged.boocorp.com`) to the Elastic IP address you just retrieved.
    

**The n8n application will NOT be accessible by the IP address alone, and Caddy will NOT issue a TLS certificate until the DNS record is correctly pointed to the EC2 instance.** Trying to access the service by IP alone will not work.

## Access and Management

- **n8n URL:** Access your n8n workflow interface via the HTTPS URL defined in your configuration (e.g., `https://n8nstaged.boocorp.com/`).
    
	- **SSH Access:** Use the command provided in the Terraform output to manage the server. You will need the private key associated with the AWS Key Pair referenced in variables.tf.
		
			terraform output ssh_connect_command

## Cleanup

To tear down all deployed AWS resources (EC2, EIP, Security Groups, Launch Template, etc.), run the destroy command:

		terraform destroy
