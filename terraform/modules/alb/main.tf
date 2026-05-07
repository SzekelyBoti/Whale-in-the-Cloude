resource "aws_security_group" "alb" {
  name   = "${var.project}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = var.alb_protocol
    cidr_blocks = var.allowed_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "${var.project}-alb-sg" })
}

resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  tags               = merge(var.common_tags, { Name = "${var.project}-alb" })
}

resource "aws_lb_target_group" "servers" {
  name     = "${var.project}-tg"
  port     = var.alb_port
  protocol = var.alb_protocol
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
  }
  tags = merge(var.common_tags, { Name = "${var.project}-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port
  protocol          = var.alb_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.servers.arn
  }
}