resource "aws_autoscaling_group" "backend" {

  name = "${var.environment}-backend-asg"

  min_size = 2

  max_size = 4

  desired_capacity = 2

  vpc_zone_identifier = var.private_app_subnet_ids

  target_group_arns = [
    aws_lb_target_group.backend.arn
  ]

  launch_template {
    id = aws_launch_template.backend.id

    version = "$Latest"
  }

  health_check_type = "ELB"

  health_check_grace_period = 300
}

resource "aws_autoscaling_policy" "scale_out" {
  name = "scale-out"

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = 1

  autoscaling_group_name = aws_autoscaling_group.backend.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name = "scale-in"

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = -1

  autoscaling_group_name = aws_autoscaling_group.backend.name
}
