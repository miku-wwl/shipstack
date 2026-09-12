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
    lambda       = var.aws_api_endpoint
    logs         = var.aws_api_endpoint
    codebuild    = var.aws_api_endpoint
    codepipeline = var.aws_api_endpoint
    cloudwatch   = var.aws_api_endpoint
  }
}

data "aws_caller_identity" "current" {}
