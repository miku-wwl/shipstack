data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.name_prefix}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.name_prefix}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name_prefix}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${var.codebuild_log_group_arn}:*" },
      { Effect = "Allow", Action = ["s3:GetBucketLocation", "s3:GetBucketVersioning"], Resource = var.artifact_bucket_arn },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"], Resource = "${var.artifact_bucket_arn}/*" },
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      { Effect = "Allow", Action = ["ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart", "ecr:DescribeImages"], Resource = var.ecr_repository_arn },
      { Effect = "Allow", Action = ["sts:GetCallerIdentity"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:GetBucketAcl", "s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"], Resource = var.artifact_bucket_arn },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"], Resource = "${var.artifact_bucket_arn}/*" },
      { Effect = "Allow", Action = ["codebuild:StartBuild", "codebuild:BatchGetProjects"], Resource = var.codebuild_project_arn },
      # CodeBuild exposes the generated build ARN only after StartBuild. The
      # local CodePipeline integration evaluates BatchGetBuilds against a
      # wildcard resource; keep this exception limited to read-only status.
      { Effect = "Allow", Action = ["codebuild:BatchGetBuilds"], Resource = "*" },
      # DescribeServices does not support resource-level permissions; the
      # mutating UpdateService action remains limited to this service ARN.
      { Effect = "Allow", Action = ["ecs:DescribeServices"], Resource = "*" },
      { Effect = "Allow", Action = ["ecs:UpdateService"], Resource = var.ecs_service_arn },
      { Effect = "Allow", Action = ["ecs:DescribeTaskDefinition", "ecs:RegisterTaskDefinition", "ecs:ListTasks", "ecs:DescribeTasks"], Resource = "*" },
      { Effect = "Allow", Action = ["iam:PassRole"], Resource = [var.task_execution_role_arn, var.task_role_arn] }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_execution" {
  role = aws_iam_role.ecs_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      { Effect = "Allow", Action = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"], Resource = var.ecr_repository_arn },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${var.log_group_arn}:*" }
    ]
  })
}

# The current Spring Boot application does not call AWS APIs. The task role is
# intentionally permissionless; application permissions can be added here when
# a real AWS integration is introduced, without changing the execution role.
