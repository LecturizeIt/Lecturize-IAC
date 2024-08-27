terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "lecturizeit_terraform" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = "lt-0873b8eb16bd5f7b9"
    version = "$Latest"
  }
}

resource "aws_lb" "lecturizeit_terraform" {
  name               = "lecturizeit-alb-terraform"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lecturizeit_alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "lecturizeit" {
  load_balancer_arn = aws_lb.lecturizeit_terraform.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lecturizeit.arn
  }
}

resource "aws_lb_target_group" "lecturizeit" {
  name     = "lecturizeit-tg-terraform"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_autoscaling_attachment" "lecturizeit" {
  autoscaling_group_name = aws_autoscaling_group.lecturizeit_terraform.id
  lb_target_group_arn    = aws_lb_target_group.lecturizeit.arn
}

resource "aws_security_group" "lecturizeit_alb" {
  name = "lecturizeit-alb-sg-terraform"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = data.aws_vpc.default.id
}