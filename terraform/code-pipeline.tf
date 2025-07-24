resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.project_name}-codepipeline-bucket-${random_id.id.hex}"

  tags = {
    Name = "${var.project_name}-codepipeline-bucket"
  }
}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_codepipeline_webhook" "main" {
  name            = "${var.project_name}-webhook"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source" # Must match the name of your source action
  target_pipeline = aws_codepipeline.main.name

  authentication_configuration {
    secret_token = var.github_token # Use the same PAT or a different secret
  }

  filter {
    json_path = "$.ref"
    match_equals = "refs/heads/{Branch}" # {Branch} is a variable resolved by CodePipeline
  }
}

resource "github_repository_webhook" "main" {
  repository = var.github_repo

  configuration {
    url          = aws_codepipeline_webhook.main.url
    content_type = "json"
    insecure_ssl = false
    secret       = var.github_token
  }

  # Trigger on push events
  events = ["push"]
}


resource "aws_codepipeline" "main" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      # --- FIX: Reverted provider to 'GitHub' (Version 1) ---
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      
      # --- FIX: Reverted configuration to use the GitHub PAT ---
      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = var.github_branch
        OAuthToken           = var.github_token
        PollForSourceChanges = false # Important: Rely on the webhook for triggers
      }
    }
  }
  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.main.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_codebuild_project" "main" {
  name          = "${var.project_name}-build"
  description   = "Build project for the NestJS application"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.main.name
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "${var.project_name}-container"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml" # Ensure this file exists in your repo
  }

  tags = {
    Name = "${var.project_name}-build"
  }
}