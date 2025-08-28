terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {}
variable "instance_name" {}
variable "instance_type" {}

provider "aws" {
  region = var.aws_region
}

# Generar par de llaves SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Guardar la llave privada localmente
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.instance_name}.pem"
  file_permission = "0400"
}

# Crear key pair en AWS
resource "aws_key_pair" "generated_key" {
  key_name   = "${var.instance_name}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Security group abierto (ajustar según necesidad)
resource "aws_security_group" "open_all" {
  name        = "${var.instance_name}-sg"
  description = "Open all ports"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instancia EC2 Ubuntu
resource "aws_instance" "ec2" {
  ami                         = "ami-08c40ec9ead489470" # Ubuntu 22.04 us-east-1
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  security_groups             = [aws_security_group.open_all.name]
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}

output "instance_ip" {
  value = aws_instance.ec2.public_ip
}

output "private_key_path" {
  value = local_file.private_key.filename
}
