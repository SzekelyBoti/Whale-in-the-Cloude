resource "aws_security_group" "ec2" {
  name   = "${var.project}-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }
  ingress {
    description = "SSH from within VPC only"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project}-ec2-sg" })
}

locals {
  ecr_base = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

locals {
  nginx_conf_b64 = base64encode(file("${path.module}/templates/nginx.conf"))

  compose_b64 = base64encode(templatefile("${path.module}/templates/docker-compose.tpl", {
    ecr_base    = local.ecr_base
    project     = var.project
    db_host     = var.db_host
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
  }))

  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=== Starting user_data ==="
    echo "Account: ${var.account_id}"
    echo "Region:  ${var.region}"
    echo "ECR:     ${local.ecr_base}"

    # Wait for NAT Gateway + network
    echo "Waiting for network..."
    until curl -s --max-time 5 https://amazon.com > /dev/null 2>&1; do
      echo "Network not ready, retrying in 10s..."
      sleep 10
    done
    echo "Network is ready"

    # Install Docker
    yum update -y
    yum install -y docker
    systemctl enable docker
    systemctl start docker

    # Install docker-compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Write nginx.conf from base64 (no heredoc, no BOM, no formatting issues)
    echo "${local.nginx_conf_b64}" | base64 -d > /home/ec2-user/nginx.conf

    # Write docker-compose.yml from base64
    echo "${local.compose_b64}" | base64 -d > /home/ec2-user/docker-compose.yml

    # Login to ECR with retry
    echo "Logging in to ECR..."
    until aws ecr get-login-password --region ${var.region} | \
      docker login --username AWS --password-stdin ${local.ecr_base}; do
      echo "ECR login failed, retrying in 10s..."
      sleep 10
    done
    echo "ECR login succeeded"

    # Pull images with retry
    echo "Pulling images..."
    cd /home/ec2-user
    until /usr/local/bin/docker-compose pull; do
      echo "Pull failed, retrying in 15s..."
      sleep 15
    done
    echo "Images pulled"

    # Start containers
    /usr/local/bin/docker-compose up -d
    echo "=== user_data complete ==="
  EOF
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "servers" {
  count                  = length(var.private_subnet_ids)
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = var.instance_profile
  key_name               = var.key_pair_name
  user_data              = local.user_data
  tags = merge(var.common_tags, {
    Name = "${var.project}-server-${count.index + 1}"
  })
}

resource "aws_lb_target_group_attachment" "servers" {
  count            = length(aws_instance.servers)
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.servers[count.index].id
  port             = 80
}