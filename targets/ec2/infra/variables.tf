variable "project_name" {
  type    = string
  default = "shipstack"
}

variable "target_name" {
  type    = string
  default = "ec2"
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

variable "instance_aws_endpoint" {
  type        = string
  description = "LocalStack endpoint reachable from the EC2 runtime."
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

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "ami_id" {
  type        = string
  description = "AMI ID used by LocalStack or a real AWS account. Replace with a valid regional AMI for real EC2."
  default     = "ami-024f768332f0"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 8080
}
