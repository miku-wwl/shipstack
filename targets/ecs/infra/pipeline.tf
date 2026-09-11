resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name_prefix}-artifacts"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_codebuild_project" "this" {
  name          = local.codebuild_name
  description   = "Shipstack ECS target build and image publication"
  service_role  = aws_iam_role.codebuild.arn
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
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = local.ecr_repository_uri
    }

    environment_variable {
      name  = "ECS_CONTAINER_NAME"
      value = "ecs-platform-demo"
    }

    environment_variable {
      name  = "AWS_ENDPOINT_URL"
      value = var.codebuild_aws_endpoint == null ? "" : var.codebuild_aws_endpoint
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build"
      status      = "ENABLED"
    }
  }
}

resource "aws_codepipeline" "this" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "LocalSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        S3Bucket             = aws_s3_bucket.artifacts.id
        S3ObjectKey          = var.source_object_key
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAndPush"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["BuildOutput"]
      configuration = {
        ClusterName = aws_ecs_cluster.this.name
        ServiceName = aws_ecs_service.this.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  depends_on = [aws_iam_role_policy.codepipeline]
}
