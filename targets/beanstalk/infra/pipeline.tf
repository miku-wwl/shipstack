resource "aws_codebuild_project" "this" {
  name          = local.codebuild_name
  description   = "Shipstack Elastic Beanstalk bundle build and API deployment"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30

  source {
    type      = "CODEPIPELINE"
    buildspec = "targets/beanstalk/buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ENDPOINT_URL"
      value = var.codebuild_aws_endpoint
    }

    environment_variable {
      name  = "EB_APPLICATION_NAME"
      value = aws_elastic_beanstalk_application.this.name
    }

    environment_variable {
      name  = "EB_ENVIRONMENT_NAME"
      value = local.eb_environment_name
    }

    environment_variable {
      name  = "EB_RELEASE_BUCKET"
      value = aws_s3_bucket.artifacts.id
    }

    environment_variable {
      name  = "EB_SOLUTION_STACK_NAME"
      value = var.solution_stack_name == null ? "" : var.solution_stack_name
    }

    environment_variable {
      name  = "EB_SERVICE_ROLE_NAME"
      value = aws_iam_role.beanstalk_service.name
    }

    environment_variable {
      name  = "EB_INSTANCE_PROFILE_NAME"
      value = aws_iam_instance_profile.beanstalk.name
    }

    environment_variable {
      name  = "EB_ENVIRONMENT_RELEASE_VALIDATION_MODE"
      value = var.environment_release_validation_mode
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
    name = "BuildDeploy"

    action {
      name             = "BuildPackageDeployValidate"
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

  depends_on = [aws_iam_role_policy.codepipeline]
}
