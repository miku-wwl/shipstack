variable "project_name" {
  type    = string
  default = "shipstack"
}

variable "target_name" {
  type    = string
  default = "eks"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_api_endpoint" {
  type        = string
  description = "运行 Terraform 的主机可访问的 LocalStack endpoint。"
  default     = "http://localhost:4566"
}

variable "codebuild_aws_endpoint" {
  type        = string
  description = "CodeBuild 容器可访问的 LocalStack endpoint。"
  default     = "http://localstack:4566"
}

variable "codebuild_kubernetes_api_endpoint" {
  type        = string
  description = "CodeBuild 容器可访问的 LocalStack EKS Kubernetes API endpoint。"
  default     = "https://localstack:4511"
}

variable "ecr_registry_port" {
  type        = number
  description = "LocalStack ECR registry 的可访问端口。"
  default     = 4566
}

variable "codebuild_image" {
  type    = string
  default = "public.ecr.aws/codebuild/amazonlinux-x86_64-standard:5.0"
}

variable "source_object_key" {
  type    = string
  default = "source.zip"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS 控制面的 Kubernetes 版本；LocalStack 会映射到其嵌入式 K3s。"
  default     = "1.35"
}

variable "k8s_namespace" {
  type    = string
  default = "shipstack-eks"
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
