terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = var.region_name
}

# Security Group for WordPress CI/CD Server
resource "aws_security_group" "ecowordlylife-sg" {
  name        = "ecowordlylife-server-sg"
  description = "Security group for ecowordlylife WordPress CI/CD server"

  # Essential WordPress Ports
  ingress {
    description = "WordPress HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WordPress HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Management Ports
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Monitoring Ports
  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus Metrics"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # CI/CD Ports
  ingress {
    description = "Jenkins Dashboard"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube Analysis"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EKS Management Ports
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# WordPress CI/CD Server Instance
resource "aws_instance" "ecowordlylife-server" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = "ecowordlylife-key"  # Update with your key pair name
  vpc_security_group_ids = [aws_security_group.ecowordlylife-sg.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "ecowordlylife-ci-cd-server"
    Project = "WordPress Deployment"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      private_key = file("./ecowordlylife-key.pem")  # Update with your key path
      user        = "ubuntu"
      host        = self.public_ip
    }

    inline = [
      # Base System Setup
      "sudo apt update -y && sudo apt upgrade -y",
      
      # WordPress Dependencies
      "sudo apt install -y php php-mysql php-gd php-curl php-mbstring php-xml php-zip",
      "sudo apt install -y mariadb-client",
      
      # Containerization Tools
      "sudo apt install -y docker.io docker-compose",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ubuntu",
      
      # Monitoring Stack
      "sudo docker run -d --name prometheus -p 9090:9090 prom/prometheus",
      "sudo docker run -d --name grafana -p 3000:3000 grafana/grafana",
      
      # CI/CD Tools
      <<-EOT
      sudo docker run -d --name jenkins \
        -p 8080:8080 \
        -v jenkins_home:/var/jenkins_home \
        jenkins/jenkins:lts
      EOT,
      
      "sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:community",
      
      # Kubernetes Tools
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x kubectl && sudo mv kubectl /usr/local/bin/",
      
      # WordPress-Specific Configurations
      "echo 'export WORDPRESS_DB_HOST=ecowordlylife-db' >> ~/.bashrc",
      "echo 'export WORDPRESS_DB_USER=wpadmin' >> ~/.bashrc",
      
      # Final Output
      "echo 'ecowordlylife CI/CD Stack Deployment Complete'",
      "echo 'WordPress Admin URL: http://${self.public_ip}/wp-admin'",
      "echo 'Jenkins URL: http://${self.public_ip}:8080'",
      "echo 'Grafana Dashboard: http://${self.public_ip}:3000'"
    ]
  }
}

# Outputs
output "wordpress_admin_url" {
  value = "http://${aws_instance.ecowordlylife-server.public_ip}/wp-admin"
}

output "jenkins_url" {
  value = "http://${aws_instance.ecowordlylife-server.public_ip}:8080"
}

output "grafana_dashboard_url" {
  value = "http://${aws_instance.ecowordlylife-server.public_ip}:3000"
}

output "ssh_access" {
  value = "ssh -i ecowordlylife-key.pem ubuntu@${aws_instance.ecowordlylife-server.public_ip}"
}
