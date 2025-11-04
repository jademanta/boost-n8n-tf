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
  default     = "/home/jade/.ssh/id_ed25519"
}
variable "vpc_id" {
  description = "The VPC ID where the EC2 instance will be deployed"
  type        = string
  default     = "vvpc-18b6427c" #(staging vpc)
}
variable "subnet_id" {
  description = "The Subnet ID within the VPC where the EC2 instance will be deployed"
  type        = string
  default     = "subnet-08e4d38ed26372b49" #(a public subnet in Boost-stage us-west-2b)
}
