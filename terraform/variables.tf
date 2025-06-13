variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH into the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Reemplazar con IPs específicas en producción
}

variable "ec2_ami" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (actualizar según la región)
}

variable "ec2_instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 instances"
  type        = string
  default     = "auth-services-key"  # Reemplazar con el nombre de tu key pair
}

variable "api_stage_name" {
  description = "Stage name for the API Gateway deployment"
  type        = string
  default     = "v1"
}
