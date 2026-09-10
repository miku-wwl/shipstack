resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = 7
  tags              = { Name = var.log_group_name }
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = var.codebuild_log_group_name
  retention_in_days = 7
  tags              = { Name = var.codebuild_log_group_name }
}
