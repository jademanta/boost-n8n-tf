terraform {
  backend "s3" {
    bucket = "boost.cloudformation"
    key    = "Terraform_state_files/staging/n8n.tfstate"
    region = "us-west-2" # Use your deployment region
    encrypt = false
  }

  # 2. Required Providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}