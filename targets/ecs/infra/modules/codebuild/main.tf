resource "aws_codebuild_project" "this" {
  name          = var.project_name
  description   = "Shipstack ECS target build and image publication"
  service_role  = var.service_role_arn
  build_timeout = 30

  source {
    type      = "CODEPIPELINE"
    buildspec = "targets/ecs/buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "ECR_REPOSITORY"
      value = var.ecr_repository
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_uri
      type  = "PLAINTEXT"
    }
    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.name_prefix}"
      stream_name = "build"
      status      = "ENABLED"
    }
  }
}
