# DevOps Infrastructure Project

This repository contains a complete DevOps infrastructure setup using Terraform, Ansible, Docker, and monitoring scripts. The project sets up AWS infrastructure, configures instances, deploys a containerized web application, and implements monitoring and backup solutions.

## Architecture Diagram

![AWS Architecture Diagram](Blank%20diagram.png)

This architecture diagram shows the serverless media streaming application designed to handle 200 users per hour with high availability and security standards.

Key components:
- CloudFront for global content delivery
- S3 for media storage
- Lambda for video processing
- API Gateway for RESTful endpoints
- DynamoDB for metadata storage
- Cognito for user authentication
- CloudWatch for monitoring

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform (>= 0.12)
- Ansible (>= 2.9)
- Docker and Docker Compose
- Git

## Project Structure

```
.
├── ansible/
│   ├── ec2.tf                  # EC2 instance configuration
│   ├── inventory.ini           # Auto-generated Ansible inventory
│   ├── playbook.yml           # Main Ansible playbook
│   └── scripts_setup.yml      # Scripts deployment playbook
├── docker/
│   ├── docker-compose.yml     # Docker compose configuration
│   ├── Dockerfile            # Web application Dockerfile
│   └── src/                  # Web application source
├── scripts/
│   ├── monitor.sh           # System monitoring script
│   └── mysql_backup.sh      # Database backup script
└── terraform/
    ├── main.tf              # Main AWS infrastructure
    ├── versions.tf          # Provider versions
    └── lambda/              # Lambda functions
```

## Step-by-Step Setup Guide

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd devops_assignment

# Install required Terraform providers
cd terraform
terraform init
```

### 2. AWS Infrastructure Setup

```bash
# In the terraform directory
cd terraform

# Review the infrastructure plan
terraform plan

# Apply the infrastructure
terraform apply -auto-approve

# Note the outputs for future use
```

### 3. EC2 Instance Setup

```bash
# Navigate to ansible directory
cd ../ansible

# Initialize Terraform for EC2
terraform init

# Create EC2 instance and generate inventory
terraform apply -auto-approve

# Wait for instance to be fully running (usually 1-2 minutes)
```

### 4. Ansible Configuration

```bash
# Verify the inventory file has been created
cat inventory.ini

# Run the main playbook
ansible-playbook -i inventory.ini playbook.yml

# Deploy monitoring and backup scripts
ansible-playbook -i inventory.ini scripts_setup.yml
```

### 5. Testing Scripts

```bash
# SSH into the EC2 instance
ssh -i my-instance-key.pem ubuntu@<ec2-instance-ip>

# Test monitoring script
./monitor.sh

# Test backup script
./mysql_backup.sh
```

### 6. Docker Setup and Deployment

```bash
# Navigate to docker directory
cd ../docker

# Build the Docker image
docker build -t webapp .

# Start the application stack
docker-compose up -d

# Verify the containers are running
docker-compose ps
```

### 7. Accessing the Application

- Web Application: http://localhost:80

## Infrastructure Details

### AWS Resources Created

- VPC with public and private subnets
- EC2 instances for application hosting
- S3 bucket for backups
- Lambda functions for video processing
- CloudFront distribution (if configured)

### Security

- All sensitive information is stored in AWS Secrets Manager
- Security groups limit access to required ports only
- Private subnets used for database instances
- Regular automated backups configured

### Monitoring and Maintenance

The `monitor.sh` script provides:
- CPU usage monitoring
- Memory utilization
- Disk space monitoring
- Process monitoring
- Network statistics

The `mysql_backup.sh` script:
- Creates daily database backups
- Rotates old backups
- Uploads to S3 for safekeeping

## Docker Components

The application runs in containers with:
- Nginx web server
- Application container
- Database container (if required)

### Ports Used

- 80: Web Application
- 3000: Monitoring Dashboard (if configured)
- 3306: MySQL Database (internal only)

## Troubleshooting

### Common Issues

1. Terraform Apply Fails
   ```bash
   terraform destroy
   terraform apply -auto-approve
   ```

2. Ansible Connection Issues
   - Verify security group allows SSH access
   - Check the instance is fully initialized
   - Verify the key permissions (chmod 400)

3. Docker Issues
   ```bash
   # Restart the containers
   docker-compose down
   docker-compose up -d

   # Check container logs
   docker-compose logs
   ```

## Cleanup

To destroy all created resources:

```bash
# Destroy Docker resources
cd docker
docker-compose down

# Destroy EC2 instance
cd ../ansible
terraform destroy -auto-approve

# Destroy AWS infrastructure
cd ../terraform
terraform destroy -auto-approve
```
