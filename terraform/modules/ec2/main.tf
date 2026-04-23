locals {
  ecr_base = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    # Wait for network/NAT gateway to be ready
    echo "Waiting for network..."
    until curl -s --max-time 5 https://amazon.com > /dev/null 2>&1; do
      echo "Network not ready, retrying in 10s..."
      sleep 10
    done
    echo "Network is ready"

    yum update -y
    yum install -y docker
    systemctl enable docker
    systemctl start docker

    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    aws ecr get-login-password --region ${var.region} | \
      docker login --username AWS --password-stdin ${local.ecr_base}

    cat > /home/ec2-user/nginx.conf << 'NGINXCONF'
events {
  worker_connections 1024;
}

http {
  upstream app_servers {
    server app1:3000;
    server app2:3001;
  }

  server {
    listen 80;

    location / {
      proxy_pass http://app_servers;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }
}
NGINXCONF

    cat > /home/ec2-user/docker-compose.yml << 'COMPOSE'
services:
  nginx:
    image: ${local.ecr_base}/${var.project}-nginx:latest
    ports:
      - "80:80"
    volumes:
      - /home/ec2-user/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app1
      - app2
  app1:
    image: ${local.ecr_base}/${var.project}-app:latest
    environment:
      - PORT=3000
  app2:
    image: ${local.ecr_base}/${var.project}-app:latest
    environment:
      - PORT=3001
COMPOSE

    cd /home/ec2-user
    /usr/local/bin/docker-compose up -d
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
  vpc_security_group_ids = [var.ec2_sg_id]
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