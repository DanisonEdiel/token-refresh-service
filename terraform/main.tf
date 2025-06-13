provider "aws" {
  region = var.aws_region
}

# VPC para los servicios
resource "aws_vpc" "auth_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "auth-services-vpc"
  }
}

# Subredes públicas
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.auth_vpc.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "auth-public-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.auth_vpc.id

  tags = {
    Name = "auth-igw"
  }
}

# Tabla de rutas para subredes públicas
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.auth_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "auth-public-rt"
  }
}

# Asociación de tabla de rutas a subredes públicas
resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Grupo de seguridad para el servicio de refresh de tokens
resource "aws_security_group" "token_refresh_sg" {
  name        = "token-refresh-sg"
  description = "Security group for token refresh service"
  vpc_id      = aws_vpc.auth_vpc.id

  # Permitir tráfico HTTP desde cualquier lugar
  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir SSH desde direcciones IP específicas
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "token-refresh-sg"
  }
}

# EC2 para el servicio de refresh de tokens
resource "aws_instance" "token_refresh_service" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = [aws_security_group.token_refresh_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
              EOF

  tags = {
    Name = "token-refresh-service"
  }
}

# Elastic IP para el servicio de refresh de tokens
resource "aws_eip" "token_refresh_eip" {
  instance = aws_instance.token_refresh_service.id
  domain   = "vpc"

  tags = {
    Name = "token-refresh-eip"
  }
}

# API Gateway para exponer los servicios
resource "aws_api_gateway_rest_api" "auth_api" {
  name        = "auth-api"
  description = "API Gateway for authentication services"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Recurso para el servicio de refresh de tokens
resource "aws_api_gateway_resource" "token_refresh_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
  path_part   = "auth"
}

# Recurso para el endpoint de refresh
resource "aws_api_gateway_resource" "refresh_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_resource.token_refresh_resource.id
  path_part   = "refresh"
}

# Método POST para el endpoint de refresh
resource "aws_api_gateway_method" "refresh_post" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.refresh_resource.id
  http_method   = "POST"
  authorization_type = "NONE"
}

# Integración con el servicio de refresh de tokens
resource "aws_api_gateway_integration" "refresh_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.refresh_resource.id
  http_method = aws_api_gateway_method.refresh_post.http_method
  
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_eip.token_refresh_eip.public_ip}:8001/auth/refresh"
  
  connection_type = "INTERNET"
}

# Despliegue de la API
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.refresh_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  stage_name  = var.api_stage_name
}

# Salida del endpoint de la API
output "api_endpoint" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/${aws_api_gateway_resource.token_refresh_resource.path_part}/${aws_api_gateway_resource.refresh_resource.path_part}"
}

output "token_refresh_service_ip" {
  value = aws_eip.token_refresh_eip.public_ip
}
