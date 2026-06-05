resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-starttech-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"

        properties = {
          title   = "Backend CPU Utilization"
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.autoscaling_group_name
            ]
          ]
        }
      }
    ]
  })
}
