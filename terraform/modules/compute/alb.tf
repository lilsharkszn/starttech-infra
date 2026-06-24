resource "aws_lb" "backend" {
  name = "${var.environment}-backend-alb"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    var.alb_security_group_id
  ]

  subnets = var.public_subnet_ids

  tags = {
    Name = "${var.environment}-backend-alb"
  }
}

resource "aws_lb_target_group" "backend" {
  name = "${var.environment}-backend-tg"

  port = 8080

  protocol = "HTTP"

  target_type = "instance"

  vpc_id = var.vpc_id

  health_check {
    path = "/health"

    protocol = "HTTP"

    matcher = "200"

    interval = 30

    healthy_threshold = 2

    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend.arn

  port = 80

  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.backend.arn
  }
}

