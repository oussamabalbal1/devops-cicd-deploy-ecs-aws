resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/${var.project_name}"
  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}