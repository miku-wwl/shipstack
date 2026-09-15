resource "aws_cloudwatch_log_group" "batch" {
  name              = local.batch_log_group_name
  retention_in_days = 7
  tags              = { Name = local.batch_log_group_name }
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = local.codebuild_log_group
  retention_in_days = 7
  tags              = { Name = local.codebuild_log_group }
}
