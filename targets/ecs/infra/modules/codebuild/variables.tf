variable "name_prefix" { type = string }
variable "project_name" { type = string }
variable "service_role_arn" { type = string }
variable "aws_region" { type = string }
variable "codebuild_image" { type = string }
variable "ecr_repository" { type = string }
variable "ecr_repository_uri" { type = string }
variable "container_name" { type = string }
variable "codebuild_log_group_name" { type = string }
variable "environment_variables" {
  type    = map(string)
  default = {}
}
