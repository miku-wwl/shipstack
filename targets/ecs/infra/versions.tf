terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region            = var.aws_region
  s3_use_path_style = true

  endpoints {
    s3           = var.aws_api_endpoint
    iam          = var.aws_api_endpoint
    sts          = var.aws_api_endpoint
    ec2          = var.aws_api_endpoint
    ecr          = var.aws_api_endpoint
    ecs          = var.aws_api_endpoint
    elbv2        = var.aws_api_endpoint
    logs         = var.aws_api_endpoint
    codebuild    = var.aws_api_endpoint
    codepipeline = var.aws_api_endpoint
    cloudwatch   = var.aws_api_endpoint
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix              = "${var.project_name}-${var.target_name}"
  ecr_repository           = "${local.name_prefix}-demo"
  ecs_cluster_name         = "${local.name_prefix}-cluster"
  ecs_service_name         = "${local.name_prefix}-service"
  codebuild_name           = "${local.name_prefix}-build"
  codepipeline_name        = "${local.name_prefix}-pipeline"
  log_group_name           = "/shipstack/${var.target_name}/ecs-platform-demo"
  codebuild_log_group_name = "/aws/codebuild/${local.name_prefix}"

  # LocalStack can expose the registry on a host port that differs from the
  # repository URL returned by its ECR API. On real AWS this replace is a no-op.
  ecr_repository_uri = replace(aws_ecr_repository.this.repository_url, ":4566/", ":${var.ecr_registry_port}/")
  bootstrap_image    = "${local.ecr_repository_uri}:${var.bootstrap_image_tag}"
}
