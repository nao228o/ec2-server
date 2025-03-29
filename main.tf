terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-northeast-1"
}

resource "aws_instance" "app_server" {
  ami                         = "ami-0599b6e53ca798bb2"
  instance_type               = "t2.micro"
  key_name                    = "staging-key"
  user_data                   = file("user-data.sh")
  subnet_id                   = aws_subnet.staging_subnet.id
  vpc_security_group_ids      = [aws_security_group.staging_sg.id]
  
  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "staging-ec2"
  }
}

resource "aws_subnet" "staging_subnet" {
  vpc_id                  = aws_vpc.staging_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "staging-subnet"
  }
}

resource "aws_vpc" "staging_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "staging-vpc"
  }
}

resource "aws_vpc_dhcp_options" "dns_resolver" {
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers        = ["169.254.169.123"]
  netbios_name_servers = ["169.254.169.123"]
  netbios_node_type = 2

  tags = {
    Name = "staging-dhcp-options"
  }
}

# VPCのDNS設定を有効化
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.staging_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dns_resolver.id
}

resource "aws_security_group" "staging_sg" {
  name        = "staging-sg"
  description = "Security group for staging environment"
  vpc_id      = aws_vpc.staging_vpc.id

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "staging-sg"
  }
}


output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

