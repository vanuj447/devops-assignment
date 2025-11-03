# Required providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# EC2 Instance Configuration
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
  default_for_az    = true
}

# Create a key pair
resource "tls_private_key" "instance_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate random suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create AWS key pair
resource "aws_key_pair" "instance_key_pair" {
  key_name   = "my-instance-key-${random_string.suffix.result}"
  public_key = tls_private_key.instance_key.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.instance_key.private_key_pem
  filename = "${path.module}/my-instance-key.pem"
  file_permission = "0600"
}

# Security group
resource "aws_security_group" "instance_sg" {
  name        = "instance-security-group-${random_string.suffix.result}"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-security-group"
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t2.micro"
  key_name      = aws_key_pair.instance_key_pair.key_name
  subnet_id     = data.aws_subnet.default.id

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name = "web-server"
  }
}

# Output values
output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
  description = "Public IP of the EC2 instance"
}

output "instance_public_dns" {
  value = aws_instance.web_server.public_dns
  description = "Public DNS of the EC2 instance"
}

output "ssh_connection_string" {
  value = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.web_server.public_dns}"
  description = "SSH connection string to connect to the instance"
}

# Create Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = <<-EOF
[webserver]
${aws_instance.web_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${path.module}/my-instance-key.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

  filename = "${path.module}/../ansible/inventory.ini"
  depends_on = [aws_instance.web_server, local_file.private_key]
}

# Create Ansible config file
resource "local_file" "ansible_config" {
  content = <<-EOF
[defaults]
inventory = inventory.ini
remote_user = ubuntu
host_key_checking = False
EOF

  filename = "${path.module}/../ansible/ansible.cfg"
  depends_on = [local_file.ansible_inventory]
}

# Ensure correct key permissions
resource "null_resource" "fix_key_permissions" {
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key.filename}"
  }

  depends_on = [local_file.private_key]
}