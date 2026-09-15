variable "project_name" {
  type    = string
  default = "shipstack"
}

variable "target_name" {
  type    = string
  default = "batch"
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
  description = "CodeBuild 使用的 Java 21、Docker 和 AWS CLI 构建镜像。"
  default     = "public.ecr.aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "source_object_key" {
  type    = string
  default = "source.zip"
}

variable "ecr_registry_port" {
  type        = number
  description = "LocalStack ECR registry 的可访问端口。"
  default     = 4566
}

variable "bootstrap_image" {
  type        = string
  description = "Terraform 首次创建 Job Definition 时使用的占位镜像。正式发布由 CodeBuild 注册新版本。"
  default     = "busybox:1.36"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
