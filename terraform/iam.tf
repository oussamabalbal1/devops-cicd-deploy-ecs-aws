# -----------------------------------------------------------------------------
# IAM ROLES AND POLICIES
# -----------------------------------------------------------------------------

# --- Role for ECS Task Execution (pulling images, logging) ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Policy to allow the ECS Task Execution Role to read the specific secret ---
resource "aws_iam_policy" "ecs_secrets_manager_access" {
  name        = "${var.project_name}-ecs-secrets-manager-access"
  description = "Allows ECS tasks to access the DB secret from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.db_host.arn
        ]
      }
    ]
  })
}

# --- Attach the new policy to the ECS Task Execution Role ---
resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets_manager_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_manager_access.arn
}


# --- This role is for your application code to interact with other AWS services. ---
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# --- Role for CodePipeline ---
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${var.project_name}-codepipeline-policy"
  description = "Policy for CodePipeline to build and deploy to ECS"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        "Resource" : aws_codebuild_project.main.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ],
        "Resource" : aws_ecs_service.main.id
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : aws_iam_role.ecs_task_execution_role.arn,
        "Condition" : {
          "StringEqualsIfExists" : {
            "iam:PassedToService" : "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# --- Attach AdministratorAccess to CodePipeline Role ---
resource "aws_iam_role_policy_attachment" "codepipeline_admin_access" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- Role for CodeBuild ---
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.project_name}-codebuild-policy"
  description = "Policy for CodeBuild"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion"
        ],
        Resource = "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}
