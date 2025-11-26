terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls" # This is common when you need to create an EC2 instance and also generate an SSH key pair dynamically instead of manually uploading one.
    }
    local = {
      source = "hashicorp/local" # This is useful when you want to save the generated SSH key locally for later use.
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "tls_private_key" "infra_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.infra_private_key.private_key_pem
  filename        = "${path.module}/jenkins-agent.pem"
  file_permission = "0600"
}

# Key-Pair
resource "aws_key_pair" "infra_key_pair" {
  key_name   = "jenkins_agent_key"
  public_key = tls_private_key.infra_private_key.public_key_openssh
}

# Security Group
resource "aws_security_group" "infra_sg" {
  name = "jenkins-agent-sg"

  # inbound rules
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  # outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-agent-sg"
  }
}

# To get the latest Ubuntu image ID dynnamically instead of hard-coding so we can use it in our EC2 instance
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# EC2 Instance
resource "aws_instance" "my-infra" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  key_name          = aws_key_pair.infra_key_pair.key_name
  availability_zone = var.availability_zone
  security_groups   = [aws_security_group.infra_sg.name]

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # User data: Create jenkins_agent directory and add Jenkins Master public key inside it
  user_data = base64encode(<<-EOF
    #!/bin/bash
    mkdir -p /home/ubuntu/jenkins_agent/.ssh
    
    # Add Jenkins Master public key (allows master to SSH into agent)
    echo "${var.jenkins_master_pubkey}" >> /home/ubuntu/id_rsa.pub

    cp /home/ubuntu/id_rsa.pub /home/ubuntu/jenkins_agent/.ssh/authorized_keys
    
    chmod 700 /home/ubuntu/jenkins_agent/.ssh
    chmod 600 /home/ubuntu/jenkins_agent/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/jenkins_agent
  EOF
  )
  tags = {
    Name = "jenkins-agent"
  }
  depends_on = [aws_key_pair.infra_key_pair, aws_security_group.infra_sg]
}