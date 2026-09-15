variable "project_name" {
  type    = string
  default = "shipstack"
}

variable "target_name" {
  type    = string
  default = "beanstalk"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_api_endpoint" {
  type        = string
  description = "运行 Terraform 和主机侧 AWS CLI 可以访问的外部 LocalStack endpoint。"
  default     = "http://localhost:4566"
}

variable "codebuild_aws_endpoint" {
  type        = string
  description = "CodeBuild 容器可以访问的外部 LocalStack endpoint。"
  default     = "http://localstack:4566"
}

variable "codebuild_image" {
  type        = string
  description = "CodeBuild 使用的 Java 21 构建镜像。"
  default     = "public.ecr.aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "source_object_key" {
  type    = string
  default = "source.zip"
}

variable "solution_stack_name" {
  type        = string
  description = "真实 AWS 使用的 Elastic Beanstalk solution stack；LocalStack 控制面实验可留空。"
  nullable    = true
  default     = null
}

variable "environment_release_validation_mode" {
  type        = string
  description = "环境版本校验模式；LocalStack 控制面允许显式记录不支持，真实 AWS 必须使用 strict。"
  default     = "localstack-control-plane"

  validation {
    condition     = contains(["localstack-control-plane", "strict"], var.environment_release_validation_mode)
    error_message = "environment_release_validation_mode 只能是 localstack-control-plane 或 strict。"
  }
}
