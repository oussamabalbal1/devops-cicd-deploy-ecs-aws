# -----------------------------------------------------------------------------
# ECR REPOSITORY
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-repo"
  }
}


