variable "project_name" {
  type    = string
  default = "shipstack"
}

variable "target_name" {
  type    = string
  default = "lambda"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_api_endpoint" {
  type        = string
  description = "LocalStack endpoint reachable from the host running Terraform."
  default     = "http://localhost:4566"
}

variable "codebuild_aws_endpoint" {
  type        = string
  description = "LocalStack endpoint reachable from the CodeBuild container."
  default     = "http://localstack:4566"
}

variable "codebuild_image" {
  type    = string
  default = "aws/codebuild/standard:7.0"
}

variable "source_object_key" {
  type    = string
  default = "source.zip"
}
