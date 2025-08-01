variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
}