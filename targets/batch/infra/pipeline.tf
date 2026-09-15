resource "aws_codebuild_project" "this" {
  name          = local.codebuild_name
  description   = "Shipstack Batch target build, image publication, job submission and result validation"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30

  source {
    type      = "CODEPIPELINE"
    buildspec = "targets/batch/buildspec.yml"
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
      name  = "AWS_ENDPOINT_URL"
      value = var.codebuild_aws_endpoint
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = local.ecr_repository_uri
    }

    environment_variable {
      name  = "BATCH_JOB_QUEUE_NAME"
      value = aws_batch_job_queue.this.name
    }

    environment_variable {
      name  = "BATCH_JOB_DEFINITION_NAME"
      value = aws_batch_job_definition.this.name
    }

    environment_variable {
      name  = "BATCH_TASK_EXECUTION_ROLE_ARN"
      value = aws_iam_role.batch_task_execution.arn
    }

    environment_variable {
      name  = "BATCH_LOG_GROUP_NAME"
      value = aws_cloudwatch_log_group.batch.name
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
    name = "BuildSubmitValidate"

    action {
      name             = "BuildSubmitBatchJob"
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
