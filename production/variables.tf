variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}
variable "instance_type" {
  description = "The type of instance to use for the EC2 instance"
  type        = string
  default     = "t3.medium"
}
variable "key_name" {
  description = "The name of the my personal SSH key pair to use for the EC2 instance"
  type        = string
  default     = "n8n_boost"
}
variable "vpc_id" {
  description = "The VPC ID where the EC2 instance will be deployed"
  type        = string
  default     = "vpc-b2a82cd7" #(Cloudformation - boostprod-vpc)
}
variable "subnet_id" {
  description = "The Subnet ID within the VPC where the EC2 instance will be deployed"
  type        = string
  default     = "subnet-43ac3026" #(a public subnet in Boostprod us-west-2a)
}
