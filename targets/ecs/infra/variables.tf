variable "project_name" {
  type    = string
  default = "shipstack"
}

variable "target_name" {
  type    = string
  default = "ecs"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_api_endpoint" {
  type        = string
  description = "Optional AWS API endpoint override. Set only for AWS-compatible local environments."
  nullable    = true
  default     = null
}

variable "codebuild_aws_endpoint" {
  type        = string
  description = "Optional endpoint injected into the CodeBuild runtime environment."
  nullable    = true
  default     = null
}

variable "ecr_registry_port" {
  type        = number
  description = "Optional registry port override for AWS-compatible local environments."
  default     = 4566
}

variable "codebuild_image" {
  type    = string
  default = "aws/codebuild/standard:7.0"
}

variable "source_object_key" {
  type    = string
  default = "source.zip"
}

variable "bootstrap_image_tag" {
  type    = string
  default = "bootstrap"
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
